# frozen_string_literal: true

##
class AlexaSlot
  attr_accessor :display
  attr_reader :name, :value, :key

  def initialize(slot)
    @name = slot['name']
    @value = slot['value']&.downcase
    @key = value&.downcase&.gsub(' ', '')
  end

  # default designed for city names
  def display
    @display ||= value&.split&.map(&:capitalize)&.join(' ')
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
end
