require 'socket'

module Guard
  class Spork
    class Runner
      attr_accessor :options
      attr_reader :spork_instances

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
        initialize_spork_instances
      end

      def launch_sporks(action)
        UI.info "#{action.capitalize}ing Spork for #{spork_names}", :reset => true
        spork_instances.values.each(&:start)
        verify_launches(action)
      end

      def kill_sporks
        alive = spork_instances.select(&:alive?)
        UI.debug "Killing Spork servers with PID: #{alive.map(&:pid).join(', ')}"
        alive.each(&:kill)
      end

      def kill_global_sporks
        if options[:aggressive_kill]
          kill_global_sporks!
        end
      end

      def kill_global_sporks!
        pids = ps_spork_pids
        UI.debug "Killing Spork servers with PID: #{pids.join(', ')}"
        pids.each { |pid| Process.kill("KILL", pid) }
      end

    private
      def initialize_spork_instances
        @spork_instances = {}
        [:rspec, :cucumber, :test_unit].each do |type|
          port, env = options[:"#{type}_port"], options[:"#{type}_env"]
          spork_instances[type] = SporkInstance.new(type, port, env, :bundler => should_use?(:bundler)) if should_use?(type)
        end
      end

      def verify_launches(action)
        start_time = Time.now
        if wait_for_launch(options[:wait])
          UI.info "Spork server for #{spork_names} successfully #{action}ed", :reset => true
          Notifier.notify "#{spork_names} successfully #{action}ed", :title => "Spork", :image => :success
        else
          UI.reset_line # workaround before Guard::UI update
          UI.error "Could not #{action} Spork server for #{spork_names} after #{options[:wait]} seconds. I will continue waiting for a further 60 seconds."
          Notifier.notify "#{spork_names} NOT #{action}ed. Continuing to wait for 60 seconds.", :title => "Spork", :image => :failed
          if wait_for_launch(60)
            total_time = Time.now - start_time
            UI.info "Spork server for #{spork_names} eventually #{action}ed after #{total_time.to_i} seconds. Consider adjusting your :wait option beyond this time.", :reset => true
            Notifier.notify "#{spork_names} eventually #{action}ed after #{total_time.to_i} seconds", :title => "Spork", :image => :success
          else
            UI.reset_line # workaround before Guard::UI update
            UI.error "Could not #{action} Spork server for #{spork_names}. Make sure you can use it manually first."
            Notifier.notify "#{spork_names} NOT #{action}ed", :title => "Spork", :image => :failed
            throw :task_has_failed
          end
        end
      end

      def wait_for_launch(wait)
        not_running = spork_instances.values.dup
        wait.times do
          sleep 1
          not_running.delete_if { |instance| instance.running? }
          return true if not_running.empty?
        end
        false
      end

      def ps_spork_pids
        `ps aux | awk '/spork/&&!/awk/{print $2;}'`.split("\n").map { |pid| pid.to_i }
      end

      def spork_names
        spork_instances.keys.map(&:to_s).sort.join(', ')
      end

      def should_use?(what)
        if options[what].nil?
          send("detect_#{what}")
        else
          options[what]
        end
      end

      def detect_bundler
        File.exist?("Gemfile")
      end

      def detect_test_unit
        File.exist?("test/test_helper.rb")
      end

      def detect_rspec
        File.exist?("spec")
      end

      def detect_cucumber
        File.exist?("features")
      end
    end
  end
end
