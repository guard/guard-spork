require 'rinda/ring'
require 'guard/spork/rinda_ring_finger_patch'

module Guard
  class Spork
    class SporkWindowsInstance < SporkInstance
      def command
        ["cmd", "/C"] + super
      end

      def stop
        kill_all_spork_processes
      end

      def running?
        super && drb_ready?
      end

      def self.spork_pids
        spork_processes.map { |process| process[:pid] }
      end

      private 

      def drb_ready?
        DRb.start_service
        # make sure that ringfinger is not taken from cache, because it won't
        # work after guard-spork has been restarted
        Rinda::RingFinger.class_variable_set :@@finger, nil
        ts = Rinda::RingFinger.primary
        ts.read_all([:name, :MagazineSlave, nil, nil]).size > 0
      rescue
        false
      end

      def kill_all_spork_processes
        all_pids_for(pid, self.class.spork_processes).each do |pid|
          Process.kill 9, pid rescue nil
        end
      end

      def all_pids_for(parent_pid, processes)
        processes.inject([parent_pid]) do |memo, process|
          memo += all_pids_for(process[:pid], processes) if process[:ppid] == parent_pid
          memo
        end
      end

      def self.spork_processes
        require "win32ole"
        WIN32OLE.connect("winmgmts://.").InstancesOf("win32_process").
          each.
          select do |p| 
            p.commandline =~ /spork|ring_server|magazine_slave_provider/ && 
              File.basename(p.executablepath, File.extname(p.executablepath)) =~ /^(cmd|ruby)$/i
          end.
          map { |p| {:pid => p.processid, :ppid => p.parentprocessid} }
      end

    end
  end
end
