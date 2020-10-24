# alexa-snomer-ruby
Minnesota snow emergency information

Working towards a reusable Ruby interface for Alexa skills with APL

## package
Generates zip file for upload to AWS Lambda for Ruby
```bash
./package.sh
```

## manual test
src/ex.rb is an attempt to simulate the way Alexa accesses the Lambda function
### device with no screen
```bash
src/ex.rb ns
```

### device with screen
```bash
src/ex.rb
```

## unit test
```bash
bundle exec rspec
```
or
```bash
bundle exec rake
```

## APL
### generate templates in the developer console
1. https://developer.amazon.com
1. Select your skill
1. From Build tab click Multimodal Reaponses
1. Click Visual
1. Click Create Visual Response
1. Use tools to craft your visual presentation template
* I like to click the Data icon and use data that's representative of what I intend to display
1. Save your template
1. Download your template to the `apl` directory
* This file will contain the template _and_ any sample data you created

### modify the downloaded template
The downloaded template includes at least three top-level keys: `document`, `datasources` and `sources`.

#### document
We'll save the document values in the `apl` directory. Your file should look like
```json
{
    "type": "APL",
...
}
```

#### datasources
We'll generate our datasources dynamically at runtime

#### sources
I don't know what this is for.

## request payload examples
### request with food slot
```json
{
    "version": "1.0",
    "session": {
        "new": true,
        "sessionId": "amzn1.echo-api.session.33333",
        "application": {
            "applicationId": "amzn1.ask.skill.44444"
        },
        "user": {
            "userId": "amzn1.ask.account.AAAAA",
            "permissions": {
                "consentToken": "yyyyy"
            }
        }
    },
    "context": {
        "Display": {},
        "System": {
            "application": {
                "applicationId": "amzn1.ask.skill.44444"
            },
            "user": {
                "userId": "amzn1.ask.account.AAAAA",
                "permissions": {
                    "consentToken": "yyyyy"
                }
            },
            "device": {
                "deviceId": "amzn1.ask.device.ddddd",
                "supportedInterfaces": {
                    "Display": {
                        "templateVersion": "1.0",
                        "markupVersion": "1.0"
                    },
                    "Alexa.Presentation.APL": {
                        "runtime": {
                            "maxVersion": "1.0"
                        }
                    }
                }
            },
            "apiEndpoint": "https://api.amazonalexa.com",
            "apiAccessToken": "ttttt"
        },
        "Viewport": {
            "experiences": [
                {
                    "arcMinuteWidth": 246,
                    "arcMinuteHeight": 144,
                    "canRotate": false,
                    "canResize": false
                }
            ],
            "shape": "RECTANGLE",
            "pixelWidth": 1024,
            "pixelHeight": 600,
            "dpi": 160,
            "currentPixelWidth": 1024,
            "currentPixelHeight": 600,
            "touch": [
                "SINGLE"
            ]
        }
    },
    "request": {
        "type": "IntentRequest",
        "requestId": "amzn1.echo-api.request.rrrrr",
        "timestamp": "2019-01-21T12:11:37Z",
        "locale": "en-US",
        "intent": {
            "name": "iNeedAGyroIntent",
            "confirmationStatus": "NONE",
            "slots": {
                "foodItem": {
                    "name": "foodItem",
                    "value": "potato",
                    "confirmationStatus": "NONE",
                    "source": "USER"
                },
                "locCount": {
                    "name": "locCount",
                    "value": "2",
                    "confirmationStatus": "NONE",
                    "source": "USER"
                }
            }
        }
    }
}
```

