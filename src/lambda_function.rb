# frozen_string_literal: true

require 'json'
require_relative './alexa_event'
require_relative './alexa_processor'

##
def lambda_handler(event:, context:)
  puts("event: #{event}")
  puts("context: #{context}")

  ap = AlexaProcessor.new event
  payload = ap.process
  pp = if payload.length == 1
         <<~PP
           {
             "version": "1.0",
             "response": {
               "outputSpeech": {
                 "type": "SSML",
                 "ssml": "#{payload[0]}"
               },
               "shouldEndSession": true
             },
             "sessionAttributes": {}
           }
         PP
       else
         <<~PP
           {
             "version": "1.0",
             "response": {
               "outputSpeech": {
                 "type": "SSML",
                 "ssml": "#{payload[0]}"
               },
               "shouldEndSession": true,
               #{payload[1]}
             },
             "sessionAttributes": {}
           }
         PP
       end
  pp = JSON.parse pp
  puts "RETURN: #{pp}"
  pp
end
