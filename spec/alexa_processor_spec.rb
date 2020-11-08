# frozen_string_literal: true

require_relative '../src/alexa_processor'
require 'json'
require 'spec_helper'

RSpec.describe AlexaProcessor do
  context '#get_page' do
    it 'returns text "ERROR" when error accessing site' do
      site = 'http://www2.minneapolismn.gov/snow/index.htm'
      ap = AlexaProcessor.new request_builder 'LocationRequest', address_perm: false, args: { cityName: 'Minneapolis' }
      VCR.use_cassette('minneapolis_503') do
        r = ap.send(:get_page, site)
        expect(r).to eq('ERROR')
      end
    end
  end

  context '#intent_request_handler' do
    before(:each) do
      @ap = AlexaProcessor.new request_builder 'LocationRequest', address_perm: false, args: { cityName: 'Saint Paul' }
      @ap.send(:loc_processor) # this happens earlier than the call to intent_request_handler
      @loc_info = {
        'yesCondition' => ['saint paul declares snow emergency'],
        'noCondition' => ['A Snow Emergency is typically declared after snowfalls of 3 inches or more, or after an accumulation of 3 inches or more from several snowfalls. When a snow emergency is declared, which officially goes into effect at 9 p.m., residents are asked to follow specific parking guidelines to allow for efficient snow removal operations. Vehicles in violation of parking restrictions are ticketed and towed.'],
        'policy' => 'A Snow Emergency is typically declared after snowfalls of 3 inches or more, or after an accumulation of 3 inches or more from several snowfalls. When a snow emergency is declared, which officially goes into effect at 9 p.m., residents are asked to follow specific parking guidelines to allow for efficient snow removal operations. Vehicles in violation of parking restrictions are ticketed and towed.',
        'site' => 'https://www.stpaul.gov/departments/public-works/street-maintenance/snow-emergency-update'
      }
    end

    it 'generates APL response' do
      VCR.use_cassette('saint paul') do
        r = @ap.intent_request_handler @loc_info, true
        expect(r[0]).to eq('<speak>There is not a snow emergency in Saint Paul</speak>')
        expect(r[1]).to include('"headerBackgroundColor": "green"')
        expect(r[1]).to include(@loc_info['policy'])
      end
    end

    it 'generates non-APL response' do
      VCR.use_cassette('saint paul') do
        r = @ap.intent_request_handler @loc_info, false
        expect(r[0]).to eq('<speak>There is not a snow emergency in Saint Paul</speak>')
        expect(r.size).to eq(1)
      end
    end
  end

  context '.color_picker' do
    it 'returns red if snow emergency declared' do
      expect(AlexaProcessor.color_picker('yes')).to eq('red')
    end

    it 'returns red if snow emergency declared' do
      expect(AlexaProcessor.color_picker('no')).to eq('green')
    end

    it 'returns red if snow emergency declared' do
      expect(AlexaProcessor.color_picker('maybe')).to eq('yellow')
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

    it 'handles wrong slots' do
      ap = AlexaProcessor.new request_builder 'LocationRequest', address_perm: false, args: { cityName: 'brooklyn', stateName: 'park' }
      info = ap.send(:loc_processor)
      expect(info['site']).to eq('http://www.brooklynpark.org/city-government/public-works/snow-removal-information/')
    end

    it 'handles non-match' do
      ap = AlexaProcessor.new request_builder 'LocationRequest', address_perm: false, args: { cityName: 'fargo' }
      info = ap.send(:loc_processor)
      expect(info).to be_nil
    end
  end

  context '#generate_text' do
    it 'yes condition exists' do
      ap = AlexaProcessor.new request_builder 'LocationRequest', address_perm: false, args: { cityName: 'Frostbite Falls' }
      VCR.use_cassette('frostbite_falls') do
        info = ap.send(:loc_processor)
        t = ap.generate_text info

        expect(t).to eq('Frostbite Falls has declared a snow emergency')
        expect(ap.instance_variable_get(:@snow_emergency)).to eq('yes')
      end
    end

    it 'no condition exists' do
      ap = AlexaProcessor.new request_builder 'LocationRequest', address_perm: false, args: { cityName: 'Saint Paul' }
      VCR.use_cassette('saint paul') do
        info = ap.send(:loc_processor)
        t = ap.generate_text info

        expect(t).to eq('There is not a snow emergency in Saint Paul')
        expect(ap.instance_variable_get(:@snow_emergency)).to eq('no')
      end
    end

    it 'no yes or no condition' do
      ap = AlexaProcessor.new request_builder 'LocationRequest', address_perm: false, args: { cityName: 'Plymouth' }
      VCR.use_cassette('saint paul') do
        info = ap.send(:loc_processor)
        t = ap.generate_text info

        expect(t).to eq("Plymouth doesn't post snow emergencies.")
        expect(ap.instance_variable_get(:@snow_emergency)).to eq('maybe')
      end
    end

    it 'municipality website error' do
      ap = AlexaProcessor.new request_builder 'LocationRequest', address_perm: false, args: { cityName: 'Minneapolis' }
      VCR.use_cassette('minneapolis_503') do
        info = ap.send(:loc_processor)
        t = ap.generate_text info

        expect(t).to eq('The website for Minneapolis is not responding. Snow Emergencies are called after significant snowfall and before 6 p.m. on any given day. During a Snow Emergency, special parking rules go into effect that allow City crews to plow streets and emergency vehicles to travel safely.')
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

  context '#process' do
    it 'unknonwn city' do
      event = request_builder 'LocationRequest', address_perm: false, args: { cityName: 'Saint Olaf' }
      ap = AlexaProcessor.new event

      expect(ap.process).to eql(["<speak>I don't have information for Saint Olaf. Request another Minnesota city and I'll get snow emergency info for you!</speak>"])
    end

    it 'knonwn city' do
      event = request_builder 'LocationRequest', address_perm: false, args: { cityName: 'Saint Paul' }
      ap = AlexaProcessor.new event

      VCR.use_cassette('saint paul') do
        expect(ap.process).to eql(['<speak>There is not a snow emergency in Saint Paul</speak>'])
      end
    end

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
    shape = args[:shape] || 'RECTANGLE'

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
          "Viewport": {
            "pixelWidth": 1363,
            "pixelHeight": 799,
            "shape": "#{shape}"
          }
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
