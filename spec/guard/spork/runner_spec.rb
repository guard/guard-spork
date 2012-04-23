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
    it { should include(:minitest => false) }
    it { should include(:cucumber_env => {}) }
    it { should include(:aggressive_kill => true) }
    it { should include(:foreman => false) }
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

    def instance(type, runner = runner)
      runner.spork_instances.find { |instance| instance.type == type }
    end

    it "has a spork instance for :rspec when configured" do
      runner = Guard::Spork::Runner.new({
        :rspec => true,
        :rspec_port => 2,
        :rspec_env  => {'spec' => 'yes'},
      })

      instance(:rspec, runner).tap do |instance|
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

      instance(:cucumber, runner).tap do |instance|
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

      instance(:test_unit, runner).tap do |instance|
        instance.port.should == 2
        instance.env.should == {'unit' => 'yes'}
      end
    end

    it "has a spork instance for :minitest when configured" do
      runner = Guard::Spork::Runner.new({
        :minitest => true,
        :minitest_port => 2,
        :minitest_env  => {'minitest' => 'yes'},
      })

      instance(:minitest, runner).tap do |instance|
        instance.port.should == 2
        instance.env.should == {'minitest' => 'yes'}
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
        instance(:test_unit).should be_instance_of(Guard::Spork::SporkInstance)
      end

      it "does not have bundler enabled for the test_unit instance" do
        instance(:test_unit).options.should include(:bundler => false)
      end

      it "does not have a spork instance for :rspec" do
        instance(:rspec).should be_nil
      end

      it "does not have a spork instance for :cucumber" do
        instance(:cucumber).should be_nil
      end
    end

    context "with MiniTest only" do
      before(:each) do
        file_existance({
          'test/test_helper.rb' => true,
          'spec'                => true,
          'features'            => false,
          'Gemfile'             => false,
        })

        @runner = Guard::Spork::Runner.new({
          :minitest => true,
          :minitest_port => 2,
          :minitest_env  => {'minitest' => 'yes'},
        })

      end

      it "has a spork instance for :test_unit" do
        instance(:minitest, @runner).should be_instance_of(Guard::Spork::SporkInstance)
      end

      it "does not have bundler enabled for the test_unit instance" do
        instance(:minitest, @runner).options.should include(:bundler => false)
      end

      it "does not have a spork instance for :rspec" do
        instance(:rspec, @runner).should be_nil
      end

      it "does not have a spork instance for :cucumber" do
        instance(:cucumber, @runner).should be_nil
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
        instance(:rspec).should be_instance_of(Guard::Spork::SporkInstance)
      end

      it "does not have bundler enabled for the rspec instance" do
        instance(:rspec).options.should include(:bundler => false)
      end

      it "does not have a spork instance for :test_unit" do
        instance(:test_unit).should be_nil
      end

      it "does not have a spork instance for :cucumber" do
        instance(:cucumber).should be_nil
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
        instance(:cucumber).should be_instance_of(Guard::Spork::SporkInstance)
      end

      it "does not have bundler enabled for the cucumber instance" do
        instance(:cucumber).options.should include(:bundler => false)
      end

      it "does not have a spork instance for :test_unit" do
        instance(:test_unit).should be_nil
      end

      it "does not have a spork instance for :rspec" do
        instance(:rspec).should be_nil
      end

      it "does not have a spork instance for :minitest" do
        instance(:minitest).should be_nil
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
        instance(:rspec).should be_instance_of(Guard::Spork::SporkInstance)
      end

      it "has a spork instance for :cucumber" do
        instance(:cucumber).should be_instance_of(Guard::Spork::SporkInstance)
      end

      it "has bundler enabled for the rspec instance" do
        instance(:rspec).options.should include(:bundler => true)
      end

      it "has bundler enabled for the cucumber instance" do
        instance(:cucumber).options.should include(:bundler => true)
      end

      it "does not have a spork instance for :test_unit" do
        instance(:test_unit).should be_nil
      end
    end
  end

  describe "#launch_sporks(action, type)" do
    let(:rspec_instance) { fake_instance(:rspec) }
    let(:cucumber_instance) { fake_instance(:cucumber) }

    def fake_instance(type)
      fake = Object.new
      fake.instance_eval do
        def start() nil end
        def running?() true end
        def type() @type end
        def to_s() type.to_s end
        def inspect() to_s end
      end
      fake.instance_variable_set('@type', type)
      fake
    end

    around(:each) do |example|
      Timeout.timeout(2) { example.run }
    end

    before(:each) do
      runner.stub(:spork_instances => [rspec_instance, cucumber_instance])
      runner.stub(:sleep)
    end

    context "with no type specified" do
      it "outputs an info message" do
        runner.stub(:spork_instances => [
          fake_instance("one"),
          fake_instance("two"),
          fake_instance("three"),
        ])
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
        runner.stub(:spork_instances => [
          fake_instance("one"),
          fake_instance("two"),
          fake_instance("three"),
        ])
        Guard::UI.should_receive(:info).with("Kissing Spork for two", :reset => true)
        runner.launch_sporks("kiss", "two")
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
        runner.stub(:spork_instances => [alive, dead])

        Guard::UI.should_receive(:debug).with(/111/)
        alive.should_receive(:stop)
        dead.should_not_receive(:stop)

        runner.kill_sporks
      end
    end

    context "with a given type" do
      it "kills the matching spork instance" do
        matching = double("alive instance", :alive? => true, :pid => 111, :type => :matching)
        other = double("dead instance", :alive? => true, :pid => 222, :type => :other)
        runner.stub(:spork_instances => [matching, other])

        Guard::UI.should_receive(:debug).with(/111/)
        matching.should_receive(:stop)
        other.should_not_receive(:stop)

        runner.kill_sporks(:matching)
      end
    end
  end

  describe "#kill_global_sporks" do
    context "when configured to do aggressive killing" do
      before(:each) { runner.options[:aggressive_kill] = true }

      it "calls #kill_pids" do
        runner.should_receive(:kill_pids)
        runner.kill_global_sporks
      end

      it "calls a KILL command for each Spork server running on the system" do
        # This is pretty hard to stub right now. We're hardcoding the command here
        runner.stub(:`).and_return { |command| raise "Unexpected command: #{command}" }
        runner.should_receive(:`).with("ps aux | awk '/spork/&&!/awk/{print $2;}'").and_return("666\n999")

        Guard::UI.should_receive(:debug).with('Killing Spork servers with PID: 666, 999')
        Process.should_receive(:kill).with('KILL', 666)
        Process.should_receive(:kill).with('KILL', 999)

        runner.kill_global_sporks
      end
    end

    context "when configured to not do aggressive killing" do
      before(:each) { runner.options[:aggressive_kill] = false }

      it "does not call #kill_pids" do
        runner.should_not_receive(:kill_pids)
        runner.kill_global_sporks
      end
    end
  end

  describe "#should_use?(what)" do
    subject {runner.send(:should_use?, :what)}

    context "with the detection succeeding" do
      before(:each) { runner.stub(:detect_what => true) }
      # Not sure this is the best way of testing this, but since the behavior is the same regardless of the argument...

      context "with no option specified" do
        it {should be_true}
      end

      context "with an option set to false" do
        before(:each) {runner.options[:what] = false}
        it {should be_false}
      end

      context "with an option set to true" do
        before(:each) {runner.options[:what] = true}
        it {should be_true}
      end
    end

    context "with the detection failing" do
      before(:each) { runner.stub(:detect_what => false) }

      # Not sure this is the best way of testing this, but since the behavior is the same regardless of the argument...
      subject {runner.send(:should_use?, :what)}
      context "with no option specified" do
        it {should be_false}
      end

      context "with an option set to false" do
        before(:each) {runner.options[:what] = false}
        it {should be_false}
      end

      context "with an option set to true" do
        before(:each) {runner.options[:what] = true}
        it {should be_true}
      end
    end
  end

end
