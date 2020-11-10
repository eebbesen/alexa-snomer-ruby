# frozen_string_literal: true

require_relative '../src/alexa_device'
require_relative 'spec_helper'

RSpec.describe AlexaDevice do
  context '#pick_font_size' do
    it 'handles round' do
      ad = AlexaDevice.new JSON.parse(slug_hub_json(480, 480))
      expect(ad.pick_font_size).to eq('170db')
    end

    it 'handles small' do
      ad = AlexaDevice.new JSON.parse(slug_hub_json(480, 960))
      expect(ad.pick_font_size).to eq('30db')
    end

    it 'provides default when no match' do
      ad = AlexaDevice.new JSON.parse(slug_hub_json(1, 1))
      expect(ad.pick_font_size).to eq('40db')
    end

    it 'provides default when nil inputs' do
      ad = AlexaDevice.new JSON.parse(slug_hub_json(1, 1))
      ad.instance_variable_set(:@height, nil)
      ad.instance_variable_set(:@width, nil)
      expect(ad.pick_font_size).to eq('40db')

      ad.instance_variable_set(:@height, 1)
      ad.instance_variable_set(:@width, nil)
      expect(ad.pick_font_size).to eq('40db')

      ad.instance_variable_set(:@height, nil)
      ad.instance_variable_set(:@width, 1)
      expect(ad.pick_font_size).to eq('40db')
    end
  end

  it 'creates with small round Viewport JSON' do
    ad = AlexaDevice.new JSON.parse(small_hub_json)

    expect(ad.round?).to be_truthy
    expect(ad.rectangle?).to be_falsey
    expect(ad.apl?).to be_truthy
    expect(ad.height).to eq(480)
    expect(ad.width).to eq(480)
  end

  it 'creates with medium Viewport JSON' do
    ad = AlexaDevice.new JSON.parse(medium_hub_json)

    expect(ad.round?).to be_falsey
    expect(ad.rectangle?).to be_truthy
    expect(ad.apl?).to be_truthy
    expect(ad.height).to eq(799)
    expect(ad.width).to eq(1363)
  end

  private

  def slug_hub_json(h, w)
    <<-JSON
      {
        "context": {
          "Viewport": {
            "shape": "ROUND",
            "pixelWidth": #{w},
            "pixelHeight": #{h},
            "currentPixelWidth": #{w},
            "currentPixelHeight": #{h}
          },
          "System": {
            "device": {
              "deviceId": "amzn1.ask.device.DDDD",
              "supportedInterfaces": {
                "Alexa.Presentation.APL": {
                  "runtime": {
                    "maxVersion": "1.5"
                  }
                },
                "Display": {
                  "templateVersion": "1.0",
                  "markupVersion": "1.0"
                }
              }
            }
          }
        }
      }
    JSON
  end

  def medium_hub_json
    <<-JSON
      {
        "context": {
          "Viewports": [
            {
              "type": "APL",
              "id": "main",
              "shape": "RECTANGLE",
              "dpi": 213,
              "presentationType": "STANDARD",
              "canRotate": false,
              "configuration": {
                "current": {
                  "mode": "HUB",
                  "video": {
                    "codecs": [
                      "H_264_42",
                      "H_264_41"
                    ]
                  },
                  "size": {
                    "type": "DISCRETE",
                    "pixelWidth": 1363,
                    "pixelHeight": 799
                  }
                }
              }
            }
          ],
          "Viewport": {
            "experiences": [
              {
                "arcMinuteWidth": 346,
                "arcMinuteHeight": 216,
                "canRotate": false,
                "canResize": false
              }
            ],
            "mode": "HUB",
            "shape": "RECTANGLE",
            "pixelWidth": 1363,
            "pixelHeight": 799,
            "dpi": 213,
            "currentPixelWidth": 1363,
            "currentPixelHeight": 799,
            "touch": [
              "SINGLE"
            ],
            "video": {
              "codecs": [
                "H_264_42",
                "H_264_41"
              ]
            }
          },
          "Extensions": {
            "available": {
              "aplext:backstack:10": {}
            }
          },
          "System": {
            "device": {
              "deviceId": "amzn1.ask.device.xxxx",
              "supportedInterfaces": {
                "Alexa.Presentation.APL": {
                  "runtime": {
                    "maxVersion": "1.5"
                  }
                },
                "Display": {
                  "templateVersion": "1.0",
                  "markupVersion": "1.0"
                }
              }
            },
            "apiEndpoint": "https://api.amazonalexa.com",
            "apiAccessToken": "xxxxx"
          },
          "Display": {},
          "Alexa.Presentation.APL": {
            "token": "",
            "version": "APL_WEB_RENDERER_GANDALF",
            "componentsVisibleOnScreen": [
              {
                "uid": ":1000",
                "position": "1023x600+0+0:0",
                "type": "mixed",
                "tags": {
                  "viewport": {}
                },
                "children": [
                  {
                    "uid": ":1001",
                    "position": "1023x600+0+0:0",
                    "type": "graphic",
                    "tags": {},
                    "visibility": 0.9992662668228149,
                    "entities": []
                  },
                  {
                    "uid": ":1005",
                    "position": "1023x100+0+0:1",
                    "type": "mixed",
                    "tags": {},
                    "visibility": 0.9992663264274597,
                    "entities": []
                  },
                  {
                    "id": "Content",
                    "uid": ":1016",
                    "position": "896x309+63+132:1",
                    "type": "text",
                    "tags": {
                      "spoken": true
                    },
                    "entities": []
                  }
                ],
                "entities": []
              }
            ]
          }
        }
      }
    JSON
  end

  def small_hub_json
    <<-JSON
      {
        "context": {
          "Viewports": [
            {
              "type": "APL",
              "id": "main",
              "shape": "ROUND",
              "dpi": 160,
              "presentationType": "STANDARD",
              "canRotate": false,
              "configuration": {
                "current": {
                  "mode": "HUB",
                  "video": {
                    "codecs": [
                      "H_264_41"
                    ]
                  },
                  "size": {
                    "type": "DISCRETE",
                    "pixelWidth": 480,
                    "pixelHeight": 480
                  }
                }
              }
            }
          ],
          "Viewport": {
            "experiences": [
              {
                "arcMinuteWidth": 144,
                "arcMinuteHeight": 144,
                "canRotate": false,
                "canResize": false
              }
            ],
            "mode": "HUB",
            "shape": "ROUND",
            "pixelWidth": 480,
            "pixelHeight": 480,
            "dpi": 160,
            "currentPixelWidth": 480,
            "currentPixelHeight": 480,
            "touch": [
              "SINGLE"
            ],
            "video": {
              "codecs": [
                "H_264_41"
              ]
            }
          },
          "System": {
            "device": {
              "deviceId": "amzn1.ask.device.DDDD",
              "supportedInterfaces": {
                "Alexa.Presentation.APL": {
                  "runtime": {
                    "maxVersion": "1.5"
                  }
                },
                "Display": {
                  "templateVersion": "1.0",
                  "markupVersion": "1.0"
                }
              }
            }
          },
          "Display": {}
        }
      }
    JSON
  end
end
