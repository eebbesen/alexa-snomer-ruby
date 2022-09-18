# frozen_string_literal: true

require_relative './alexa_event'
require_relative './alexa_device'
require_relative './apl_assembler'
require 'cgi'
require 'forwardable'
require 'logger'
require 'open-uri'

##
class AlexaProcessor
  extend Forwardable

  def_delegators :@alexa_event,
                 :system,
                 :device_api_endpoint,
                 :api_access_token,
                 :api_endpoint,
                 :device_id,
                 :request_id,
                 :slots,
                 :address,
                 :find_intent_type,
                 :device_permission?,
                 :amazon_address_request,
                 :city,
                 :state

  def_delegators :@alexa_device,
                 :round?,
                 :apl?,
                 :pick_font_size

  def initialize(event)
    @alexa_event = AlexaEvent.new event
    @alexa_device = AlexaDevice.new event
  end

  def generate_text(info)
    page = if info['yesCondition'].size.positive?
             get_page info['site']
           else
             ''
           end

    return "The website for #{city.display} is not responding. #{info['policy']}" if page == 'ERROR'

    yes = info['yesCondition'].select { |c| page.downcase.include?(c) }.size.positive?
    no = info['noCondition'].select { |c| page.downcase.include?(c) }.size.positive?

    if yes
      @snow_emergency = 'yes'
      "#{city.display} has declared a snow emergency"
    elsif no || page.size.positive?
      @snow_emergency = 'no'
      "There is not a snow emergency in #{city.display}"
    else
      @snow_emergency = 'maybe'
      "#{city.display} doesn't post snow emergencies."
    end
  end

  def intent_request_handler(loc_info, apl)
    text = generate_text loc_info

    r = respond text # speech
    logger.info "RESPONSE STRING\n#{r}"

    if apl
      logger.info 'IS APL'
      directives = nil
      if round?
        data = {
          text: @snow_emergency == 'maybe' ? '?' : @snow_emergency.upcase,
          to_speak: respond(text)
        }

        directives = AplAssembler.build_directives data, :round
      else
        data = {
          title: text,
          text: loc_info['policy'],
          to_speak: respond(text),
          header_background_color: AlexaProcessor.color_picker(@snow_emergency),
          header_theme: @snow_emergency == 'maybe' ? 'light' : 'dark',
          font_size: pick_font_size
        }
        directives = AplAssembler.build_directives data, :text
      end
      [r, directives]
    else
      logger.info 'IS NOT APL'
      [r]
    end
  end

  def process
    intent = find_intent_type
    case intent
    when 'IntentRequest', 'LocationRequest'
      info = loc_processor
      unless info&.size&.positive?
        return [respond("I don't have information for #{city.display}. Request another Minnesota city and I'll get snow emergency info for you!")]
      end

      intent_request_handler info, apl?
    when 'SessionEndedRequest', 'CancelIntent'
      ['']
    when 'LaunchRequest', 'HelpIntent'
      [respond("Request a Minnesota city and I'll get snow emergency info for you!")]
    when 'StopIntent'
      [respond('Bye!')]
    else
      logger.info "Didn't get an expected intent: #{intent}"
      [respond("I'm sorry, I don't understand.")]
    end
  rescue AddressPermissionError
    [respond(e.message)]
  rescue StandardError => e
    logger.info "error:\n#{e}\nresponding with:\n#{e.message}"
    [respond("I'm having issues, please try again later")]
  end

  def self.color_picker(snow_emergency)
    case snow_emergency
    when 'yes'
      'red'
    when 'maybe'
      'yellow'
    else
      'green'
    end
  end

  private

  def logger
    @logger ||= Logger.new($stdout)
  end

  def loc_processor
    return unless city.key

    file = File.open('database/city_map.json')
    cities = JSON.parse(file.read)
    return cities[city.key] if cities[city.key]

    return unless cities[@alexa_event.alternate_city_key]

    city.display = @alexa_event.alternate_city_display
    cities[@alexa_event.alternate_city_key]
  end

  def parse_loc_data(locs)
    s = ''
    locs.map do |l|
      logger.info "parse loc data\n#{l[:name]}--#{l[:street]}"
      n = ' next' if s.length.positive?
      s += "Your#{n} closest location is #{l[:name]}"
      s += " at #{l[:street]}" if l[:street]
      s += '.<break time=\\"500ms\\"/>'
    end
    s
  end

  def respond(text)
    speak text
  end

  def speak(text)
    AlexaProcessor.send(:sanitize, "<speak>#{text}</speak>")
  end

  def extract_loc_data(locs, count = 4)
    c = (count&.positive? ? count - 1 : 3)
    d = []
    (0..c).collect do |i|
      d[i] = {
        name: locs[i]['name'],
        street: locs[i]['location']['address1'],
        city: locs[i]['location']['city'],
        distance: locs[i]['distance']
      }
    end
    d
  end

  # https://maps.googleapis.com/maps/api/geocode/json?address=1600+Amphitheatre+Parkway,+Mountain+View,+CA&key=YOUR_API_KEY
  def geocode(address)
    logger.info 'starting geocode'
    url = "https://maps.googleapis.com/maps/api/geocode/json?key=#{ENV.fetch('GOOGLE_API_KEY', nil)}&address="
    a = CGI.escape([address['addressLine1'], address['city'], address['stateOrRegion'], address['postalCode']].compact.join(','))
    raise "You don't have any address information with your device" if a == ''

    res = URI.parse(url + a).open
    status = res.status[0]
    read = JSON.parse res.read
    read['results'][0]['geometry']['location'] if status == '200'
  end

  # gets target page
  def get_page(url)
    URI.parse(url).open.read
  rescue StandardError => e
    logger.error("Error accessing #{url}:\n#{e.message}")
    'ERROR'
  end

  # # 30: hub small landscape
  # # 40: hub meedium
  # # 50: hub landscape
  # # 40: tv
  # def pick_font_size(h, w)

  # end

  private_class_method def self.sanitize(text)
    text.gsub(/&/, 'and')
  end
end
