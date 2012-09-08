module Guard
  class Spork
    class SporkInstance
      attr_reader :type, :env, :port, :options, :pid, :process

      def initialize(type, port, env, options)
        @type = type
        @port = port
        @env = env
        @options = options
      end

      def to_s
        case type
        when :rspec
          "RSpec"
        when :cucumber
          "Cucumber"
        when :test_unit
          "Test::Unit"
        when :minitest
          "MiniTest"
        else
          type.to_s
        end
      end

      def start
        cmd = [command]

        if self.class.windows?
          cmd = ["cmd", "/C"] + cmd
        end

        @process = ChildProcess.build *cmd
        @process.environment.merge!(env)
        @process.io.inherit!
        @process.start
        @pid = @process.pid
      end

      def stop
        unless self.class.windows?
          process.stop
        else
          kill_all_child_processes
        end
      end

      def alive?
        pid && process.alive?
      end

      def running?
        return false unless alive?
        TCPSocket.new('localhost', port).close
        if self.class.windows?
          running_on_windows?
        else
          true
        end
      rescue Errno::ECONNREFUSED
        false
      end

      def command
        parts = []
        parts << "bundle exec" if use_bundler?
        parts << "foreman run" if use_foreman?
        parts << "spork"

        if type == :test_unit
          parts << "testunit"
        elsif type == :cucumber
          parts << "cu"
        elsif type == :minitest
          parts << "minitest"
        end

        parts << "-p #{port}"
        parts << "-q" if options[:quiet]
        parts.join(" ")
      end

      def self.windows?
        RUBY_PLATFORM =~ /mswin|msys|mingw/
      end

    private

      def use_bundler?
        options[:bundler]
      end

      def use_foreman?
        options[:foreman]
      end

      def kill_all_child_processes
        all_pids_for(pid).each do |pid|
          Process.kill 9, pid
        end
      end

      def all_pids_for(parent_pid)
        pids = [parent_pid]
        Sys::ProcTable.ps do |process|
          pids += all_pids_for(process.pid) if process.ppid == parent_pid
        end
        pids
      end

      def running_on_windows?
        DRb.start_service
        # make sure that ringfinger is not taken from cache, because it won't
        # work after guard-spork has been restarted
        Rinda::RingFinger.class_variable_set :@@finger, nil
        ts = Rinda::RingFinger.primary
        ts.read_all([:name, :MagazineSlave, nil, nil]).size > 0
      rescue DRb::DRbConnError
        false
      end

    end
  end
end
