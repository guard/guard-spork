require 'spec_helper'
require 'timeout'

describe Guard::Spork::Runner do
  let(:runner) { Guard::Spork::Runner.new }

  describe "default options" do
    subject { Guard::Spork::Runner.new.options }

    it { should include(:wait => 30) }
    it { should include(:cucumber_port => 8990) }
    it { should include(:rspec_port => 8989) }
    it { should include(:test_unit_port => 8988) }
    it { should include(:test_unit_env => {}) }
    it { should include(:rspec_env => {}) }
    it { should include(:cucumber_env => {}) }
    it { should include(:aggressive_kill => true) }
  end

  before(:each) do
    Guard::Notifier.stub(:notify)
    Guard::Spork::SporkInstance.any_instance.stub(:start)
    Guard::UI.stub(:info)
    Guard::UI.stub(:error)
    Guard::UI.stub(:reset_line)
  end

  describe "(spork detection)" do
    def file_existance(files)
      File.stub(:exist?).and_raise { |name| "Unexpected file passed: #{name}" }
      files.each_pair do |file, existance|
        File.stub(:exist?).with(file).and_return(existance)
      end
    end

    it "has a spork instance for :rspec when configured" do
      runner = Guard::Spork::Runner.new({
        :rspec => true,
        :rspec_port => 2,
        :rspec_env  => {'spec' => 'yes'},
      })

      runner.spork_instances[:rspec].tap do |instance|
        instance.port.should == 2
        instance.env.should == {'spec' => 'yes'}
      end
    end

    it "has a spork instance for :cucumber when configured" do
      runner = Guard::Spork::Runner.new({
        :cucumber => true,
        :cucumber_port => 2,
        :cucumber_env  => {'cuke' => 'yes'},
      })

      runner.spork_instances[:cucumber].tap do |instance|
        instance.port.should == 2
        instance.env.should == {'cuke' => 'yes'}
      end
    end

    it "has a spork instance for :test_unit when configured" do
      runner = Guard::Spork::Runner.new({
        :test_unit => true,
        :test_unit_port => 2,
        :test_unit_env  => {'unit' => 'yes'},
      })

      runner.spork_instances[:test_unit].tap do |instance|
        instance.port.should == 2
        instance.env.should == {'unit' => 'yes'}
      end
    end

    context "with Test::Unit only" do
      before(:each) do
        file_existance({
          'test/test_helper.rb' => true,
          'spec'                => false,
          'features'            => false,
          'Gemfile'             => false,
        })
      end

      it "has a spork instance for :test_unit" do
        runner.spork_instances[:test_unit].should be_instance_of(Guard::Spork::SporkInstance)
      end

      it "does not have bundler enabled for the test_unit instance" do
        runner.spork_instances[:test_unit].options.should include(:bundler => false)
      end

      it "does not have a spork instance for :rspec" do
        runner.spork_instances[:rspec].should be_nil
      end

      it "does not have a spork instance for :cucumber" do
        runner.spork_instances[:cucumber].should be_nil
      end
    end

    context "with RSpec only" do
      before(:each) do
        file_existance({
          'test/test_helper.rb' => false,
          'spec'                => true,
          'features'            => false,
          'Gemfile'             => false,
        })
      end

      it "has a spork instance for :rspec" do
        runner.spork_instances[:rspec].should be_instance_of(Guard::Spork::SporkInstance)
      end

      it "does not have bundler enabled for the rspec instance" do
        runner.spork_instances[:rspec].options.should include(:bundler => false)
      end

      it "does not have a spork instance for :test_unit" do
        runner.spork_instances[:test_unit].should be_nil
      end

      it "does not have a spork instance for :cucumber" do
        runner.spork_instances[:cucumber].should be_nil
      end
    end

    context "with Cucumber only" do
      before(:each) do
        file_existance({
          'test/test_helper.rb' => false,
          'spec'                => false,
          'features'            => true,
          'Gemfile'             => false,
        })
      end

      it "has a spork instance for :cucumber" do
        runner.spork_instances[:cucumber].should be_instance_of(Guard::Spork::SporkInstance)
      end

      it "does not have bundler enabled for the cucumber instance" do
        runner.spork_instances[:cucumber].options.should include(:bundler => false)
      end

      it "does not have a spork instance for :test_unit" do
        runner.spork_instances[:test_unit].should be_nil
      end

      it "does not have a spork instance for :rspec" do
        runner.spork_instances[:rspec].should be_nil
      end
    end

    context "with RSpec, Cucumber and Bundler" do
      before(:each) do
        file_existance({
          'test/test_helper.rb' => false,
          'spec'                => true,
          'features'            => true,
          'Gemfile'             => true,
        })
      end

      it "has a spork instance for :rspec" do
        runner.spork_instances[:rspec].should be_instance_of(Guard::Spork::SporkInstance)
      end

      it "has a spork instance for :cucumber" do
        runner.spork_instances[:cucumber].should be_instance_of(Guard::Spork::SporkInstance)
      end

      it "has bundler enabled for the rspec instance" do
        runner.spork_instances[:rspec].options.should include(:bundler => true)
      end

      it "has bundler enabled for the cucumber instance" do
        runner.spork_instances[:cucumber].options.should include(:bundler => true)
      end

      it "does not have a spork instance for :test_unit" do
        runner.spork_instances[:test_unit].should be_nil
      end
    end
  end

  describe "#launch_sporks(action, type)" do
    let(:rspec_instance) { fake_instance(:rspec) }
    let(:cucumber_instance) { fake_instance(:cucumber) }

    def fake_instance(type)
      double("fake instance", :start => nil, :running? => true, :type => type).tap do |mock|
        def mock.to_s() type.to_s end
        # This one is needed to get this to work in 1.8.7
        # The effect only shows up during tests; Array#join uses #to_s in both
        # 1.8.7 and 1.9.2
        # It's probably something related to RSpec
        def mock.inspect() type.to_s end
      end
    end

    around(:each) do |example|
      Timeout.timeout(2) { example.run }
    end

    before(:each) do
      runner.stub(:spork_instances => {:rspec => rspec_instance, :cucumber => cucumber_instance})
      runner.stub(:sleep)
    end

    context "with no type specified" do
      it "outputs an info message" do
        runner.stub(:spork_instances => {
          "a" => fake_instance("one"),
          "b" => fake_instance("two"),
          "c" => fake_instance("three")
        })
        Guard::UI.should_receive(:info).with("Kissing Spork for one, two, three", :reset => true)
        runner.launch_sporks("kiss")
      end

      it "starts all spork instances" do
        rspec_instance.should_receive(:start)
        cucumber_instance.should_receive(:start)
        runner.launch_sporks("")
      end

      it "waits for the spork instances to start" do
        rspec_instance.should_receive(:running?).and_return(false, false, false, true)
        cucumber_instance.stub(:running? => true)
        runner.should_receive(:sleep).with(1).exactly(4).times

        runner.launch_sporks("")
      end

      # This behavior is a bit weird, isn't it?
      it "does not wait longer than the configured wait duration + 60" do
        runner.options[:wait] = 7
        runner.should_receive(:sleep).with(1).exactly(67).times
        rspec_instance.stub(:running? => false)
        cucumber_instance.stub(:running? => true)

        expect {
          runner.launch_sporks("")
        }.to throw_symbol(:task_has_failed)
      end
    end

    context "with a type specified" do
      it "outputs an info message" do
        runner.stub(:spork_instances => {
          "a" => fake_instance("one"),
          "b" => fake_instance("two"),
          "c" => fake_instance("three")
        })
        Guard::UI.should_receive(:info).with("Kissing Spork for two", :reset => true)
        runner.launch_sporks("kiss", "b")
      end

      it "starts the matching spork instance" do
        rspec_instance.should_receive(:start)
        cucumber_instance.should_not_receive(:start)
        runner.launch_sporks("", :rspec)
      end

      it "waits for the spork instances to start" do
        rspec_instance.should_receive(:running?).and_return(false, false, false, true)
        runner.should_receive(:sleep).with(1).exactly(4).times

        cucumber_instance.should_not_receive(:running?)
        runner.launch_sporks("", :rspec)
      end

      # This behavior is a bit weird, isn't it?
      it "does not wait longer than the configured wait duration + 60" do
        runner.options[:wait] = 7
        runner.should_receive(:sleep).with(1).exactly(67).times
        rspec_instance.stub(:running? => false)

        cucumber_instance.should_not_receive(:running?)
        expect {
          runner.launch_sporks("", :rspec)
        }.to throw_symbol(:task_has_failed)
      end
    end
  end

  describe "#kill_sporks(type)" do
    context "without a type" do
      it "kills all alive spork instances" do
        alive = double("alive instance", :alive? => true, :pid => 111)
        dead = double("dead instance", :alive? => false, :pid => 222)
        runner.stub(:spork_instances => {'a' => alive, 'b' => dead})

        Guard::UI.should_receive(:debug).with(/111/)
        alive.should_receive(:kill)
        dead.should_not_receive(:kill)

        runner.kill_sporks
      end
    end

    context "with a given type" do
      it "kills the matching spork instance" do
        matching = double("alive instance", :alive? => true, :pid => 111)
        other = double("dead instance", :alive? => true, :pid => 222)
        runner.stub(:spork_instances => {:matching => matching, :other => other})

        Guard::UI.should_receive(:debug).with(/111/)
        matching.should_receive(:kill)
        other.should_not_receive(:kill)

        runner.kill_sporks(:matching)
      end
    end
  end

  describe "#kill_global_sporks" do
    context "when configured to do aggressive killing" do
      before(:each) { runner.options[:aggressive_kill] = true }

      it "delegates to #kill_global_sporks!" do
        runner.should_receive(:kill_global_sporks!)
        runner.kill_global_sporks
      end
    end

    context "when configured to not do aggressive killing" do
      before(:each) { runner.options[:aggressive_kill] = false }

      it "does not call #kill_global_sporks!" do
        runner.should_not_receive(:kill_global_sporks!)
        runner.kill_global_sporks
      end
    end
  end

  describe "#kill_global_sporks!" do
    it "calls a KILL command for each Spork server running on the system" do
      # This is pretty hard to stub right now. We're hardcoding the command here
      runner.stub(:`).and_return { |command| raise "Unexpected command: #{command}" }
      runner.should_receive(:`).with("ps aux | awk '/spork/&&!/awk/{print $2;}'").and_return("666\n999")

      Guard::UI.should_receive(:debug).with('Killing Spork servers with PID: 666, 999')
      Process.should_receive(:kill).with('KILL', 666)
      Process.should_receive(:kill).with('KILL', 999)

      runner.kill_global_sporks!
    end
  end
end
