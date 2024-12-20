# frozen_string_literal: true

require_relative '../src/minneapolis'
require 'json'
require 'spec_helper'

RSpec.describe Minneapolis do
  context '#parse_notices' do
    it 'finds record for current datetime' do
      expect(DateTime).to receive(:now).and_return(DateTime.parse('2024-12-20 13:50:00'))

      page = JSON.parse(File.read('./spec/minneapolis_emergency-en.json'))

      expect(Minneapolis.parse_notices(page)).to include('rules are in effect')
    end

    it 'ignores records without expiry' do
      expect(DateTime).to receive(:now).and_return(DateTime.parse('2024-11-21 13:50:00'))

      page = JSON.parse(File.read('./spec/minneapolis_emergency-en.json'))

      expect(Minneapolis.parse_notices(page)).to eq('')
    end

    it 'handles empty file' do
      page = JSON.parse('{ "notices": [] }')

      expect(Minneapolis.parse_notices(page)).to eq('')
    end
  end
end
