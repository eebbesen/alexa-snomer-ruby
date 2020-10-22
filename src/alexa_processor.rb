# frozen_string_literal: true

require_relative './alexa_event'
require_relative './apl_assembler'
require 'cgi'
require 'forwardable'
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
    page = if info['yesCondition'].size > 0
      get_page info['site']
    else
      ''
    end

    yes = info['yesCondition'].select { |c| page.downcase.include?(c) }.size > 0
    no = info['noCondition'].select { |c| page.downcase.include?(c) }.size > 0

    text = if yes
      "#{city} has declared a snow emergency"
    elsif no || page.size > 0
      "There is not a snow emergency in #{city}"
    else
      "#{city} doesn't post snow emergencies. #{info['policy']}"
    end
  end

  def process
    intent = find_intent_type
    case intent
    when 'LaunchRequest', 'IntentRequest'
      info = loc_processor

      text = generate_text(info)

      r = respond text # speech
      puts "RESPONSE STRING\n#{r}"

      if apl?
        puts 'IS APL'
        directives = AplAssembler.build_directives d
        [r, directives]
      else
        puts 'IS NOT APL'
        [r]
      end
    when 'SessionEndedRequest', 'CancelIntent'
      ['']
    when 'HelpIntent'
      [respond("Request a Minnesota city and I'll get snow emergency info for you!")]
    when 'StopIntent'
      [respond('Bye!')]
    else
      puts "Didn't get an expected intent: #{intent}"
      [respond("I'm sorry, I don't understand.")]
    end
  rescue AddressPermissionError, FoodNameError => e
    [respond(e.message)]
  rescue StandardError => e
    puts "error:\n#{e}\nresponding with:\n#{e.message}"
    [respond("I'm having issues, please try again later")]
  end

  private

  def loc_processor
    return unless city
    file = File.open('database/city_map.json')
    cities = JSON.parse(file.read)
    return cities[city]
  end

  def parse_loc_data(locs)
    s = ''
    locs.map do |l|
      puts "parse loc data\n#{l[:name]}--#{l[:street]}"
      n = ' next' if s.length.positive?
      s += "Your#{n} closest yeero is #{l[:name]}"
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
    return unless slots

    city = slots && slots['cityName'] && slots['cityName']['value']
    state = slots && slots['stateName'] && slots['stateName']['value']
    { city: city, state: state }
  end

  # https://maps.googleapis.com/maps/api/geocode/json?address=1600+Amphitheatre+Parkway,+Mountain+View,+CA&key=YOUR_API_KEY
  def geocode(address)
    puts 'starting geocode'
    url = "https://maps.googleapis.com/maps/api/geocode/json?key=#{ENV['GOOGLE_API_KEY']}&address="
    a = CGI.escape([address['addressLine1'], address['city'], address['stateOrRegion'], address['postalCode']].compact.join(','))
    raise "You don't have any address information with your device" if a == ''

    res = URI.open(url + a)
    status = res.status[0]
    read = JSON.parse res.read
    read['results'][0]['geometry']['location'] if status == '200'
  end

  # gets target page
  def get_page(url)
    res = URI.open(url).read
  end

  # https://www.ineedagyro.com/recs?lat=1&lng=8
  def gyro_service(lat, lng)
    url = "https://www.ineedagyro.com/recs?lat=#{lat}1&lng=#{lng}"

    res = URI.open(url)
    read = JSON.parse res.read
    read['locs']
  end

  private_class_method def self.sanitize(text)
    text.gsub(/&/, 'and')
  end
end

##
class FoodNameError < StandardError
  MSG = "I'm sorry, I can only find yeeros"
  def initialize
    super(MSG)
  end
end