### request with screen
```json
{
    "requestEnvelope": {
        "version": "1.0",
        "session": {
            "new": true,
            "sessionId": "amzn1.echo-api.session.xxx",
            "application": {
                "applicationId": "amzn1.ask.skill.xxx"
            },
            "user": {
                "userId": "amzn1.ask.account.xxx",
                "permissions": {
                    "consentToken": "xxx"
                }
            }
        },
        "context": {
            "Display": {},
            "System": {
                "application": {
                    "applicationId": "amzn1.ask.skill.xxx"
                },
                "user": {
                    "userId": "amzn1.ask.account.xxx",
                    "permissions": {
                        "consentToken": "xxx"
                    }
                },
                "device": {
                    "deviceId": "amzn1.ask.device.xxx",
                    "supportedInterfaces": {
                        "Display": {
                            "templateVersion": "1.0",
                            "markupVersion": "1.0"
                        },
                        "Alexa.Presentation.APL": {
                            "runtime": {
                                "maxVersion": "1.0"
                            }
                        }
                    }
                },
                "apiEndpoint": "https://api.amazonalexa.com",
                "apiAccessToken": "xxx"
            },
            "Viewport": {
                "experiences": [
                    {
                        "arcMinuteWidth": 246,
                        "arcMinuteHeight": 144,
                        "canRotate": false,
                        "canResize": false
                    }
                ],
                "shape": "RECTANGLE",
                "pixelWidth": 1024,
                "pixelHeight": 600,
                "dpi": 160,
                "currentPixelWidth": 1024,
                "currentPixelHeight": 600,
                "touch": [
                    "SINGLE"
                ],
                "keyboard": []
            }
        },
        "request": {
            "type": "LaunchRequest",
            "requestId": "amzn1.echo-api.request.xxx",
            "timestamp": "2019-01-17T06:05:01Z",
            "locale": "en-US",
            "shouldLinkResultBeReturned": false
        }
    },
    "context": {
        "callbackWaitsForEmptyEventLoop": true,
        "logGroupName": "/aws/lambda/alexa-ineedagyro-beta",
        "logStreamName": "2019/01/17/[$LATEST]xxx",
        "functionName": "alexa-ineedagyro-beta",
        "memoryLimitInMB": "128",
        "functionVersion": "$LATEST",
        "invokeid": "xxx",
        "awsRequestId": "xxx",
        "invokedFunctionArn": "arn:aws:lambda:us-east-1:xxx:function:alexa-ineedagyro-beta"
    },
    "attributesManager": {},
    "responseBuilder": {},
    "serviceClientFactory": {
        "apiConfiguration": {
            "apiClient": {},
            "apiEndpoint": "https://api.amazonalexa.com",
            "authorizationValue": "xxx"
        }
    }
}
```
## return payloads
### Text-only payload example
```json
{
    "outputSpeech": {
        "type": "SSML",
        "ssml": "<speak>Your closest yeero is Toppers Pizza at 1154 Grand Ave. . The next closest yeero is Grand Ole Creamery and Grand Pizza at 750 Grand Ave.</speak>"
    }
}
```

