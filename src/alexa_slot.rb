# frozen_string_literal: true

##
class AlexaSlot
  attr_reader :name, :value

  def initialize(slot)
    @name = slot['name']
    @value = slot['value']
  end

  # gets slots from an event
  # slots are parsed as Arrays with name as the first value and hash as the second
  # since the hash also contains the name, we just get the hash
  def self.parse_slots(event)
    return {} unless event &&
       event['request'] &&
       event['request']['intent'] &&
       event['request']['intent']['slots']

    event['request']['intent']['slots'].collect do |slot|
      AlexaSlot.new slot.last
    end
  end
end
