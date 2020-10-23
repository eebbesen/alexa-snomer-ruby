# frozen_string_literal: true

require_relative './template_data_builder'

## Class to build APL templates
# You'll need to cusom define
# * a document part (I build this using the Alexa Developer Console and save it to another file)
# * code to transform your data into the format APL expect
class AplAssembler
  MPM = 1610.0

  def self.build_directives(data)
    tl = transform_locs data
    <<~DIR
      "directives": [
        {
          "type": "Alexa.Presentation.APL.RenderDocument",
          "version": "1.0",
          "document": #{document_part},
          "datasources": #{datasource_part(tl).to_json}
        }
      ]
    DIR
  end

  def self.transform_policy(text)
  end

  # locaction-specific
  def self.transform_locs(locs)
    ls = []
    locs.each_with_index do |loc, i|
      ls.push(transform_loc(loc, i + 1))
    end
    ls
  end

  # locaction-specific
  def self.transform_loc(d, o)
    id = d[:name].downcase.gsub(/[^a-z]/, '')
    distance = meters_to_miles d[:distance]

    {
      id: id,
      ordinal_no: o,
      primary_text: truncate_text(d[:name]),
      secondary_text: d[:street],
      tertiary_text: "#{distance} miles",
      token: id
    }
  end


  # move to util
  # will try to break text where there are spaces
  def self.truncate_text(text)
    return text if text.length < 30

    t = text[0, 30]
    tr = t.rindex ' '
    return text[0, tr] if tr && tr > 10

    t
  end

  # move to a util
  def self.meters_to_miles(meters)
    (meters / MPM).round 2
  end

  # general
  def self.document_part
    File.read('./apl/apl_template-list_view-document.json')
  end

  # general
  def self.datasource_part(locs)
    TemplateDataBuilder.build_data_template locs
  end
end
