# frozen_string_literal: true

require_relative '../src/alexa_processor'
require 'json'
require 'spec_helper'

RSpec.describe AlexaProcessor do
  context '#getPage' do
    it 'returns text "ERROR" when error accessing site' do
      site = 'http://www2.minneapolismn.gov/snow/index.htm'
      ap = AlexaProcessor.new request_builder 'LocationRequest', address_perm: false, args: { cityName: 'Minneapolis' }
      VCR.use_cassette('minneapolis_503') do
        r = ap.send(:get_page, site)
        expect(r).to eq('ERROR')
      end
    end
  end

  context '#loc_processor' do
    it 'finds city info case insensitive' do
      ap = AlexaProcessor.new request_builder 'LocationRequest', address_perm: false, args: { cityName: 'Minneapolis' }
      info = ap.send(:loc_processor)
      expect(info['site']).to eq('http://www2.minneapolismn.gov/snow/index.htm')
    end

    it 'finds city info multi-word' do
      ap = AlexaProcessor.new request_builder 'LocationRequest', address_perm: false, args: { cityName: 'Saint Paul' }
      info = ap.send(:loc_processor)
      expect(info['site']).to eq('https://www.stpaul.gov/departments/public-works/street-maintenance/snow-emergency-update')
    end

    it 'handles non-match' do
      ap = AlexaProcessor.new request_builder 'LocationRequest', address_perm: false, args: { cityName: 'fargo' }
      info = ap.send(:loc_processor)
      expect(info).to be_nil
    end
  end

  context '#generate_text' do
    it 'yes condition exists' do
      ap = AlexaProcessor.new request_builder 'LocationRequest', address_perm: false, args: { cityName: 'Minneapolis' }
      VCR.use_cassette('minneapolis') do
        info = ap.send(:loc_processor)
        t = ap.generate_text info

        expect(t).to eq('minneapolis has declared a snow emergency')
      end
    end

    it 'no condition exists' do
      ap = AlexaProcessor.new request_builder 'LocationRequest', address_perm: false, args: { cityName: 'Saint Paul' }
      VCR.use_cassette('saint paul') do
        info = ap.send(:loc_processor)
        t = ap.generate_text info

        expect(t).to eq('There is not a snow emergency in saintpaul')
      end
    end

    it 'no yes or no condition' do
      ap = AlexaProcessor.new request_builder 'LocationRequest', address_perm: false, args: { cityName: 'Plymouth' }
      VCR.use_cassette('saint paul') do
        info = ap.send(:loc_processor)
        t = ap.generate_text info

        expect(t).to eq("plymouth doesn't post snow emergencies. If less than 2.5 inches falls, only major streets in the city system are plowed. If more than 2.5 inches of snow falls, a snow emergency is declared and all city streets are plowed curb-to-curb.")
      end
    end
  end

  context 'payload' do
    it 'should extract intent' do
      event = request_builder 'LaunchRequest'
      ap = AlexaProcessor.new event
      expect(ap.send(:find_intent_type)).to eql('LaunchRequest')
    end

    it 'confirms address permission yes' do
      event = request_builder 'LaunchRequest', address_perm: true
      ap = AlexaProcessor.new event
      expect(ap.send(:device_permission?)).to be_truthy
    end

    it 'confirms address permission no' do
      event = request_builder 'LaunchRequest'
      ap = AlexaProcessor.new event
      expect(ap.send(:device_permission?)).to be_falsey
    end

    it 'gets device id' do
      event = request_builder 'LaunchRequest', address_perm: false
      ap = AlexaProcessor.new event
      expect(ap.send(:device_id)).to eql('amzn1.ask.device.AEGXGYKTLQ')
    end

    it 'gets api access token' do
      event = request_builder 'LaunchRequest'
      ap = AlexaProcessor.new event
      expect(ap.send(:api_access_token)).to eql('eyJ0eXA')
    end

    it 'gets api endpoint' do
      event = request_builder 'LaunchRequest'
      ap = AlexaProcessor.new event
      expect(ap.send(:api_endpoint)).to eql('https://api.amazonalexa.com')
    end

    it 'gets request id' do
      event = request_builder 'LaunchRequest'
      ap = AlexaProcessor.new event
      expect(ap.send(:request_id)).to eql('amzn1.echo-api.request.888888')
    end
  end

  context 'address request' do
    it 'gets address on success' do
      expected_payload = JSON.parse '{"addressLine1":null,"addressLine2":null,"addressLine3":null,"districtOrCounty":null,"stateOrRegion":null,"city":null,"countryCode":"US","postalCode":"55104"}'
      device_id = 'amzn1.ask.device.AEGXGYKTLQ'
      api_access_token = 'eyJ0eXA'
      event = request_builder('LaunchRequest', address_perm: false)
      event['context']['System']['device']['deviceId'] = device_id
      event['context']['System']['apiAccessToken'] = api_access_token
      ap = AlexaProcessor.new event

      VCR.use_cassette('address_request') do
        address = ap.send :amazon_address_request

        expect(address).to eql(expected_payload)
      end
    end
  end

  context 'other intents' do
    it 'responds to help intent' do
      event = request_builder('HelpIntent', address_perm: false)
      ap = AlexaProcessor.new event

      expect(ap.process).to eql(["<speak>Request a Minnesota city and I'll get snow emergency info for you!</speak>"])
    end

    it 'says bye for stop event' do
      event = request_builder('StopIntent', address_perm: false)
      ap = AlexaProcessor.new event

      expect(ap.process).to eql(['<speak>Bye!</speak>'])
    end

    it 'returns silently for cancel event' do
      event = request_builder('CancelIntent', address_perm: false)
      ap = AlexaProcessor.new event

      expect(ap.process).to eql([''])
    end

    it 'claims ignorance for unexpected intents' do
      event = request_builder('MisunderstoodIntent', address_perm: false)
      ap = AlexaProcessor.new event

      expect(ap.process).to eql(["<speak>I'm sorry, I don't understand.</speak>"])
    end
  end

  context 'cannot complete' do
    it 'should respond when it cannot process' do
      event = request_builder 'huh'
      ap = AlexaProcessor.new event
      res = ap.process

      expect(res).to eql(["<speak>I'm sorry, I don't understand.</speak>"])
    end

    #   it 'should handle address fetch error' do
    #   end
  end

  it 'sanitizes text' do
    expect(AlexaProcessor.send(:sanitize, 'Hello & goodbye')).to eql('Hello and goodbye')
    expect(AlexaProcessor.send(:sanitize, 'you & me & baby')).to eql('you and me and baby')
    expect(AlexaProcessor.send(:sanitize, 'one man and')).to eql('one man and')
  end

  context 'slots' do
    %w[LaunchRequest IntentRequest].each do |r|
      it "handles nils for #{r}" do
        event = request_builder r, address_perm: false
        ap = AlexaProcessor.new event

        expect(ap.send(:slot_vals)[:food]).to be_nil
        expect(ap.send(:city)).to be_nil
        expect(ap.send(:slot_vals)[:count]).to be_nil
        expect(ap.send(:state)).to be_nil
      end
    end

    context 'saint paul' do
      it 'handles gyro' do
        event = request_builder 'IntentRequest', address_perm: false, args: { cityName: 'saint paul' }
        ap = AlexaProcessor.new event

        expect(ap.send(:slot_vals)[:city]).to eql('saint paul')
        expect(ap.send(:city)).to eql('saintpaul')
      end
    end
  end

  private

  def screen_request_builder(intent_type, address_perm: false, args: {})
    args[:screen] = true
    request_builder(intent_type, address_perm, args)
  end

  def request_builder(intent_type, address_perm: false, args: {})
    intent_name = args[:intent_name] || 'LocationRequest'
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
