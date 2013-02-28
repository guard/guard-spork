require 'socket'

module Guard
  class Spork
    class Runner
      attr_accessor :options
      attr_reader :spork_instances

      def initialize(options={})
        options[:wait]           ||= 30 # seconds
        options[:retry_delay]    ||= 2 * options[:wait] # seconds
        options[:test_unit_port] ||= 8988
        options[:cucumber_port]  ||= 8990
        options[:rspec_port]     ||= 8989
        options[:minitest_port]  ||= 8988
        options[:rspec_env]      ||= {}
        options[:test_unit_env]  ||= {}
        options[:cucumber_env]   ||= {}
        options[:minitest_env]   ||= {}
        options[:minitest]       ||= false
        options[:aggressive_kill]  = true unless options[:aggressive_kill] == false
        options[:foreman]        ||= false
        options[:quiet]          ||= false
        @options  = options
        initialize_spork_instances
      end

      def launch_sporks(action, type = nil)
        instances = find_instances(type)
        UI.info "#{action.capitalize}ing Spork for #{instances.join(', ')}", :reset => true
        if options[:notify_on_start]
          Notifier.notify "#{action.capitalize}ing #{instances.join(', ')}", :title => "Spork", :image => :success
        end
        instances.each(&:start)
        verify_launches(action, instances)
      end

      def kill_sporks(type = nil)
        alive = find_instances(type).select(&:alive?)
        UI.debug "Killing Spork servers with PID: #{alive.map(&:pid).join(', ')}"
        alive.each(&:stop)
      end

      def kill_global_sporks
        if options[:aggressive_kill]
          kill_pids self.class.spork_instance_class.spork_pids
        end
      end

      def self.windows?
        ENV['OS'] == 'Windows_NT'
      end

    private

      def initialize_spork_instances
        @spork_instances = []
        [:rspec, :cucumber, :test_unit, :minitest].each do |type|
          port, env = options[:"#{type}_port"], options[:"#{type}_env"]
          spork_instances << self.class.spork_instance_class.new(type, port, env, :bundler => should_use?(:bundler), :foreman => should_use?(:foreman), :quiet => should_use?(:quiet)) if should_use?(type)
        end
      end

      def self.spork_instance_class
        windows? ? SporkWindowsInstance : SporkInstance
      end

      def kill_pids(pids)
        UI.debug "Killing Spork servers with PID: #{pids.join(', ')}"
        pids.each { |pid| ::Process.kill("KILL", pid) rescue nil }
      end

      def find_instances(type = nil)
        if type.nil?
          spork_instances
        else
          spork_instances.select { |instance| instance.type == type }
        end
      end

      def verify_launches(action, instances)
        start_time = Time.now
        names = instances.join(', ')

        if wait_for_launch(instances, options[:wait])
          UI.info "Spork server for #{names} successfully #{action}ed", :reset => true
          Notifier.notify "#{names} successfully #{action}ed", :title => "Spork", :image => :success
        else
          UI.reset_line # workaround before Guard::UI update
          UI.error "Could not #{action} Spork server for #{names} after #{options[:wait]} seconds. I will continue waiting for a further #{options[:retry_delay]} seconds."
          Notifier.notify "#{names} NOT #{action}ed. Continuing to wait for #{options[:retry_delay]} seconds.", :title => "Spork", :image => :failed
          if wait_for_launch(instances, options[:retry_delay])
            total_time = Time.now - start_time
            UI.info "Spork server for #{names} eventually #{action}ed after #{total_time.to_i} seconds. Consider adjusting your :wait option beyond this time.", :reset => true
            Notifier.notify "#{names} eventually #{action}ed after #{total_time.to_i} seconds", :title => "Spork", :image => :success
          else
            UI.reset_line # workaround before Guard::UI update
            UI.error "Could not #{action} Spork server for #{names}. Make sure you can use it manually first."
            Notifier.notify "#{names} NOT #{action}ed", :title => "Spork", :image => :failed
            throw :task_has_failed
          end
        end
      end

      def wait_for_launch(instances, wait)
        not_running = instances.dup
        wait_or_loop(wait) do
          sleep 1
          not_running.delete_if { |instance| instance.running? }
          return true if not_running.empty?
        end
      end

      def should_use?(what)
        options[what].nil? ? send("detect_#{what}") : options[what]
      end

      def wait_or_loop(wait)
        if wait
          wait.times { yield }
        else
          loop { yield }
        end
        false
      end

      def detect_bundler
        File.exist?("Gemfile")
      end

      def detect_test_unit
        File.exist?("test/test_helper.rb")
      end

      def detect_rspec
        File.exist?("spec") && (options[:minitest].nil? || !options[:minitest])
      end

      def detect_minitest
        false
      end

      def detect_cucumber
        File.exist?("features")
      end

      def detect_foreman
        File.exist?("Procfile")
      end

    end
  end
end
