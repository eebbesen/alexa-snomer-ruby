# frozen_string_literal: true

require 'logger'
require 'open-uri'

require_relative './alexa_slot'

##
class AddressPermissionError < StandardError
  MSG = 'Please grant me permission to access your device address. Without this permission I cannot find locations near you!'
  def initialize
    super(MSG)
  end
end

##
class AlexaEvent
  attr_reader :slots

  def initialize(event)
    @event = event
    @slots ||= AlexaSlot.parse_slots @event
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
    slots[:cityName]
  end

  def state
    slots[:stateName]
  end

  # sometiems Alexa splits a city into city and state
  # try combining them
  def combine_city_state
    "#{city.display} #{state.display}"
  end

  private

  def logger
    @logger ||= Logger.new($stdout)
  end

  attr_writer :state, :city
end
