# frozen_string_literal: true

require_relative '../src/template_data_builder'
require 'json'
require 'spec_helper'

RSpec.describe TemplateDataBuilder do
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
end
