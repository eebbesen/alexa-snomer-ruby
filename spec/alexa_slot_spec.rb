# frozen_string_literal: true

require_relative '../src/alexa_slot'
require 'json'
require_relative 'spec_helper'

RSpec.describe AlexaSlot do
  context '.parse_slots' do
    it 'generates slots from event' do
      slots = AlexaSlot.parse_slots JSON.parse(event_json_city)

      expect(slots.size).to eq(2)
      expect(slots.first.name).to eq('cityName')
      expect(slots.first.value).to eq('eagan')
      expect(slots.last.name).to eq('stateName')
      expect(slots.last.value).to be_nil
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

  context '#initialize' do
    it 'stores properly' do
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
          "value":"eagan",
          "confirmationStatus":"NONE",
          "source":"USER",
          "slotValue":{
            "type":"Simple",
            "value":"eagan"
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
