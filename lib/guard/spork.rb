require 'guard'
require 'guard/guard'
require 'childprocess'

module Guard
  class Spork < Guard

    autoload :Runner, 'guard/spork/runner'
    autoload :SporkInstance, 'guard/spork/spork_instance'
    autoload :SporkWindowsInstance, 'guard/spork/spork_windows_instance'
    attr_accessor :runner

    def initialize(watchers=[], options={})
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

    def run_on_changes(paths_or_symbol)
      if paths_or_symbol.is_a?(Symbol)
        runner.kill_sporks(paths_or_symbol)
        runner.launch_sporks("reload", paths_or_symbol)
      else
        runner.kill_sporks
        runner.launch_sporks("reload")
      end
    end

    def stop
      runner.kill_sporks
    end

  end
end
