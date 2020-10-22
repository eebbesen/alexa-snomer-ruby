# frozen_string_literal: true

## Builds the APL datasource
class TemplateDataBuilder
  LIH = <<~LIST_ITEM_HEADER
    "listTemplate1Metadata": {
        "type": "object",
        "objectId": "lt1Metadata",
        "title": "Snow Emergency",
        "logoUrl": "https://images-na.ssl-images-amazon.com/images/I/81QXYqxgqhL._SL210_QL95_BG0,0,0,0_FMpng_.png"
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

  # interpolated String of list item data
  private_class_method def self.build_list_item(item)
    (LI % item).to_s
  end

  def self.build_data_template(items)
    locs = items.map { |i| build_list_item i }
    d = {
      list_size: locs.size,
      list_items: locs.join(',')
    }

    JSON.parse "{#{LIH % d}}"
  end
end
