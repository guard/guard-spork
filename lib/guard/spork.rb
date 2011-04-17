require 'guard'
require 'guard/guard'

module Guard
  class Spork < Guard

    autoload :Runner, 'guard/spork/runner'
    attr_accessor :runner

    def initialize(watchers=[], options={})
      super
      @runner = Runner.new(options)
    end

    def start
      runner.kill_sporks
      runner.launch_sporks("start")
    end

    def reload
      runner.kill_sporks
      runner.launch_sporks("reload")
    end

    def run_on_change(paths)
      runner.kill_sporks
      runner.launch_sporks("reload")
    end

    def stop
      runner.kill_sporks
    end

  end
end
