module Guard
  class Spork
    class SporkInstance
      attr_reader :type, :env, :port, :options, :pid

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
        else
          type.to_s
        end
      end

      def start
        @pid = fork do
          exec env, command
        end
        store_pid
      end

      def stop
        Process.kill('KILL', pid)
      end

      def alive?
        return false unless pid
        Process.waitpid(pid, Process::WNOHANG).nil?
      end

      def running?
        return false unless pid
        TCPSocket.new('localhost', port).close
        true
      rescue Errno::ECONNREFUSED
        false
      end

      def command
        parts = []
        parts << "bundle exec" if use_bundler?
        parts << "spork"

        if type == :test_unit
          parts << "testunit"
        elsif type == :cucumber
          parts << "cu"
        end

        parts << "-p #{port}"
        parts.join(" ")
      end

      def env_exec(environment, command)
        if RUBY_VERSION > "1.9"
          exec environment, command
        else
          environment.each_pair { |key, value| ENV[key] = value }
          exec command
        end
      end

      private
        def use_bundler?
          options[:bundler]
        end

        def store_pid
          # We need to store away the PIDs somewhere safe since
          # Guard will destroy our class instances when Guardfile is
          # reevaluated without telling us beforehand
          ENV['SPORK_PIDS'] = [ENV['SPORK_PIDS'], pid.to_s].compact.join(",")
        end
    end
  end
end
