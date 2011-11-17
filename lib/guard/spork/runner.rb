require 'socket'

module Guard
  class Spork
    class Runner
      attr_accessor :options

      def initialize(options={})
        options[:wait]           ||= 30 # seconds
        options[:test_unit_port] ||= 8988
        options[:cucumber_port]  ||= 8990
        options[:rspec_port]     ||= 8989
        options[:rspec_env]      ||= {}
        options[:test_unit_env]  ||= {}
        options[:cucumber_env]   ||= {}
        options[:aggressive_kill]  = true unless options[:aggressive_kill] == false
        @options  = options
        ENV['SPORK_PIDS'] ||= ''
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
        spork_pids.each do |pid|
          ::Process.kill("KILL", pid)
          remove_children(pid)
        end
      end

    private

      def spawn_child(env, cmd)
        pid = fork
        raise "Fork failed." if pid == -1

        unless pid
          if RUBY_VERSION > "1.9"
            exec(env, cmd)
          else
            swap_env(env) { exec(cmd) }
          end
        end

        UI.debug "Spawned Spork server #{pid} ('#{cmd}')"
        add_children(pid)
        pid
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
        start_time = Time.now
        if wait_for_launch(options[:wait])
          UI.info "Spork server for #{sporked_gems} successfully #{action}ed", :reset => true
          Notifier.notify "#{sporked_gems} successfully #{action}ed", :title => "Spork", :image => :success          
        else
          UI.reset_line # workaround before Guard::UI update
          UI.error "Could not #{action} Spork server for #{sporked_gems} after #{options[:wait]} seconds. I will continue waiting for a further 60 seconds."
          Notifier.notify "#{sporked_gems} NOT #{action}ed. Continuing to wait for 60 seconds.", :title => "Spork", :image => :failed
          if wait_for_launch(60)
            total_time = Time.now - start_time
            UI.info "Spork server for #{sporked_gems} eventually #{action}ed after #{total_time.to_i} seconds. Consider adjusting your :wait option beyond this time.", :reset => true
            Notifier.notify "#{sporked_gems} eventually #{action}ed after #{total_time.to_i} seconds", :title => "Spork", :image => :success
          else 
            UI.reset_line # workaround before Guard::UI update
            UI.error "Could not #{action} Spork server for #{sporked_gems}. Make sure you can use it manually first."
            Notifier.notify "#{sporked_gems} NOT #{action}ed", :title => "Spork", :image => :failed
            throw :task_has_failed
          end
        end
      end
      
      def wait_for_launch(wait)
        wait.times do
          sleep 1
          begin
            TCPSocket.new('localhost', options[:test_unit_port]).close if test_unit?
            TCPSocket.new('localhost', options[:rspec_port]).close if rspec?
            TCPSocket.new('localhost', options[:cucumber_port]).close if cucumber?
          rescue Errno::ECONNREFUSED
            next
          end
          return true # Success
        end
        return false # Failure
      end

      def add_children(pid)
        pids              = spork_pids << pid
        ENV['SPORK_PIDS'] = pids.join(',')
      end

      def remove_children(pid)
        pids              = spork_pids
        deleted_pid       = pids.delete(pid)
        ENV['SPORK_PIDS'] = pids.join(',')
        deleted_pid
      end

      def spork_pids
        if ENV['SPORK_PIDS'] == '' && options[:aggressive_kill]
          ps_spork_pids
        else
          ENV['SPORK_PIDS'].split(',').map { |pid| pid.to_i }
        end
      end

      def ps_spork_pids
        `ps aux | awk '/spork/&&!/awk/{print $2;}'`.split("\n").map { |pid| pid.to_i }
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
