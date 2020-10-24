# frozen_string_literal: true

require_relative '../src/template_data_builder'
require 'json'
require 'spec_helper'

RSpec.describe TemplateDataBuilder do
  before(:each) do
    ENV['APP_NAME'] = 'Snow Emergency'
    ENV['LOGO_URL'] = 'https://images-na.ssl-images-amazon.com/images/I/81QXYqxgqhL._SL210_QL95_BG0,0,0,0_FMpng_.png'
  end

  context 'final template' do
    it 'builds template' do
      d = [{
        id: 'gyrohero',
        ordinal_no: 1,
        primary_text: 'Gyro Hero',
        secondary_text: '100 Main Street',
        tertiary_text: '2 miles',
        token: 'gyrohero'
       },
       {
         id: 'greekgrille',
         ordinal_no: 2,
         primary_text: 'Greek Grille',
         secondary_text: '88 Elm Street',
         tertiary_text: '2.5 miles',
         token: 'greekgrille'
       }]

      ex = JSON.parse <<~TTT
        {
          "listTemplate1Metadata": {
            "type": "object",
            "objectId": "lt1Metadata",
            "title": "Snow Emergency",
            "logoUrl": "https://images-na.ssl-images-amazon.com/images/I/81QXYqxgqhL._SL210_QL95_BG0,0,0,0_FMpng_.png"
          },
          "listTemplate1ListData": {
            "type": "list",
            "listId": "lt1Sample",
            "totalNumberOfItems": 2,
            "listPage": {
              "listItems": [
                {
                  "listItemIdentifier": "gyrohero",
                  "ordinalNumber": 1,
                  "textContent": {
                    "primaryText": {
                      "type": "PlainText",
                      "text": "Gyro Hero"
                    },
                    "secondaryText": {
                      "type": "PlainText",
                      "text": "100 Main Street"
                    },
                    "tertiaryText": {
                      "type": "PlainText",
                      "text": "2 miles"
                    }
                  },
                  "token": "gyrohero"
                },
                {
                  "listItemIdentifier": "greekgrille",
                  "ordinalNumber": 2,
                  "textContent": {
                    "primaryText": {
                      "type": "PlainText",
                      "text": "Greek Grille"
                    },
                    "secondaryText": {
                      "type": "PlainText",
                      "text": "88 Elm Street"
                    },
                    "tertiaryText": {
                      "type": "PlainText",
                      "text": "2.5 miles"
                    }
                  },
                  "token": "greekgrille"
                }
              ]
            }
          }
        }
      TTT

      ret = TemplateDataBuilder.send(:build_data_template, d)

      expect(ret).to eql(ex)
    end
  end

  context 'list items' do
    it 'handles one item' do
      ex = JSON.parse <<~TTT
        {
          "listItemIdentifier": "gyrohero",
          "ordinalNumber": 1,
          "textContent": {
            "primaryText": {
              "type": "PlainText",
              "text": "Gyro Hero"
            },
            "secondaryText": {
              "type": "PlainText",
              "text": "100 Main Street"
            },
            "tertiaryText": {
              "type": "PlainText",
              "text": "2 miles"
            }
          },
          "token": "gyrohero"
        }
      TTT

      d = {
        id: 'gyrohero',
        ordinal_no: 1,
        primary_text: 'Gyro Hero',
        secondary_text: '100 Main Street',
        tertiary_text: '2 miles',
        token: 'gyrohero'
      }

      ret = JSON.parse(TemplateDataBuilder.send(:build_list_item, d))

      expect(ret).to eql(ex)
    end
  end

  context 'long text' do
    it 'formats entry' do
      ex = JSON.parse <<~LONG_TEXT
          {
              "longTextTemplateData": {
                  "type": "object",
                  "objectId": "longTextSample",
                  "properties": {
                      "backgroundImage": {
                          "contentDescription": null,
                          "smallSourceUrl": null,
                          "largeSourceUrl": null,
                          "sources": [
                              {
                                  "url": "https://somepic.com/abcdef.jpg",
                                  "size": "small",
                                  "widthPixels": 0,
                                  "heightPixels": 0
                              },
                              {
                                  "url": "https://somepic.com/abcdef.jpg",
                                  "size": "large",
                                  "widthPixels": 0,
                                  "heightPixels": 0
                              }
                          ]
                      },
                      "title": "No snow emergency in Saint Paul",
                      "textContent": {
                          "primaryText": {
                              "type": "PlainText",
                              "text": "A Snow Emergency is typically declared after snowfalls of 3 inches or more, or after an accumulation of 3 inches or more from several snowfalls. When a snow emergency is declared, which officially goes into effect at 9 p.m., residents are asked to follow specific parking guidelines to allow for efficient snow removal operations. Vehicles in violation of parking restrictions are ticketed and towed."
                          }
                      },
                      "logoUrl": "https://somepic.com/abcdef.jpg",
                      "speechSSML": "<speak>There is not a snow emergency in saint paul.</speak>"
                  },
                  "transformers": [
                      {
                          "inputPath": "speechSSML",
                          "transformer": "ssmlToSpeech",
                          "outputName": "infoSpeech"
                      }
                  ]
              }
          }
        LONG_TEXT

        d = {
          logo_url: 'https://somepic.com/abcdef.jpg',
          card_title: 'No snow emergency in Saint Paul',
          card_text: 'A Snow Emergency is typically declared after snowfalls of 3 inches or more, or after an accumulation of 3 inches or more from several snowfalls. When a snow emergency is declared, which officially goes into effect at 9 p.m., residents are asked to follow specific parking guidelines to allow for efficient snow removal operations. Vehicles in violation of parking restrictions are ticketed and towed.',
          text_to_speak: 'There is not a snow emergency in saint paul.'
        }

        ret = JSON.parse(TemplateDataBuilder.send(:build_long_text, d))

        expect(ret).to eql(ex)
    end
  end
end
