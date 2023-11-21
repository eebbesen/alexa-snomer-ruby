# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'rake'
end

group :development do
  gem 'rubocop'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara'
  gem 'rspec'
  gem 'selenium-webdriver'
  gem 'simplecov'
  gem 'vcr'
  gem 'webdrivers'
  gem 'webmock'
end
