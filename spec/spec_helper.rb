require 'rspec'
require 'guard/spork'

RSpec.configure do |config|
  config.color_enabled = true
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.before(:each) do
    ENV["GUARD_ENV"] = 'test'
    @lib_path = Pathname.new(File.expand_path('../../lib/', __FILE__))
  end

  config.after(:each) do
    ENV["GUARD_ENV"] = nil
  end

end