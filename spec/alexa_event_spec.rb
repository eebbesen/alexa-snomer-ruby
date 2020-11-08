# frozen_string_literal: true

require_relative '../src/alexa_event'
require 'json'
require_relative 'spec_helper'

ENV['GOOGLE_API_KEY'] = 'SECRET'

RSpec.describe AlexaEvent do
  context '#alternate_city_display' do
    it 'handles incorrectly split city and state' do
      ae = AlexaEvent.new request_builder 'LocationRequest', address_perm: false, args: { cityName: 'brooklyn', stateName: 'park' }
      expect(ae.alternate_city_display).to eq('Brooklyn Park')
    end
  end

  context '#alternate_city_key' do
    it 'handles incorrectly split city and state' do
      ae = AlexaEvent.new request_builder 'LocationRequest', address_perm: false, args: { cityName: 'brooklyn', stateName: 'park' }
      expect(ae.alternate_city_key).to eq('brooklynpark')
    end
  end

  context 'slots' do
    it 'handles nils for LaunchRequest' do
      event = request_builder 'LaunchRequest', address_perm: false
      ae = AlexaEvent.new event

      expect(ae.slots[:cityName]).to be_nil
      expect(ae.slots[:count]).to be_nil
      expect(ae.city).to be_nil
      expect(ae.state).to be_nil
    end

    it 'handles nils for IntentRequest' do
      event = request_builder 'IntentRequest', address_perm: false
      ae = AlexaEvent.new event

      expect(ae.slots[:cityName].value).to be_nil
      expect(ae.slots[:count]).to be_nil
      expect(ae.city.value).to be_nil
      expect(ae.state.value).to be_nil
    end

    it 'populates city' do
      event = request_builder 'IntentRequest', address_perm: false, args: { cityName: 'saint paul' }
      ae = AlexaEvent.new event

      expect(ae.city.value).to eql('saint paul')
    end

    it 'populates state' do
      event = request_builder 'IntentRequest', address_perm: false, args: { cityName: 'saint paul', stateName: 'minnesota' }
      ae = AlexaEvent.new event

      expect(ae.state.value).to eql('minnesota')
    end
  end

  context 'payload' do
    it 'should extract intent' do
      event = request_builder 'LaunchRequest'
      ae = AlexaEvent.new event
      expect(ae.send(:find_intent_type)).to eql('LaunchRequest')
    end

    it 'confirms address permission yes' do
      event = request_builder 'LaunchRequest', address_perm: true
      ae = AlexaEvent.new event
      expect(ae.send(:device_permission?)).to be_truthy
    end

    it 'confirms address permission no' do
      event = request_builder 'LaunchRequest'
      ae = AlexaEvent.new event
      expect(ae.send(:device_permission?)).to be_falsey
    end

    it 'gets device id' do
      event = request_builder 'LaunchRequest', address_perm: true
      ae = AlexaEvent.new event
      expect(ae.send(:device_id)).to eql('amzn1.ask.device.AEGXGYKTLQ')
    end

    it 'gets api access token' do
      event = request_builder 'LaunchRequest'
      ae = AlexaEvent.new event
      expect(ae.send(:api_access_token)).to eql('eyJ0eXA')
    end

    it 'gets api endpoint' do
      event = request_builder 'LaunchRequest'
      ae = AlexaEvent.new event
      expect(ae.send(:api_endpoint)).to eql('https://api.amazonalexa.com')
    end

    it 'gets request id' do
      event = request_builder 'LaunchRequest'
      ae = AlexaEvent.new event
      expect(ae.send(:request_id)).to eql('amzn1.echo-api.request.888888')
    end
  end

  context 'address request' do
    it 'gets address on success' do
      expected_payload = JSON.parse '{"addressLine1":null,"addressLine2":null,"addressLine3":null,"districtOrCounty":null,"stateOrRegion":null,"city":null,"countryCode":"US","postalCode":"55104"}'
      device_id = 'amzn1.ask.device.AEGXGYKTLQ'
      api_access_token = 'eyJ0eXA'
      event = request_builder('LaunchRequest', address_perm: true)
      event['context']['System']['device']['deviceId'] = device_id
      event['context']['System']['apiAccessToken'] = api_access_token
      ae = AlexaEvent.new event

      VCR.use_cassette('address_request') do
        address = ae.send :amazon_address_request
        expect(address).to eql(expected_payload)
      end
    end
  end

  private

  def screen_request_builder(intent_type, address_perm: false, args: {})
    args[:screen] = true
    request_builder(intent_type, address_perm, args)
  end

  def request_builder(intent_type, address_perm: false, args: {})
    intent_name = args[:intent_name] || 'LaunchRequest'
    city = args[:cityName] || nil
    state = args[:stateName] || nil
    screen = args[:screen] || false

    apl_string = <<~SSCC
      ,"supportedInterfaces": {
          "Display": {
              "templateVersion": "1.0",
              "markupVersion": "1.0"
          },
          "Alexa.Presentation.APL": {
              "runtime": {
                  "maxVersion": "1.0"
              }
          }
      }
    SSCC
    address_permission_string = '"consentToken": "abcdefgh123456790"'
    city_string = city ? "\"value\": \"#{city}\"," : ''
    state_string = state ? "\"value\": \"#{state}\"," : ''
    intent_string = <<~INTENT
      ,"intent": {
        "name": "#{intent_name}",
        "confirmationStatus": "NONE",
        "slots": {
          "cityName": {
            #{city_string}
            "name": "cityName",
            "confirmationStatus": "NONE",
            "source": "USER"
          },
          "stateName": {
            #{state_string}
            "name": "stateName",
            "confirmationStatus": "NONE",
            "source": "USER"
          }
        }
      }
    INTENT

    JSON.parse <<~JSONT
      {
        "version": "1.0",
        "context": {
          "System": {
            "user": {
              "permissions": {
                #{address_perm ? address_permission_string : ''}
              }
            },
            "device": {
              "deviceId": "amzn1.ask.device.AEGXGYKTLQ"
              #{screen ? apl_string : ''}
            },
            "apiEndpoint": "https://api.amazonalexa.com",
            "apiAccessToken": "eyJ0eXA"
          },
          "Viewport": {}
        },
        "request": {
          "type": "#{intent_type}",
          "requestId": "amzn1.echo-api.request.888888",
          "timestamp": "2019-01-19T17:48:25Z",
          "locale": "en-US",
          "shouldLinkResultBeReturned": false
            #{intent_type == 'LaunchRequest' ? '' : intent_string}
        }
      }
    JSONT
  end
end
