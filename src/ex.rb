# frozen_string_literal: true

# test file to exercise lambda_function.lambda_handler call like (I think) AWS Lambda does
require_relative 'lambda_function'
require 'byebug'
require 'json'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
end

def yes_screen_zip_only
  process read('launch_request_viewport_event'), 'ex_address_request_screen'
end

def no_screen_zip_only
  process read('launch_request_no-screen_event')
end

def read(file)
  File.read("./samples/#{file}.json")
end

def process(payload, cassette = 'ex_address_request')
  VCR.use_cassette(cassette) do
    VCR.use_cassette('ex_google_geocode_request_zip_only') do
      event = JSON.parse payload
      context = event['context']
      lambda_handler(event: event, context: context)
    end
  end
end

if ARGV&.count&.positive? && ARGV[0] == 'ns'
  no_screen_zip_only
else
  yes_screen_zip_only
end
