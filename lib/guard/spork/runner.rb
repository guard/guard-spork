require 'socket'

module Guard
  class Spork
    class Runner
      attr_accessor :options

      def initialize(options = {})
        options[:wait]          ||= 20 # seconds
        options[:rspec_port]    ||= 8989
        options[:cucumber_port] ||= 8990
        @options = options
        @children = {}

        Signal.trap('CHLD', self.method(:reap_children))
      end

      def launch_sporks(action)
        UI.info "#{action.capitalize}ing Spork for #{sporked_gems} ", :reset => true
        spawn_child(spork_command("rspec")) if rspec?
        spawn_child(spork_command("cucumber")) if cucumber?
        verify_launches(action)
      end

      def kill_sporks
        UI.debug "Killing sporks #{spork_pids.join(', ')}"
        spork_pids.each { |pid| Process.kill("KILL", pid) }
      end

    private
      def spawn_child(cmd)
        pid = fork
        raise "Fork failed." if pid == -1

        unless pid
          ignore_control_signals
          exec(cmd)
        end

        UI.debug "Spawned spork #{pid} ('#{cmd}')"
        @children[pid] = cmd
        pid
      end

      def ignore_control_signals
        Signal.trap('QUIT', 'IGNORE')
        Signal.trap('INT', 'IGNORE')
        Signal.trap('TSTP', 'IGNORE')
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
            pid, stat = Process.wait2(-1, Process::WNOHANG)
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
        when "rspec"
          cmd_parts << "-p #{options[:rspec_port]}"
        when "cucumber"
          cmd_parts << "cu"
          cmd_parts << "-p #{options[:cucumber_port]}"
        end

        cmd_parts.join(" ")
      end

      def verify_launches(action)
        options[:wait].times do
          sleep 1
          begin
            TCPSocket.new('localhost', options[:rspec_port]).close if rspec?
            TCPSocket.new('localhost', options[:cucumber_port]).close if cucumber?
          rescue Errno::ECONNREFUSED
            next
          end
          UI.info "Spork for #{sporked_gems} successfully #{action}ed", :reset => true
          Notifier.notify "#{sporked_gems} successfully #{action}ed", :title => "Spork", :image => :success
          return true
        end
        UI.reset_line # workaround before Guard::UI update
        UI.error "Could not #{action} Spork for #{sporked_gems}. Make sure you can use it manually first."
        Notifier.notify "#{sporked_gems} NOT #{action}ed", :title => "Spork", :image => :failed
      end

      def spork_pids
        @children.keys
      end

      def sporked_gems
        gems = []
        gems << "RSpec" if rspec?
        gems << "Cucumber" if cucumber?
        gems.join(' & ')
      end

      def bundler?
        @bundler ||= File.exist?("#{Dir.pwd}/Gemfile") && options[:bundler] != false
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
