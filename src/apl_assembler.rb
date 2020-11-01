# frozen_string_literal: true

require_relative './template_data_builder'

## Class to build APL templates
# You'll need to custom define
# * a document part (I build this using the Alexa Developer Console and save it to another file)
# * code to transform your data into the format APL expect
class AplAssembler
  MPM = 1610.0

  def self.build_directives(data, type)
    document_part = nil
    data_part = nil

    case type
    when :list
      tl = transform_locs data
      data_part = TemplateDataBuilder.build_data_template_list(tl).to_json
      document_part = File.read('./apl/apl_template-list_view-document.json')
    when :round
      document_part = File.read('./apl/apl_template-round_view-document.json')
    when :text
      data_part = TemplateDataBuilder.build_data_template_text(data).to_json
      document_part = File.read('./apl/apl_template-scroll_view-document.json') % data
      # need to populate header_background_color
    else
      raise StandardError, "unrecognized APL type: #{type}. Only :list and :text are valid."
    end

    <<~DIR
      "directives": [
        {
          "type": "Alexa.Presentation.APL.RenderDocument",
          "version": "1.0",
          "document": #{document_part},
          "datasources": #{data_part}
        }
      ]
    DIR
  end

  def self.transform_policy(text); end

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
    File.read('./apl/apl_template-scroll_view-document.json')
  end
end
