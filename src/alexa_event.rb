# frozen_string_literal: true

require 'logger'
require 'open-uri'

##
class AddressPermissionError < StandardError
  MSG = 'Please grant me permission to access your device address. Without this permission I cannot find locations near you!'
  def initialize
    super(MSG)
  end
end

##
class AlexaEvent
  US_STATES = [
    'alabama',
    'alaska',
    'arizona',
    'arkansas',
    'california',
    'colorado',
    'connecticut',
    'delaware',
    'florida',
    'georgia',
    'hawaii',
    'idaho',
    'illinois',
    'indiana',
    'iowa',
    'kansas',
    'kentucky',
    'louisiana',
    'maine',
    'maryland',
    'massachusetts',
    'michigan',
    'minnesota',
    'mississippi',
    'missouri',
    'montana',
    'nebraska',
    'nevada',
    'new hampshire',
    'new jersey',
    'new mexico',
    'new york',
    'north carolina',
    'north dakota',
    'ohio',
    'oklahoma',
    'oregon',
    'pennsylvania',
    'rhode island',
    'south carolina',
    'south dakota',
    'tennessee',
    'texas',
    'utah',
    'vermont',
    'virginia',
    'washington',
    'west virginia',
    'wisconsin',
    'wyoming'
  ].freeze

  def initialize(event)
    @event = event
    process_slot_vals
  end

  def system
    @event['context']['System']
  end

  def device_api_endpoint
    "#{api_endpoint}/v1/devices/#{device_id}/settings/address"
  end

  def api_access_token
    system['apiAccessToken']
  end

  def api_endpoint
    system['apiEndpoint'].gsub('http://', 'https://')
  end

  def device_id
    system['device']['deviceId']
  end

  def request_id
    @event['request']['requestId']
  end

  def address
    return raise AddressPermissionError unless device_permission?

    @address ||= amazon_address_request
  end

  # expects JSON
  def find_intent_type
    @event['request']['type']
  end

  def device_permission?
    u = system['user']
    u['permissions'] && !u['permissions'].empty?
  end

  def apl?
    system['device']['supportedInterfaces'] &&
      system['device']['supportedInterfaces']['Alexa.Presentation.APL'] &&
      system['device']['supportedInterfaces']['Display']
  end

  # get physical address of device
  # this value is user-entered and could be zip code or full address
  def amazon_address_request
    logger.info 'starting address request'
    res = URI.open(device_api_endpoint,
                   'Accept' => 'application/json',
                   'Authorization' => "Bearer #{api_access_token}")
    logger.info "ending address request\\n#{res}"
    status = res.status[0]

    return JSON.parse(res.read) if status == '200'
  end

  def city
    return @city if @city

    @original_city ||= slot_vals[:cityName]
    @city ||= slot_vals[:cityName] ? slot_vals[:cityName].downcase.gsub(' ', '') : slot_vals[:cityName]
  end

  def state
    return @state if @state

    @original_state ||= slot_vals[:stateName]
    @state ||= slot_vals[:stateName] ? slot_vals[:stateName].downcase.gsub(' ', '') : slot_vals[:stateName]
  end

  def slot_vals
    @slot_vals
  end

  def original_city
    return '' unless @original_city

    @original_city.split.map(&:capitalize).join(' ')
  end

  def original_state
    return '' unless @original_state

    @original_state.split.map(&:capitalize).join(' ')
  end

  # sometiems Alexa splits a city into city and state
  # try combining them
  def combine_city_state
    @city = "#{city} #{state}"
    @original_city = "#{@original_city} #{@original_state}"
  end

  private

  def process_slot_vals
    @slot_vals = {}.tap do |sv|
      slots.keys.collect do |k|
        sv[k.to_sym] = slots[k]['value']
      end
    end
  end

  def logger
    @logger ||= Logger.new($stdout)
  end

  def slots
    return @slots if @slots

    @slots = if @event['request'] &&
       @event['request']['intent'] &&
       @event['request']['intent']['slots']
      @event['request']['intent']['slots']
    else
      {}
    end
  end

  attr_writer :state, :city
end
