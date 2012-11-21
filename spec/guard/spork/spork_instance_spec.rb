require 'spec_helper'

class Guard::Spork
  describe SporkInstance do
    it "remembers instances" do
      instance = SporkInstance.new('type', 0, {}, {})
    end

    describe "rspec on port 1337" do
      let(:options) { Hash.new }
      subject { SporkInstance.new(:rspec, 1337, {}, options) }

      its(:command) { should == "spork -p 1337" }
      its(:port) { should == 1337 }
      its(:type) { should == :rspec }
      its(:to_s) { should == "RSpec" }

      context "with bundler enabled" do
        let(:options) { {:bundler => true} }

        its(:command) { should == "bundle exec spork -p 1337" }
      end

      context "with foreman enabled" do
        let(:options) { { :foreman => true, :bundler => true } }

        its(:command) { should == "bundle exec foreman run spork -p 1337"}
      end
      
      context "with quiet enabled" do
        let(:options) { { :quiet => true } }

        its(:command) { should == "spork -p 1337 -q"}
      end      
    end

    describe "cucumber on port 1337" do
      let(:options) { Hash.new }
      subject { SporkInstance.new(:cucumber, 1337, {}, options) }

      its(:command) { should == "spork cu -p 1337" }
      its(:port) { should == 1337 }
      its(:type) { should == :cucumber }
      its(:to_s) { should == "Cucumber" }

      context "with bundler enabled" do
        let(:options) { {:bundler => true} }

        its(:command) { should == "bundle exec spork cu -p 1337" }
      end

      context "with foreman enabled" do
        let(:options) { { :foreman => true, :bundler => true } }

        its(:command) { should == "bundle exec foreman run spork cu -p 1337"}
      end
    end

    describe "test_unit on port 1337" do
      let(:options) { Hash.new }
      subject { SporkInstance.new(:test_unit, 1337, {}, options) }

      its(:command) { should == "spork testunit -p 1337" }
      its(:port) { should == 1337 }
      its(:type) { should == :test_unit }
      its(:to_s) { should == "Test::Unit" }

      context "with bundler enabled" do
        let(:options) { {:bundler => true} }

        its(:command) { should == "bundle exec spork testunit -p 1337" }
      end

      context "with foreman enabled" do
        let(:options) { { :foreman => true, :bundler => true } }

        its(:command) { should == "bundle exec foreman run spork testunit -p 1337"}
      end
    end

    describe "minitest on port 1338" do
      let(:options) { Hash.new }
      subject { SporkInstance.new(:minitest, 1338, {}, options) }

      its(:command) { should == "spork minitest -p 1338" }
      its(:port) { should == 1338 }
      its(:type) { should == :minitest }
      its(:to_s) { should == "MiniTest" }

      context "with bundler enabled" do
        let(:options) { {:bundler => true} }

        its(:command) { should == "bundle exec spork minitest -p 1338" }
      end

      context "with foreman enabled" do
        let(:options) { { :foreman => true, :bundler => true } }

        its(:command) { should == "bundle exec foreman run spork minitest -p 1338"}
      end
    end

  end

  describe SporkInstance, "spawning" do
    let(:instance) { SporkInstance.new(:test, 1, {}, {}) }
    before(:each) do
      instance.stub(:command => "")
    end

    describe "#start" do
      after(:each) { ENV.delete('SPORK_PIDS') }

      it "uses ChildProcess and stores the pid" do
        process = double("process").as_null_object
        ChildProcess.should_receive(:build).and_return(process)
        process.stub(:pid => "a pid")
        expect {
          instance.start
        }.to change(instance, :pid).from(nil).to("a pid")
      end

      it "passes environment to the ChildProcess" do
        instance.stub(:command => "command", :env => {:environment => true})
        process = double("process").as_null_object
        ChildProcess.should_receive(:build).and_return(process)
        process_env = {}
        process.should_receive(:environment).and_return(process_env)
        process_env.should_receive(:merge!).with(:environment => true)
        instance.start
      end
    end

    describe "#stop" do
      it "delegates to ChildProcess#stop" do
        process = double("a process")
        instance.stub(:process).and_return(process)
        process.should_receive(:stop)
        instance.stop
      end
    end

    describe "(alive)" do
      subject { instance }
      before(:each) do
        instance.stub(:pid => nil)
      end

      context "when no pid is set" do
        it { should_not be_alive }
      end

      context "when the pid is a running process" do
        before(:each) do
          instance.stub(:pid => 42)
          process = double("a process")
          instance.stub(:process => process)
          process.stub(:alive? => true)
        end

        it { should be_alive }
      end

      context "when the pid is a stopped process" do
        subject { instance }
        before(:each) do
          instance.stub(:pid => 42)
          process = double("a process")
          instance.stub(:process => process)
          process.stub(:alive? => false)
        end

        it { should_not be_alive }
      end
    end

    describe "(running)" do
      let(:socket) { double(:close => nil) }
      subject { instance }

      before(:each) do
        instance.stub(:pid => 42, :port => 1337)
        TCPSocket.stub(:new => socket)
      end

      context "when no pid is specified" do
        before(:each) { instance.stub(:pid => nil) }
        it { should_not be_running }
      end

      context "when process is not alive" do
        before(:each) { instance.stub(:alive? => false)}
        it { should_not be_running }
      end

      context "when spork does not respond" do
        before(:each) do
          TCPSocket.should_receive(:new).with('localhost', 1337).and_raise(Errno::ECONNREFUSED)
          instance.stub(:alive? => true)
        end

        it { should_not be_running }
      end

      context "when spork accepts the connection" do
        before(:each) do
          TCPSocket.should_receive(:new).with('localhost', 1337).and_return(socket)
          instance.stub(:alive? => true)
        end

        it { should be_running }
      end
    end

    describe ".spork_pids" do
      it "returns all the pids belonging to spork" do
        instance.class.stub(:`).and_return { |command| raise "Unexpected command: #{command}" }
        instance.class.should_receive(:`).
          with(%q[ps aux | awk '/spork/&&!/awk/{print $2;}']).
          and_return("666\n999")

        instance.class.spork_pids.should == [666, 999]
      end
    end

  end
end
