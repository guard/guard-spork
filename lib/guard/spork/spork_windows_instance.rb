require 'rinda/ring'
require 'guard/spork/rinda_ring_finger_patch'

module Guard
  class Spork
    class SporkWindowsInstance < SporkInstance
      def command
        ["cmd", "/C"] << super
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
        result = `wmic process where "commandline like '%spork%' or commandline like '%ring_server%' or commandline like '%magazine_slave_provider%'" get handle,parentprocessid` 
        result.lines.map do |line|
          pid, ppid = line.strip.scan(/(\d+)\s+(\d+)$/).flatten
          {:pid => pid.to_i, :ppid => ppid.to_i} if pid
        end.compact
      end

    end
  end
end
