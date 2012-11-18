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

      def self.spork_processes_on_windows
        result = `wmic process where "commandline like '%spork%' or commandline like '%ring_server%' or commandline like '%magazine_slave_provider%'" get commandline,handle,parentprocessid` 
        lines = result.lines.map &:strip
        header = lines.shift
        column_sizes = header.scan(/\w+\s*/).map { |part| part.size }
        cmdline_position = 0..(column_sizes[0] - 1)
        pid_position = column_sizes[0]..(column_sizes[0] + column_sizes[1] - 1)
        ppid_position = (column_sizes[0] + column_sizes[1])..-1
        lines[1..-1].map do |line|
          cmdline, pid, ppid = line[cmdline_position], line[pid_position], line[ppid_position]
          {:cmdline => cmdline.strip, :pid => pid.to_i, :ppid => ppid.to_i} if pid
        end.compact
      end

    private

      def use_bundler?
        options[:bundler]
      end

      def use_foreman?
        options[:foreman]
      end

      def kill_all_child_processes
        all_pids_for(pid, self.class.spork_processes_on_windows).each do |pid|
          Process.kill 9, pid rescue nil
        end
      end

      def all_pids_for(parent_pid, processes)
        processes.inject([parent_pid]) do |memo, process|
          memo += all_pids_for(process[:pid], processes) if process[:ppid] == parent_pid
          memo
        end
      end

      def running_on_windows?
        DRb.start_service
        # make sure that ringfinger is not taken from cache, because it won't
        # work after guard-spork has been restarted
        Rinda::RingFinger.class_variable_set :@@finger, nil
        ts = Rinda::RingFinger.primary
        ts.read_all([:name, :MagazineSlave, nil, nil]).size > 0
      rescue
        false
      end

    end
  end
end
