# Running the fast cucumber profile will require this file instead of env.rb
# Add any other files you want to require here

require 'awesome_print'
require 'cucumber/rspec/doubles'
require File.expand_path('../spec/fast_model', File.dirname(__FILE__))

ENV["RAILS_ENV"] ||= "test"

steps = %w(
  custom_css/customize_css_steps
)

steps.each do |step|
  full_path = File.expand_path("../features/step_definitions/#{step}.rb", File.dirname(__FILE__)) 
  puts "Loading Step Definition: #{step}"
  load full_path
end
