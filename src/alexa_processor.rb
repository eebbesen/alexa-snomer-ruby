# frozen_string_literal: true

require_relative './alexa_event'
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
                 :apl?,
                 :amazon_address_request

  def initialize(event)
    @event = event
    @alexa_event = AlexaEvent.new @event
  end

  def generate_text(info)
    page = if info['yesCondition'].size.positive?
             get_page info['site']
           else
             ''
           end

    return "The website for #{city} is not responding. #{info['policy']}" if page == 'ERROR'

    yes = info['yesCondition'].select { |c| page.downcase.include?(c) }.size.positive?
    no = info['noCondition'].select { |c| page.downcase.include?(c) }.size.positive?

    if yes
      "#{city} has declared a snow emergency"
    elsif no || page.size.positive?
      "There is not a snow emergency in #{city}"
    else
      "#{city} doesn't post snow emergencies."
    end
  end

  def intent_request_handler(loc_info, apl)
    text = generate_text loc_info

    r = respond text # speech
    logger.info "RESPONSE STRING\n#{r}"

    if apl
      logger.info 'IS APL'
      header_background_color = AlexaProcessor.color_picker(loc_info, r)
      data = {
        title: text,
        text: loc_info['policy'],
        # to_speak: text, # leaving this causes device to overlap speaking test twice
        header_background_color: header_background_color,
        header_theme: header_background_color == 'yellow' ? 'light' : 'dark'
      }
      directives = AplAssembler.build_directives data, :text
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
        return [respond("I don't have information for #{city}. Request another Minnesota city and I'll get snow emergency info for you!")]
      end

      intent_request_handler info
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

  def self.color_picker(info, text)
    if (info['yesCondition'].size + info['noCondition'].size).positive?
      text.include?('not a snow') ? 'green' : 'red'
    else
      'yellow'
    end
  end

  private

  def logger
    @logger ||= Logger.new($stdout)
  end

  def loc_processor
    return unless city

    file = File.open('database/city_map.json')
    cities = JSON.parse(file.read)
    cities[city]
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

  def city
    slot_vals[:city] ? slot_vals[:city].downcase.gsub(' ', '') : slot_vals[:city]
  end

  def state
    slot_vals[:state] ? slot_vals[:state].downcase.gsub(' ', '') : slot_vals[:state]
  end

  def slot_vals
    logger.info("slot_vals: #{slots}")
    return [] unless slots

    city = slots && slots['cityName'] && slots['cityName']['value']
    state = slots && slots['stateName'] && slots['stateName']['value']
    { city: city, state: state }
  end

  # https://maps.googleapis.com/maps/api/geocode/json?address=1600+Amphitheatre+Parkway,+Mountain+View,+CA&key=YOUR_API_KEY
  def geocode(address)
    logger.info 'starting geocode'
    url = "https://maps.googleapis.com/maps/api/geocode/json?key=#{ENV['GOOGLE_API_KEY']}&address="
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

  private_class_method def self.sanitize(text)
    text.gsub(/&/, 'and')
  end
end
