# frozen_string_literal: true

require_relative '../src/apl_assembler'
require 'json'
require 'spec_helper'

RSpec.describe AplAssembler do
  it 'assembles directives' do
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

    ret = AplAssembler.build_directives locs

    expect(JSON.parse("{#{ret}}")).to eql(JSON.parse(ex))
  end

  context 'converts meters to miles' do
    it 'handles less than a mile' do
      expect(AplAssembler.meters_to_miles(100)).to eql(0.06)
    end

    it 'handles more than a mile' do
      expect(AplAssembler.meters_to_miles(3000)).to eql(1.86)
    end
  end

  it 'transforms loc' do
    d = { city: 'Saint Paul', name: 'Greek Grille & Happy Fun Time Place', street: '88 Elm Street', distance: 254.7828343564675 }
    ret = AplAssembler.send(:transform_loc, d, 2)
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

    ret = AplAssembler.transform_locs locs

    expect(ret.count).to eql(2)
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

  context 'truncates names' do
    it 'preserves short strings' do
      ret = AplAssembler.send(:truncate_text, 'Gyro Hero')
      expect(ret).to eql('Gyro Hero')
    end

    it 'truncates long strings with spaces' do
      ret = AplAssembler.send(:truncate_text, 'Greek Kitchen Modern Mediterranean')
      expect(ret).to eql('Greek Kitchen Modern')
    end

    it 'truncates long strings without spaces' do
      ret = AplAssembler.send(:truncate_text, 'averynicedayisfromthebestpartofanywhere')
      expect(ret).to eql('averynicedayisfromthebestparto')
    end
  end
end
