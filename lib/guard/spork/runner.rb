require 'socket'

module Guard
  class Spork
    class Runner
      attr_accessor :options

      def initialize(options={})
        options[:wait]           ||= 20 # seconds
        options[:test_unit_port] ||= 8988
        options[:rspec_port]     ||= 8989
        options[:cucumber_port]  ||= 8990
        options[:test_unit_env]  ||= {}
        options[:rspec_env]      ||= {}
        options[:cucumber_env]   ||= {}
        @options  = options
        @children = {}

        Signal.trap('CHLD', self.method(:reap_children))
      end

      def launch_sporks(action)
        UI.info "#{action.capitalize}ing Spork for #{sporked_gems} ", :reset => true
        spawn_child(options[:test_unit_env], spork_command("test_unit")) if test_unit?
        spawn_child(options[:rspec_env], spork_command("rspec")) if rspec?
        spawn_child(options[:cucumber_env], spork_command("cucumber")) if cucumber?
        verify_launches(action)
      end

      def kill_sporks
        UI.debug "Killing Spork servers with PID: #{spork_pids.join(', ')}"
        spork_pids.each { |pid| ::Process.kill("KILL", pid) }
      end

    private

      def spawn_child(env, cmd)
        pid = fork
        raise "Fork failed." if pid == -1

        unless pid
          ignore_control_signals
          if RUBY_VERSION > "1.9"
            exec(env, cmd)
          else
            swap_env(env) { exec(cmd) }
          end
        end

        UI.debug "Spawned Spork server #{pid} ('#{cmd}')"
        @children[pid] = cmd
        pid
      end

      def ignore_control_signals
        Signal.trap('QUIT', 'IGNORE')
        Signal.trap('INT', 'IGNORE')
        Signal.trap('TSTP', 'IGNORE')
      end

      def swap_env(env)
        old_env = {}
        env.each do |key, value|
          old_env[key] = ENV[key]
          ENV[key]     = value
        end

        yield

        env.each do |key, value|
          ENV[key] = old_env[key]
        end
      end

      def reap_children(sig)
        terminated_children.each do |stat|
          pid = stat.pid
          if cmd = @children.delete(pid)
            UI.debug "Reaping spork #{pid}"
          end
        end
      end

      def terminated_children
        stats = []
        loop do
          begin
            pid, stat = ::Process.wait2(-1, ::Process::WNOHANG)
            break if pid.nil?
            stats << stat
          rescue Errno::ECHILD
            break
          end
        end
        stats
      end

      def spork_command(type)
        cmd_parts = []
        cmd_parts << "bundle exec" if bundler?
        cmd_parts << "spork"

        case type
        when "test_unit"
          cmd_parts << "testunit -p #{options[:test_unit_port]}"
        when "rspec"
          cmd_parts << "-p #{options[:rspec_port]}"
        when "cucumber"
          cmd_parts << "cu -p #{options[:cucumber_port]}"
        end

        cmd_parts.join(" ")
      end

      def verify_launches(action)
        options[:wait].times do
          sleep 1
          begin
            TCPSocket.new('localhost', options[:test_unit_port]).close if test_unit?
            TCPSocket.new('localhost', options[:rspec_port]).close if rspec?
            TCPSocket.new('localhost', options[:cucumber_port]).close if cucumber?
          rescue Errno::ECONNREFUSED
            next
          end
          UI.info "Spork server for #{sporked_gems} successfully #{action}ed", :reset => true
          Notifier.notify "#{sporked_gems} successfully #{action}ed", :title => "Spork", :image => :success
          return true
        end
        UI.reset_line # workaround before Guard::UI update
        UI.error "Could not #{action} Spork server for #{sporked_gems}. Make sure you can use it manually first."
        Notifier.notify "#{sporked_gems} NOT #{action}ed", :title => "Spork", :image => :failed
      end

      def spork_pids
        @children.keys
      end

      def sporked_gems
        gems = []
        gems << "Test::Unit" if test_unit?
        gems << "RSpec" if rspec?
        gems << "Cucumber" if cucumber?
        gems.join(' & ')
      end

      def bundler?
        @bundler ||= File.exist?("#{Dir.pwd}/Gemfile") && options[:bundler] != false
      end

      def test_unit?
        @test_unit ||= File.exist?("#{Dir.pwd}/test/test_helper.rb") && options[:test_unit] != false
      end

      def rspec?
        @rspec ||= File.exist?("#{Dir.pwd}/spec") && options[:rspec] != false
      end

      def cucumber?
        @cucumber ||= File.exist?("#{Dir.pwd}/features") && options[:cucumber] != false
      end

    end
  end
end
