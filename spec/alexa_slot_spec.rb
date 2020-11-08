# frozen_string_literal: true

require_relative '../src/alexa_slot'
require 'json'
require_relative 'spec_helper'

RSpec.describe AlexaSlot do
  context '#us_state?' do
    it 'identifies as us state' do
      s = AlexaSlot.new({ 'name' => 'stateName', 'value' => 'new jersey' })
      expect(s.us_state?).to be_truthy
    end

    it 'identifies not as us state' do
      s = AlexaSlot.new({ 'name' => 'stateName', 'value' => 'park' })
      expect(s.us_state?).to be_falsey
    end
  end

  context '.parse_slots' do
    it 'generates slots from event' do
      slots = AlexaSlot.parse_slots JSON.parse(event_json_city)

      expect(slots.size).to eq(2)
      expect(slots[:cityName].name).to eq('cityName')
      expect(slots[:cityName].value).to eq('saint paul')
      expect(slots[:cityName].key).to eq('saintpaul')
      expect(slots[:cityName].display).to eq('Saint Paul')
      expect(slots[:stateName].name).to eq('stateName')
      expect(slots[:stateName].value).to be_nil
      expect(slots[:stateName].key).to be_nil
      expect(slots[:stateName].display).to be_nil
    end

    it 'handles events with no slots' do
      slots = AlexaSlot.parse_slots JSON.parse('{"request": {"intent": {"slots": {}}}}')
      expect(slots.size).to eq(0)

      slots = AlexaSlot.parse_slots JSON.parse('{"request": {"intent": {}}}')
      expect(slots.size).to eq(0)

      slots = AlexaSlot.parse_slots JSON.parse('{"request": {}}')
      expect(slots.size).to eq(0)

      slots = AlexaSlot.parse_slots JSON.parse('{}')
      expect(slots.size).to eq(0)
    end

    it 'handles nil event' do
      slots = AlexaSlot.parse_slots nil
      expect(slots.size).to eq(0)
    end
  end

  def event_json_city
    <<~JSON
      {
        "request":{
          "type":"IntentRequest",
          "requestId":"amzn1.echo-api.request.ee5d1985-a317-431f-a0b9-46a1eb923212",
          "locale":"en-US",
          "timestamp":"2020-11-07T14:23:24Z",
          "intent":{
            "name":"LocationRequest",
            "confirmationStatus":"NONE",
            "slots":{
              "cityName":{
                "name":"cityName",
                "value":"SAINT PAUL",
                "confirmationStatus":"NONE",
                "source":"USER",
                "slotValue":{
                  "type":"Simple",
                  "value":"saint paul"
                }
              },
              "stateName":{
                "name":"stateName",
                "confirmationStatus":"NONE"
              }
            }
          }
        }
      }
    JSON
  end
end
