# frozen_string_literal: true

## Builds the APL datasource
class TemplateDataBuilder
  LIH = <<~LIST_ITEM_HEADER
    "listTemplate1Metadata": {
        "type": "object",
        "objectId": "lt1Metadata",
        "title": "%{app_name}",
        "logoUrl": "%{logo_url}"
    },
    "listTemplate1ListData": {
        "type": "list",
        "listId": "lt1Sample",
        "totalNumberOfItems": %{list_size},
        "listPage": {
            "listItems": [%{list_items}]
        }
    }
  LIST_ITEM_HEADER

  LI = <<~LIST_ITEM
    {
        "listItemIdentifier": "%{id}",
        "ordinalNumber": %{ordinal_no},
        "textContent": {
            "primaryText": {
                "type": "PlainText",
                "text": "%{primary_text}"
            },
            "secondaryText": {
                "type": "PlainText",
                "text": "%{secondary_text}"
            },
            "tertiaryText": {
                "type": "PlainText",
                "text": "%{tertiary_text}"
            }
        },
        "token": "%{token}"
    }
  LIST_ITEM

  LT = <<~LONG_TEXT
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
                        "url": "%{logo_url}",
                        "size": "small",
                        "widthPixels": 0,
                        "heightPixels": 0
                    },
                    {
                        "url": "%{logo_url}",
                        "size": "large",
                        "widthPixels": 0,
                        "heightPixels": 0
                    }
                ]
            },
            "title": "%{card_title}",
            "textContent": {
                "primaryText": {
                    "type": "PlainText",
                    "text": "%{card_text}"
                }
            },
            "logoUrl": "%{logo_url}",
            "speechSSML": "<speak>%{text_to_speak}</speak>"
        },
        "transformers": [
            {
                "inputPath": "speechSSML",
                "transformer": "ssmlToSpeech",
                "outputName": "infoSpeech"
            }
        ]
    }
  LONG_TEXT

  # interpolated String of list item data
  private_class_method def self.build_list_item(item)
    (LI % item).to_s
  end

  # interpolated String of long text data
  private_class_method def self.build_long_text(item)
    (LT % item).to_s
  end

  def self.build_data_template_list(items)
    list = items.map { |i| build_list_item i }
    d = {
      list_size: list.size,
      list_items: list.join(','),
      app_name: ENV['APP_NAME'],
      logo_url: ENV['LOGO_URL']
    }

    JSON.parse "{#{LIH % d}}"
  end

  def self.build_data_template_text(data)
    d = {
      card_title: data[:title],
      card_text: data[:text],
      text_to_speak: data[:to_speak],
      app_name: ENV['APP_NAME'],
      logo_url: ENV['LOGO_URL']
    }

    JSON.parse "{#{LT % d}}"
  end
end
