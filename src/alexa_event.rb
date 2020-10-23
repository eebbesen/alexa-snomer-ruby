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
  def initialize(event)
    @event = event
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

  def slots
    if @event['request'] &&
       @event['request']['intent'] &&
       @event['request']['intent']['slots']
      @event['request']['intent']['slots']
    else
      ''
    end
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

  def amazon_address_request
    logger.info 'starting address request'
    res = URI.open(device_api_endpoint,
                   'Accept' => 'application/json',
                   'Authorization' => "Bearer #{api_access_token}")
    logger.info "ending address request\\n#{res}"
    status = res.status[0]

    return JSON.parse(res.read) if status == '200'
  end

  private

  def logger
    @logger ||= Logger.new($stdout)
  end
end
