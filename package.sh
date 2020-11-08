#!/bin/bash

# https://docs.aws.amazon.com/lambda/latest/dg/ruby-package.html

# not bundling vendor since I've got no production-dependent gems yet

# bundle clean
# bundle install --path vendor/bundle --without development test
# zip -r target/iag-ruby.zip lambda_function.rb alexa_processor.rb vendor
rm "target/iag*zip"
rm version.txt
version=$(git rev-parse HEAD)
echo $version >> version.txt
ver=$(echo $version | cut -c1-6)
#touch target/iag-ruby_${ver}.zip
zip -rj target/iag-ruby_${ver}v.zip src/lambda_function.rb src/alexa_device.rb src/alexa_event.rb src/alexa_processor.rb src/apl_assembler.rb src/template_data_builder.rb src/alexa_slot.rb version.txt
zip -ur target/iag-ruby_${ver}v.zip apl/apl_template-list_view-document.json apl/apl_template-round_view-document.json apl/apl_template-scroll_view-document.json database/city_map.json
# bundle install --with development test