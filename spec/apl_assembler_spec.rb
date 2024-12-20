# frozen_string_literal: true

require_relative '../src/apl_assembler'
require 'json'
require 'spec_helper'

RSpec.describe AplAssembler do
  before do
    ENV['APP_NAME'] = 'Snow Emergency'
    ENV['LOGO_URL'] = 'https://images-na.ssl-images-amazon.com/images/I/81QXYqxgqhL._SL210_QL95_BG0,0,0,0_FMpng_.png'
  end

  it 'assembles directives for list' do
    ex_data = <<~EEXXDD
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
                     "listItemIdentifier": "greekgrille",
                     "ordinalNumber": 1,
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
                           "text": "0.16 miles"
                        }
                     },
                     "token": "greekgrille"
                  },
                  {
                     "listItemIdentifier": "gyrohero",
                     "ordinalNumber": 2,
                     "textContent": {
                        "primaryText": {
                           "type": "PlainText",
                           "text": "Gyro Hero"
                        },
                        "secondaryText": {
                           "type": "PlainText",
                           "text": "100 Peach Ave N"
                        },
                        "tertiaryText": {
                           "type": "PlainText",
                           "text": "0.63 miles"
                        }
                     },
                     "token": "gyrohero"
                  }
               ]
            }
         }
      }
    EEXXDD

    ex = <<~EEXX
      {"directives": [
        {
          "type": "Alexa.Presentation.APL.RenderDocument",
          "version": "1.0",
          "document": #{File.read('./apl/apl_template-list_view-document.json')},
          "datasources": #{ex_data}
        }
      ]}
    EEXX

    locs = [
      { city: 'Saint Paul', name: 'Greek Grille', street: '88 Elm Street', distance: 254.7828343564675 },
      { city: 'Saint Paul', name: 'Gyro Hero', street: '100 Peach Ave N', distance: 1006.7278773057899 }
    ]

    ret = described_class.build_directives locs, :list

    expect(JSON.parse("{#{ret}}")).to eql(JSON.parse(ex))
  end

  it 'raises error with invalid type' do
    described_class.build_directives nil, :html
    raise StandardError, 'should have thrown error'
  rescue StandardError => e
    expect(e.message).to eq('unrecognized APL type: html. Only :list and :text are valid.')
  end

  it 'assembles directives for scroll' do
    ex_data = <<~EEXXDD
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
                  "url": "https://images-na.ssl-images-amazon.com/images/I/81QXYqxgqhL._SL210_QL95_BG0,0,0,0_FMpng_.png",
                  "size": "small",
                  "widthPixels": 0,
                  "heightPixels": 0
                },
                {
                  "url": "https://images-na.ssl-images-amazon.com/images/I/81QXYqxgqhL._SL210_QL95_BG0,0,0,0_FMpng_.png",
                  "size": "large",
                  "widthPixels": 0,
                  "heightPixels": 0
                }
              ]
            },
            "title": "Saint Paul: No snow emergency",
            "textContent": {
              "primaryText": {
                "type": "PlainText",
                "text": "A Snow Emergency is typically declared after snowfalls of 3 inches or more, or after an accumulation of 3 inches or more from several snowfalls. When a snow emergency is declared, which officially goes into effect at 9 p.m., residents are asked to follow specific parking guidelines to allow for efficient snow removal operations. Vehicles in violation of parking restrictions are ticketed and towed."
              }
            },
            "logoUrl": "https://images-na.ssl-images-amazon.com/images/I/81QXYqxgqhL._SL210_QL95_BG0,0,0,0_FMpng_.png",
            "speechSSML": "<speak>There is a snow emergency in saintpaul</speak>",
            "fontSize": "30dp"
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
    EEXXDD

    ex = <<~EEXX
      {"directives": [
        {
          "type": "Alexa.Presentation.APL.RenderDocument",
          "version": "1.0",
          "document": #{format(File.read('./apl/apl_template-scroll_view-document.json'), header_background_color: 'green', header_theme: 'dark')},
          "datasources": #{ex_data}
        }
      ]}
    EEXX

    data = {
      header_background_color: 'green',
      header_theme: 'dark',
      title: 'Saint Paul: No snow emergency',
      text: 'A Snow Emergency is typically declared after snowfalls of 3 inches or more, or after an accumulation of 3 inches or more from several snowfalls. When a snow emergency is declared, which officially goes into effect at 9 p.m., residents are asked to follow specific parking guidelines to allow for efficient snow removal operations. Vehicles in violation of parking restrictions are ticketed and towed.',
      to_speak: '<speak>There is a snow emergency in saintpaul</speak>',
      app_name: ENV.fetch('APP_NAME', nil),
      logo_url: ENV.fetch('LOGO_URL', nil),
      font_size: '30dp'
    }

    ret = described_class.build_directives data, :text

    expect(JSON.parse("{#{ret}}")).to eql(JSON.parse(ex))
  end

  it 'assembles directives for round' do
    ex_data = <<~EEXXDD
      {
        "roundTextTemplateData": {
            "type": "object",
            "objectId": "roundTextSample",
            "properties": {
                "speechSSML": "<speak>There is a snow emergency in saintpaul</speak>",
                "text": "YES"
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
    EEXXDD

    ex = <<~EEXX
      {"directives": [
        {
          "type": "Alexa.Presentation.APL.RenderDocument",
          "version": "1.0",
          "document": #{File.read('./apl/apl_template-round_view-document.json')},
          "datasources": #{ex_data}
        }
      ]}
    EEXX

    data = {
      text: 'YES',
      to_speak: '<speak>There is a snow emergency in saintpaul</speak>',
      app_name: ENV.fetch('APP_NAME', nil),
      logo_url: ENV.fetch('LOGO_URL', nil)
    }

    ret = described_class.build_directives data, :round

    expect(JSON.parse("{#{ret}}")).to eql(JSON.parse(ex))
  end

  context 'when converts meters to miles' do
    it 'handles less than a mile' do
      expect(described_class.meters_to_miles(100)).to be(0.06)
    end

    it 'handles more than a mile' do
      expect(described_class.meters_to_miles(3000)).to be(1.86)
    end
  end

  it 'transforms loc' do
    d = { city: 'Saint Paul', name: 'Greek Grille & Happy Fun Time Place', street: '88 Elm Street', distance: 254.7828343564675 }
    ret = described_class.send(:transform_loc, d, 2)
    expect(ret).to eql({
                         id: 'greekgrillehappyfuntimeplace',
                         ordinal_no: 2,
                         primary_text: 'Greek Grille & Happy Fun Time',
                         secondary_text: '88 Elm Street',
                         tertiary_text: '0.16 miles',
                         token: 'greekgrillehappyfuntimeplace'
                       })
  end

  it 'transforms locs' do
    locs = [
      { city: 'Saint Paul', name: 'Greek Grille', street: '88 Elm Street', distance: 254.7828343564675 },
      { city: 'Saint Paul', name: 'Gyro Hero', street: '100 Peach Ave N', distance: 1006.7278773057899 }
    ]

    ret = described_class.transform_locs locs

    expect(ret.count).to be(2)
    expect(ret.first).to eql({
                               id: 'greekgrille',
                               ordinal_no: 1,
                               primary_text: 'Greek Grille',
                               secondary_text: '88 Elm Street',
                               tertiary_text: '0.16 miles',
                               token: 'greekgrille'
                             })

    expect(ret.last).to eql({
                              id: 'gyrohero',
                              ordinal_no: 2,
                              primary_text: 'Gyro Hero',
                              secondary_text: '100 Peach Ave N',
                              tertiary_text: '0.63 miles',
                              token: 'gyrohero'
                            })
  end

  context 'when truncates names' do
    it 'preserves short strings' do
      ret = described_class.send(:truncate_text, 'Gyro Hero')
      expect(ret).to eql('Gyro Hero')
    end

    it 'truncates long strings with spaces' do
      ret = described_class.send(:truncate_text, 'Greek Kitchen Modern Mediterranean')
      expect(ret).to eql('Greek Kitchen Modern')
    end

    it 'truncates long strings without spaces' do
      ret = described_class.send(:truncate_text, 'averynicedayisfromthebestpartofanywhere')
      expect(ret).to eql('averynicedayisfromthebestparto')
    end
  end
end
