require 'guard/compat/plugin'
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
      relaunch_sporks
    end

    def run_on_additions(paths)
      relaunch_sporks
    end

    def run_on_modifications(paths)
      relaunch_sporks
    end

    def stop
      runner.kill_sporks
    end

    private

    def relaunch_sporks
      runner.kill_sporks
      runner.launch_sporks("reload")
    end

  end
end