### APL payload example
```json
{
    "outputSpeech": {
        "type": "SSML",
        "ssml": "<speak>Your closest yeero is Manhattan Pizza and Pasta at 312 E Diamond Ave. . The next closest yeero is Chicken Basket at 30 N Summit Ave.</speak>"
    },
    "directives": [
        {
            "type": "Alexa.Presentation.APL.RenderDocument",
            "version": "1.0",
            "document": {
                "type": "APL",
                "version": "1.0",
                "theme": "dark",
                "import": [
                    {
                        "name": "alexa-layouts",
                        "version": "1.0.0"
                    }
                ],
                "resources": [
                    {
                        "description": "Stock color for the light theme",
                        "colors": {
                            "colorTextPrimary": "#151920"
                        }
                    },
                    {
                        "description": "Stock color for the dark theme",
                        "when": "${viewport.theme == 'dark'}",
                        "colors": {
                            "colorTextPrimary": "#f0f1ef"
                        }
                    },
                    {
                        "description": "Standard font sizes",
                        "dimensions": {
                            "textSizeBody": 48,
                            "textSizePrimary": 27,
                            "textSizeSecondary": 23,
                            "textSizeDetails": 20,
                            "textSizeSecondaryHint": 25
                        }
                    },
                    {
                        "description": "Common spacing values",
                        "dimensions": {
                            "spacingThin": 6,
                            "spacingSmall": 12,
                            "spacingMedium": 24,
                            "spacingLarge": 48,
                            "spacingExtraLarge": 72
                        }
                    },
                    {
                        "description": "Common margins and padding",
                        "dimensions": {
                            "marginTop": 40,
                            "marginLeft": 60,
                            "marginRight": 60,
                            "marginBottom": 40
                        }
                    }
                ],
                "styles": {
                    "textStyleBase": {
                        "description": "Base font description; set color and core font family",
                        "values": [
                            {
                                "color": "@colorTextPrimary",
                                "fontFamily": "Amazon Ember"
                            }
                        ]
                    },
                    "textStyleBase0": {
                        "description": "Thin version of basic font",
                        "extend": "textStyleBase",
                        "values": {
                            "fontWeight": "100"
                        }
                    },
                    "textStyleBase1": {
                        "description": "Light version of basic font",
                        "extend": "textStyleBase",
                        "values": {
                            "fontWeight": "300"
                        }
                    },
                    "textStyleBase2": {
                        "description": "Regular version of basic font",
                        "extend": "textStyleBase",
                        "values": {
                            "fontWeight": "500"
                        }
                    },
                    "mixinBody": {
                        "values": {
                            "fontSize": "@textSizeBody"
                        }
                    },
                    "mixinPrimary": {
                        "values": {
                            "fontSize": "@textSizePrimary"
                        }
                    },
                    "mixinDetails": {
                        "values": {
                            "fontSize": "@textSizeDetails"
                        }
                    },
                    "mixinSecondary": {
                        "values": {
                            "fontSize": "@textSizeSecondary"
                        }
                    },
                    "textStylePrimary": {
                        "extend": [
                            "textStyleBase1",
                            "mixinPrimary"
                        ]
                    },
                    "textStyleSecondary": {
                        "extend": [
                            "textStyleBase0",
                            "mixinSecondary"
                        ]
                    },
                    "textStyleBody": {
                        "extend": [
                            "textStyleBase1",
                            "mixinBody"
                        ]
                    },
                    "textStyleSecondaryHint": {
                        "values": {
                            "fontFamily": "Bookerly",
                            "fontStyle": "italic",
                            "fontSize": "@textSizeSecondaryHint",
                            "color": "@colorTextPrimary"
                        }
                    },
                    "textStyleDetails": {
                        "extend": [
                            "textStyleBase2",
                            "mixinDetails"
                        ]
                    }
                },
                "layouts": {
                    "ListTemplate1": {
                        "parameters": [
                            "backgroundImage",
                            "title",
                            "logo",
                            "hintText",
                            "listData"
                        ],
                        "item": [
                            {
                                "type": "Container",
                                "width": "100vw",
                                "height": "100vh",
                                "direction": "column",
                                "items": [
                                    {
                                        "type": "AlexaHeader",
                                        "headerTitle": "${title}",
                                        "headerAttributionImage": "${logo}"
                                    },
                                    {
                                        "type": "Sequence",
                                        "grow": 1,
                                        "height": "80vh",
                                        "scrollDirection": "vertical",
                                        "paddingLeft": "@marginLeft",
                                        "paddingRight": "@marginRight",
                                        "data": "${listData}",
                                        "numbered": true,
                                        "items": [
                                            {
                                                "type": "VerticalListItem",
                                                "image": "${data.image.sources[0].url}",
                                                "primaryText": "${data.textContent.primaryText.text}",
                                                "secondaryText": "${data.textContent.secondaryText.text}",
                                                "tertiaryText": "${data.textContent.tertiaryText.text}"
                                            }
                                        ]
                                    }
                                ]
                            }
                        ]
                    },
                    "VerticalListItem": {
                        "parameters": [
                            "primaryText",
                            "secondaryText",
                            "tertiaryText"
                        ],
                        "items": [
                            {
                                "when": "${viewport.shape == 'round'}",
                                "type": "Container",
                                "direction": "column",
                                "height": 200,
                                "width": "100%",
                                "alignItems": "center",
                                "items": [
                                    {
                                        "type": "Text",
                                        "text": "${primaryText}",
                                        "paddingBottom": "20dp",
                                        "color": "white",
                                        "spacing": "5dp",
                                        "textAlign": "center",
                                        "maxLines": 2
                                    },
                                    {
                                        "type": "Container",
                                        "spacing": 25,
                                        "items": [
                                            {
                                                "type": "Text",
                                                "text": "${tertiaryText}",
                                                "style": "textStyleDetails",
                                                "fontWeight": "300",
                                                "grow": 1,
                                                "shrink": 1,
                                                "maxLines": 1
                                            }
                                        ]
                                    }
                                ]
                            },
                            {
                                "type": "Container",
                                "direction": "row",
                                "height": 125,
                                "width": "100%",
                                "alignItems": "center",
                                "separator": true,
                                "items": [
                                    {
                                        "type": "Text",
                                        "text": "${ordinal}",
                                        "paddingBottom": "20dp",
                                        "color": "white",
                                        "spacing": "5dp"
                                    },
                                    {
                                        "type": "Container",
                                        "spacing": 30,
                                        "direction": "column",
                                        "items": [
                                            {
                                                "type": "Text",
                                                "text": "${primaryText}",
                                                "style": "textStyleBody",
                                                "fontWeight": "300",
                                                "grow": 1,
                                                "shrink": 1,
                                                "maxLines": 1
                                            },
                                            {
                                                "type": "Text",
                                                "text": "${secondaryText}",
                                                "style": "textStyleDetails",
                                                "fontWeight": "300",
                                                "grow": 1,
                                                "shrink": 1,
                                                "maxLines": 1
                                            }
                                        ]
                                    },
                                    {
                                        "type": "Text",
                                        "text": "${tertiaryText}",
                                        "style": "textStyleBody",
                                        "fontWeight": "300",
                                        "grow": 1,
                                        "shrink": 1,
                                        "textAlign": "right",
                                        "maxLines": 1
                                    }
                                ]
                            }
                        ]
                    }
                },
                "mainTemplate": {
                    "parameters": [
                        "payload"
                    ],
                    "item": [
                        {
                            "type": "ListTemplate1",
                            "backgroundImage": "${payload.listTemplate1Metadata.backgroundImage.sources[0].url}",
                            "title": "${payload.listTemplate1Metadata.title}",
                            "logo": "${payload.listTemplate1Metadata.logoUrl}",
                            "listData": "${payload.listTemplate1ListData.listPage.listItems}"
                        }
                    ]
                }
            },
            "datasources": {
                "listTemplate1Metadata": {
                    "type": "object",
                    "objectId": "lt1Metadata",
                    "title": "You-ros (gyros near you)",
                    "logoUrl": "https://images-na.ssl-images-amazon.com/images/I/81QXYqxgqhL._SL210_QL95_BG0,0,0,0_FMpng_.png"
                },
                "listTemplate1ListData": {
                    "type": "list",
                    "listId": "lt1Sample",
                    "totalNumberOfItems": 4,
                    "listPage": {
                        "listItems": [
                            {
                                "listItemIdentifier": "manhattanpizzapasta",
                                "ordinalNumber": 1,
                                "textContent": {
                                    "primaryText": {
                                        "type": "PlainText",
                                        "text": "Manhattan Pizza & Pasta"
                                    },
                                    "secondaryText": {
                                        "type": "PlainText",
                                        "text": "312 E Diamond Ave"
                                    },
                                    "tertiaryText": {
                                        "type": "PlainText",
                                        "text": "0.2 miles"
                                    }
                                },
                                "token": "manhattanpizzapasta"
                            },
                            {
                                "listItemIdentifier": "chickenbasket",
                                "ordinalNumber": 2,
                                "textContent": {
                                    "primaryText": {
                                        "type": "PlainText",
                                        "text": "Chicken Basket"
                                    },
                                    "secondaryText": {
                                        "type": "PlainText",
                                        "text": "30 N Summit Ave"
                                    },
                                    "tertiaryText": {
                                        "type": "PlainText",
                                        "text": "0.2 miles"
                                    }
                                },
                                "token": "chickenbasket"
                            },
                            {
                                "listItemIdentifier": "starvinmarvin",
                                "ordinalNumber": 3,
                                "textContent": {
                                    "primaryText": {
                                        "type": "PlainText",
                                        "text": "Starvin Marvin"
                                    },
                                    "secondaryText": {
                                        "type": "PlainText",
                                        "text": "211 N Frederick Ave"
                                    },
                                    "tertiaryText": {
                                        "type": "PlainText",
                                        "text": "0.7 miles"
                                    }
                                },
                                "token": "starvinmarvin"
                            },
                            {
                                "listItemIdentifier": "villagegreenrestaura",
                                "ordinalNumber": 4,
                                "textContent": {
                                    "primaryText": {
                                        "type": "PlainText",
                                        "text": "Village Green Restaurant"
                                    },
                                    "secondaryText": {
                                        "type": "PlainText",
                                        "text": "120 N Frederick Ave"
                                    },
                                    "tertiaryText": {
                                        "type": "PlainText",
                                        "text": "0.7 miles"
                                    }
                                },
                                "token": "villagegreenrestaura"
                            }
                        ]
                    }
                }
            }
        }
    ]
}
```

### device address request
See spec/vcr_cassettes/address_request.yml. To capture, use the Alexa Developer Console to send a test payload to the Ruby lambda. If logging is enabled for the payload you capture the `apiAccessToken` and `deviceId` and reuse them via the VCR-enabled address test(s) in spec/alexa_processor_spec.rb.

# Tools
https://developer.amazon.com/docs/custom-skills/request-and-response-json-reference.html#response-format