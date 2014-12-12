guard :rspec, cmd: "bundle exec rspec" do
  require "ostruct"

  rspec = OpenStruct.new
  rspec.spec_dir = "spec"
  rspec.spec = ->(m) { "#{rspec.spec_dir}/#{m}_spec.rb" }
  rspec.spec_helper = "#{rspec.spec_dir}/spec_helper.rb"

  # matchers
  rspec.spec_files = %r{^#{rspec.spec_dir}/.+_spec\.rb$}

  # Ruby apps
  ruby = OpenStruct.new
  ruby.lib_files = %r{^(lib/.+)\.rb$}

  watch(rspec.spec_files)
  watch(rspec.spec_helper) { rspec.spec_dir }
  watch(ruby.lib_files)    { |m| rspec.spec.(m[1]) }
end
