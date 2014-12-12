require 'rspec'
require 'guard/spork'

ENV["GUARD_ENV"] = 'test'

RSpec.configure do |config|
  config.color = true
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
