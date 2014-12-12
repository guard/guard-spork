require 'rspec'
require 'guard/spork'

ENV["GUARD_ENV"] = 'test'

RSpec.configure do |config|
  config.color = true
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.treat_symbols_as_metadata_keys_with_true_values = true
end
