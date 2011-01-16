require 'socket'

module Guard
  class Spork
    class Runner
      attr_accessor :options

      def initialize(options = {})
        options[:wait]          ||= 20 # seconds
        options[:rspec_port]    ||= 8989
        options[:cucumber_port] ||= 8990
        options[:test_unit_port] ||= 8988
        @options = options
      end
      
      def launch_sporks(action)
        UI.info "#{action.capitalize}ing Spork for #{sporked_gems} ", :reset => true
        system(spork_command("rspec")) if rspec?
        system(spork_command("cucumber")) if cucumber?
        system(spork_command("test_unit")) if test_unit?
        verify_launches(action)
      end
      
      def kill_sporks
        spork_pids.each { |pid| Process.kill("KILL", pid) }
      end
      
    private
      
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
        when 'test_unit'
          cmd_parts << "-p #{options[:test_unit_port]}"
        end
        
        cmd_parts << ">/dev/null 2>&1 < /dev/null &"
        cmd_parts.join(" ")
      end
      
      def verify_launches(action)
        options[:wait].times do
          sleep 1
          begin
            TCPSocket.new('localhost', options[:rspec_port]).close if rspec?
            TCPSocket.new('localhost', options[:cucumber_port]).close if cucumber?
            TCPSocket.new('localhost', options[:test_unit_port]).close if test_unit?
          rescue Errno::ECONNREFUSED
            print '.'
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
        `ps aux | awk '/spork/&&!/awk/{print $2;}'`.split("\n").map { |pid| pid.to_i }
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

      def test_unit?
        @test_unit ||= File.exist?("#{Dir.pwd}/test")
      end
      
    end
  end
end
