# frozen_string_literal: true

require_relative './template_data_builder'

##
class AplAssembler
  MPM = 1610.0

  def self.build_directives(locs)
    tl = transform_locs locs
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

  def self.meters_to_miles(meters)
    (meters / MPM).round 2
  end

  def self.transform_locs(locs)
    ls = []
    locs.each_with_index do |loc, i|
      ls.push(transform_loc(loc, i + 1))
    end
    ls
  end

  def self.truncate_name(name)
    return name if name.length < 30

    t = name[0, 30]
    tr = t.rindex ' '
    return name[0, tr] if tr && tr > 10

    t
  end

  def self.transform_loc(d, o)
    id = d[:name].downcase.gsub(/[^a-z]/, '')
    distance = meters_to_miles d[:distance]

    {
      id: id,
      ordinal_no: o,
      primary_text: truncate_name(d[:name]),
      secondary_text: d[:street],
      tertiary_text: "#{distance} miles",
      token: id
    }
  end

  def self.document_part
    File.read('./apl/apl_template-list_view-document.json')
  end

  def self.datasource_part(locs)
    TemplateDataBuilder.build_data_template locs
  end
end
