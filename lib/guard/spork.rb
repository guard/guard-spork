require 'guard'
require 'guard/plugin'
require 'childprocess'

module Guard
  class Spork < Plugin

    autoload :Runner, 'guard/spork/runner'
    autoload :SporkInstance, 'guard/spork/spork_instance'
    autoload :SporkWindowsInstance, 'guard/spork/spork_windows_instance'
    attr_accessor :runner

    def initialize(options={})
      super
      @runner = Runner.new(options)
    end

    def start
      runner.kill_global_sporks
      runner.launch_sporks("start")
    end

    def reload
      runner.kill_sporks
      runner.launch_sporks("reload")
    end

    def run_on_additions(paths)
        runner.kill_sporks
        runner.launch_sporks("reload")
    end

    def run_on_modifications(paths)
        runner.kill_sporks
        runner.launch_sporks("reload")
    end

    def stop
      runner.kill_sporks
    end

  end
end
