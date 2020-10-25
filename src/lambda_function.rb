# frozen_string_literal: true

require 'json'
require 'logger'
require_relative './alexa_event'
require_relative './alexa_processor'

##
def lambda_handler(event:, context:)

  logger = Logger.new($stdout)
  logger.info("event: #{event}")
  logger.info("context: #{context.inspect}")

  ap = AlexaProcessor.new event
  payload = ap.process
  logger.info("payload: #{payload}")

  end_session = %w(StopIntent SessionEndedRequest CancelIntent).include? event['request']['type'] ? true : false
  pp = if payload.length == 1
         <<~PP
           {
             "version": "1.0",
             "response": {
               "outputSpeech": {
                 "type": "SSML",
                 "ssml": "#{payload[0]}"
               },
               "shouldEndSession": #{end_session}
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
               "shouldEndSession": #{end_session},
               #{payload[1]}
             },
             "sessionAttributes": {}
           }
         PP
       end
  pp = JSON.parse pp
  logger.info "RETURN: #{pp}"
  pp
end
