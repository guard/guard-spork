# Guard::Spork [![Build Status](https://secure.travis-ci.org/guard/guard-spork.png)](http://travis-ci.org/guard/guard-spork)

Guard::Spork allows to automatically & intelligently start/reload your RSpec/Cucumber/Test::Unit [Spork](https://github.com/sporkrb/spork) server(s).

* Compatible with Spork 0.8.4 & 0.9.0.rcX.
* Tested against Ruby 1.8.7, 1.9.2, REE, JRuby and the latest versions Rubinius.

## Install

Please be sure to have [Guard](https://github.com/guard/guard) installed before continuing.

Install the gem:

    $ gem install guard-spork

Add it to your Gemfile (inside development group):

```ruby
group :development do
  gem 'guard-spork'
end
```

Add guard definition to your Guardfile with:

    $ guard init spork

## Usage

Please read the [Guard usage documentation](https://github.com/guard/guard#readme).

## Guardfile

Please read [Guard doc](https://github.com/guard/guard#readme) for more info about the Guardfile DSL.

**IMPORTANT: place Spork guard before RSpec/Cucumber/Test::Unit guards!**

### Rails app

``` ruby
guard 'spork' do
  watch('config/application.rb')
  watch('config/environment.rb')
  watch(%r{^config/environments/.*\.rb$})
  watch(%r{^config/initializers/.*\.rb$})
  watch('Gemfile.lock')
  watch('spec/spec_helper.rb') { :rspec }
  watch('test/test_helper.rb') { :test_unit }
  watch(%r{features/support/}) { :cucumber }
end
```

### Running specs over Spork

Pass the `:cli => "--drb"` option to [Guard::RSpec](https://github.com/guard/guard-rspec) and/or [Guard::Cucumber](https://github.com/guard/guard-cucumber) to run them over the Spork DRb server:

``` ruby
guard 'rspec', :cli => "--drb" do
  # ...
end

guard 'cucumber', :cli => "--drb" do
  # ...
end
```

For MiniTest Guard you should pass the `:drb => true` option:

``` ruby
guard 'minitest', :drb => true do
  # ...
end
```

## Options

Guard::Spork automatically detect RSpec/Cucumber/Test::Unit/Bundler presence but you can disable any of them with the corresponding options:

``` ruby
guard 'spork', :rspec => false, :cucumber => false, :test_unit => false, :bundler => false do
  # ...
end
```

You can provide additional environment variables for RSpec, Cucumber, and Test::Unit with the <tt>:rspec_env</tt>, <tt>:cucumber_env</tt>, and <tt>:test_unit_env</tt> options:

``` ruby
guard 'spork', :cucumber_env => { 'RAILS_ENV' => 'cucumber' }, :rspec_env => { 'RAILS_ENV' => 'test' }, :test_unit_env => { 'RAILS_ENV' => 'test' } do
  # ...
end
```

If your application runs on [Heroku](http://www.heroku.com/) or otherwise uses [Foreman](https://github.com/ddollar/foreman), you can provide the `:foreman => true` option to have environment variables present in the `.env` file passed on to the Spork server.

Available options:

``` ruby
:wait => 60                                # Seconds to wait for the server to start, default: 30. Setting it to nil will cause it to wait indefinitely.
:retry_delay => 60                         # Seconds to wait before retrying booting the server, default: 30. Setting it to nil will cause it to wait indefinitely.
:cucumber => false
:rspec => false
:test_unit => false
:minitest => false
:bundler => false                          # Don't use "bundle exec"
:test_unit_port => 1233                    # Default: 8988
:rspec_port => 1234                        # Default: 8989
:cucumber_port => 4321                     # Default: 8990
:test_unit_env => { 'RAILS_ENV' => 'baz' } # Default: nil
:rspec_env => { 'RAILS_ENV' => 'foo' }     # Default: nil
:cucumber_env => { 'RAILS_ENV' => 'bar' }  # Default: nil
:aggressive_kill => false                  # Default: true, will search Spork pids from `ps aux` and kill them all on start.
:notify_on_start => true                   # Default: false, will notify as soon as starting begins.
:foreman => true                           # Default: false, will start Spork through `foreman run` to pick up environment variables used by Foreman. Pass an env file {:env => ".env.test"}
:quiet => true                             # Default: false, will silence some of the debugging output which can get repetitive (only work with Spork edge at the moment).
```

## Common troubleshooting

If you can start Spork manually but get the following error message when using Guard::Spork:

  Starting Spork for RSpec ERROR: Could not start Spork for RSpec/Cucumber. Make sure you can use it manually first.

Try to increase the value of the `:wait => 60` option before any further investigation.
It's possible that this error is the result of an unnecessary /test directory in the root of your application. Removing the /test directory entirely may resolve this error.

## Development

* Source hosted at [GitHub](https://github.com/guard/guard-spork).
* Report issues and feature requests to [GitHub Issues](https://github.com/guard/guard-spork/issues).

Pull requests are very welcome! Please try to follow these simple "rules", though:

* Please create a topic branch for every separate change you make.
* Make sure your patches are well tested.
* Update the README (if applicable).
* Please **do not change** the version number.

For questions please join us on our [Google group](http://groups.google.com/group/guard-dev) or on `#guard` (irc.freenode.net).

## Author

[Thibaud Guillaume-Gentil](https://github.com/thibaudgg)
