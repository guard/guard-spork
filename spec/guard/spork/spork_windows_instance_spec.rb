require 'spec_helper'

class Guard::Spork
  describe SporkWindowsInstance do
    describe "#command adds 'cmd /C' as command prefix" do
      let(:options) { Hash.new }
      subject { SporkWindowsInstance.new(:rspec, 1337, {}, options) }

      describe '#command' do
        subject { super().command }
        it { is_expected.to eq(%w{cmd /C spork -p 1337}) }
      end 
    end
  end

  describe SporkWindowsInstance, "spawning" do
    let(:instance) { SporkWindowsInstance.new(:test, 1, {}, {}) }

    describe "#stop" do
      it "kills all child processes manually on Windows" do 
        expect(instance).to receive(:pid).and_return("a pid")
        processes = [{:pid => 22, :ppid => "a pid"}, {:pid => 66, :ppid => 99}, {:pid => 33, :ppid => 22}, {:pid => 44, :ppid => 33}]
        allow(instance.class).to receive_messages(:spork_processes => processes)
        expect(Process).to receive(:kill).with(9, "a pid")
        expect(Process).to receive(:kill).with(9, 22)
        expect(Process).to receive(:kill).with(9, 33)
        expect(Process).to receive(:kill).with(9, 44)
        expect(Process).not_to receive(:kill).with(9, 66)

        instance.stop
      end
    end

    describe "(running)" do
      let(:socket) { double(:close => nil) }
      subject { instance }

      before(:each) do
        allow(instance).to receive_messages(:pid => 42, :port => 1337)
        allow(TCPSocket).to receive_messages(:new => socket)
      end

      context "when spork accepts the connection and DRb is not ready" do
        before(:each) do
          expect(TCPSocket).to receive(:new).with('127.0.0.1', 1337).and_return(socket)
          allow(instance).to receive_messages(:alive? => true)
          allow(instance).to receive_messages(:drb_ready? => false)
        end

        it { is_expected.not_to be_running }
      end

      context "when spork accepts the connection and DRb is ready" do
        before(:each) do
          expect(TCPSocket).to receive(:new).with('127.0.0.1', 1337).and_return(socket)
          allow(instance).to receive_messages(:alive? => true)
          allow(instance).to receive_messages(:drb_ready? => true)
        end

        it { is_expected.to be_running }
      end
    end

    describe ".spork_pids" do
      it "returns all the pids belonging to sporks", :if => Guard::Spork::Runner.windows? do
        require "win32ole"

        instances = double('instances')
        expect(WIN32OLE).to receive(:connect).
          with("winmgmts://.").and_return(instances)

        MockProcess = Struct.new :processid, :parentprocessid, :executablepath, :commandline
        spork = MockProcess.new 1, 10, "c:\\foo\\bar\\ruby.exe", "ruby.exe bin\\spork"
        spork_cmd = MockProcess.new 2, 1, "c:\\windows\\cmd.exe", "cmd.exe spork.bat"
        ring_server = MockProcess.new 3, 2, "c:\\foo\\bar\\ruby.exe", "ruby.exe bar\\ring_server.rb"
        slave_provider = MockProcess.new 4, 1, "c:\\foo\\bar\\ruby.exe", "ruby.exe bar\\magazine_slave_provider.rb"
        foo = MockProcess.new 5, 1, "c:\\foo\\bar\\foobar.exe", "foobar.exe ignored"
        expect(instances).to receive(:InstancesOf).with("win32_process").
          and_return([spork, spork_cmd, ring_server, slave_provider, foo])

        expect(instance.class.spork_pids).to eq([1, 2, 3, 4])
      end
    end
  end
end
