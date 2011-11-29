require 'spec_helper'

class Guard::Spork
  describe SporkInstance do
    let(:env) { Hash.new }

    describe "rspec on port 1337" do
      let(:options) { Hash.new }
      subject { SporkInstance.new(:rspec, 1337, env, options) }

      its(:command) { should == "spork -p 1337" }
      its(:port) { should == 1337 }

      context "with bundler enabled" do
        let(:options) { {:bundler => true} }

        its(:command) { should == "bundle exec spork -p 1337" }
      end
    end

    describe "cucumber on port 1337" do
      let(:options) { Hash.new }
      subject { SporkInstance.new(:cucumber, 1337, env, options) }

      its(:command) { should == "spork cu -p 1337" }
      its(:port) { should == 1337 }

      context "with bundler enabled" do
        let(:options) { {:bundler => true} }

        its(:command) { should == "bundle exec spork cu -p 1337" }
      end
    end

    describe "test_unit on port 1337" do
      let(:options) { Hash.new }
      subject { SporkInstance.new(:test_unit, 1337, env, options) }

      its(:command) { should == "spork testunit -p 1337" }
      its(:port) { should == 1337 }

      context "with bundler enabled" do
        let(:options) { {:bundler => true} }

        its(:command) { should == "bundle exec spork testunit -p 1337" }
      end
    end
  end

  describe SporkInstance, "spawning" do
    let(:instance) { SporkInstance.new(:test, 1, {}, {}) }
    before(:each) do
      instance.stub(:command => "", :exec => nil, :fork => nil)
    end

    describe "#env_exec(env, command)" do
      # This behaves differently under Ruby 1.9 and 1.8
      # Make sure to run the suite under both environments
      if RUBY_VERSION > "1.9"
        it "delegates to native #exec" do
          instance.should_receive(:exec).with("env", "command")
          instance.env_exec("env", "command")
        end
      else
        around(:each) do |example|
          ENV['FOO'] = 'original foo'
          ENV['BAR'] = 'original bar'
          example.run
          ENV.delete('FOO')
          ENV.delete('BAR')
        end

        it "replaces the current process with the command under given environment" do
          instance.should_receive(:exec).with("command").and_return {
            ENV['FOO'].should == 'new foo'
            ENV['BAR'].should == 'original bar'
          }
          instance.env_exec({'FOO' => 'new foo'}, "command")
        end
      end
    end

    describe "#start" do
      it "forks and stores the pid" do
        instance.should_receive(:fork).and_return("a pid")
        expect {
          instance.start
        }.to change(instance, :pid).from(nil).to("a pid")
      end

      it "execs the command with the env in the fork" do
        instance.stub(:command => "command", :env => "environment")
        instance.should_receive(:fork).and_yield
        instance.should_receive(:exec).with("environment", "command")
        instance.start
      end
    end

    describe "#stop" do
      it "kills the pid" do
        instance.stub(:pid => 42)
        Process.should_receive(:kill).with('KILL', 42)
        instance.stop
      end
    end

    describe "(alive)" do
      subject { instance }
      before(:each) do
        instance.stub(:pid => nil)
        Process.stub(:waitpid => nil)
      end

      context "when no pid is set" do
        it { should_not be_alive }
      end

      context "when the pid is a running process" do
        before(:each) do
          instance.stub(:pid => 42)
          Process.should_receive(:waitpid).with(42, Process::WNOHANG).and_return(nil)
        end

        it { should be_alive }
      end

      context "when the pid is a stopped process" do
        subject { instance }
        before(:each) do
          instance.stub(:pid => 42)
          Process.should_receive(:waitpid).with(42, Process::WNOHANG).and_return(42)
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

      context "when spork does not respond" do
        before(:each) { TCPSocket.should_receive(:new).with('localhost', 1337).and_raise(Errno::ECONNREFUSED) }
        it { should_not be_running }
      end

      context "when spork accepts the connection" do
        before(:each) { TCPSocket.should_receive(:new).with('localhost', 1337).and_return(socket) }
        it { should be_running }
      end
    end
  end
end
