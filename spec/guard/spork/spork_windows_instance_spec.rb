require 'spec_helper'

class Guard::Spork
  describe SporkWindowsInstance do
    describe "#command adds 'cmd /C' as command prefix" do
      let(:options) { Hash.new }
      subject { SporkWindowsInstance.new(:rspec, 1337, {}, options) }

      its(:command) { should == ["cmd", "/C", "spork -p 1337"] }
    end
  end

  describe SporkWindowsInstance, "spawning" do
    let(:instance) { SporkWindowsInstance.new(:test, 1, {}, {}) }

    describe "#stop" do
      it "kills all child processes manually on Windows" do 
        instance.should_receive(:pid).and_return("a pid")
        processes = [{:pid => 22, :ppid => "a pid"}, {:pid => 66, :ppid => 99}, {:pid => 33, :ppid => 22}, {:pid => 44, :ppid => 33}]
        instance.class.stub(:spork_processes => processes)
        Process.should_receive(:kill).with(9, "a pid")
        Process.should_receive(:kill).with(9, 22)
        Process.should_receive(:kill).with(9, 33)
        Process.should_receive(:kill).with(9, 44)
        Process.should_not_receive(:kill).with(9, 66)

        instance.stop
      end
    end

    describe "(running)" do
      let(:socket) { double(:close => nil) }
      subject { instance }

      before(:each) do
        instance.stub(:pid => 42, :port => 1337)
        TCPSocket.stub(:new => socket)
      end

      context "when spork accepts the connection and DRb is not ready" do
        before(:each) do
          TCPSocket.should_receive(:new).with('localhost', 1337).and_return(socket)
          instance.stub(:alive? => true)
          instance.stub(:drb_ready? => false)
        end

        it { should_not be_running }
      end

      context "when spork accepts the connection and DRb is ready" do
        before(:each) do
          TCPSocket.should_receive(:new).with('localhost', 1337).and_return(socket)
          instance.stub(:alive? => true)
          instance.stub(:drb_ready? => true)
        end

        it { should be_running }
      end
    end

    describe ".spork_pids" do
      it "returns all the pids belonging to sporks" do
        instance.class.stub(:`).and_return { |command| raise "Unexpected command: #{command}" }
        instance.class.should_receive(:`).
          with(%q[wmic process where "commandline like '%spork%' or commandline like '%ring_server%' or commandline like '%magazine_slave_provider%'" get handle,parentprocessid]).
          and_return("666 777\n\n999 1010")

        instance.class.spork_pids.should == [666, 999]
      end
    end
  end
end
