require 'socket'

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
        executable, *cmd = command

        Compat::UI.debug "guard-spork command execution: #{cmd}"

        @process = ChildProcess.build(executable, *cmd)
        @process.environment.merge!(env) unless env.empty?
        @process.io.inherit!
        @process.start
        @pid = @process.pid
      end

      def stop
        process.stop
      end

      def alive?
        pid && process.alive?
      end

      def running?
        return false unless alive?
        TCPSocket.new('127.0.0.1', port).close
        true
      rescue Errno::ECONNREFUSED
        false
      end

      def command
        parts = []
        if use_bundler?
          parts << "bundle"
          parts << "exec"
        end
        if use_foreman?
          parts << "foreman"
          parts << "run"
        end
        parts << "spork"

        if type == :test_unit
          parts << "testunit"
        elsif type == :cucumber
          parts << "cu"
        elsif type == :minitest
          parts << "minitest"
        end

        parts << "-p"
        parts <<  port.to_s
        parts << "-q" if options[:quiet]

        if use_foreman?
          parts << "-e=#{options[:foreman].fetch(:env, '.env')}" if foreman_options?
        end

        parts
      end

      def self.spork_pids
        `ps aux | grep -v guard | awk '/spork/&&!/awk/{print $2;}'`.split("\n").map { |pid| pid.to_i }
      end

    private

      def use_bundler?
        options[:bundler]
      end

      def use_foreman?
        options[:foreman]
      end

      def foreman_options?
        options[:foreman].is_a?(Hash)
      end

    end
  end
end
