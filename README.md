![unit tests](https://github.com/eebbesen/alexa-snomer-ruby/workflows/unit%20tests/badge.svg)

# alexa-snomer-ruby
Minnesota snow emergency information

Working towards a reusable Ruby interface for Alexa skills with APL

## package
Generates zip file for upload to AWS Lambda for Ruby
```bash
./package.sh
```

## deploy
For display please set the following environment variables
* `APP_NAME`
* `LOGO_URL`


## manual test
src/ex.rb is an attempt to simulate the way Alexa accesses the Lambda function
### device with no screen
```bash
ruby src/ex.rb ns
```

### device with screen
```bash
ruby src/ex.rb
```

## unit test
```bash
bundle exec rspec
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
More to come

# Tools
* https://developer.amazon.com/docs/custom-skills/request-and-response-json-reference.html#response-format
* https://www.minnesota-demographics.com/cities_by_population
