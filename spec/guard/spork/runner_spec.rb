require 'spec_helper'
require 'timeout'

describe Guard::Spork::Runner do
  let(:runner) { Guard::Spork::Runner.new }

  describe "default options" do
    subject { Guard::Spork::Runner.new.options }

    it { is_expected.to include(:wait => 30) }
    it { is_expected.to include(:cucumber_port => 8990) }
    it { is_expected.to include(:rspec_port => 8989) }
    it { is_expected.to include(:test_unit_port => 8988) }
    it { is_expected.to include(:test_unit_env => {}) }
    it { is_expected.to include(:rspec_env => {}) }
    it { is_expected.to include(:minitest => false) }
    it { is_expected.to include(:cucumber_env => {}) }
    it { is_expected.to include(:aggressive_kill => true) }
    it { is_expected.to include(:foreman => false) }
    it { is_expected.to include(:quiet => false) }    
  end

  before(:each) do
    allow(Guard::Notifier).to receive(:notify)
    allow_any_instance_of(Guard::Spork::SporkInstance).to receive(:start)
    allow(Guard::UI).to receive(:info)
    allow(Guard::UI).to receive(:error)
    allow(Guard::UI).to receive(:reset_line)
  end

  describe "(spork detection)" do
    def file_existance(files)
      allow(File).to receive(:exist?).and_raise { |name| "Unexpected file passed: #{name}" }
      files.each_pair do |file, existance|
        allow(File).to receive(:exist?).with(file).and_return(existance)
      end
    end

    def instance(type, runner = runner)
      runner.spork_instances.find { |instance| instance.type == type }
    end

    def spork_instance_class
      Guard::Spork::Runner.send :spork_instance_class
    end

    it "has a spork instance for :rspec when configured" do
      runner = Guard::Spork::Runner.new({
        :rspec => true,
        :rspec_port => 2,
        :rspec_env  => {'spec' => 'yes'},
      })

      instance(:rspec, runner).tap do |instance|
        expect(instance.port).to eq(2)
        expect(instance.env).to eq({'spec' => 'yes'})
      end
    end

    it "has a spork instance for :cucumber when configured" do
      runner = Guard::Spork::Runner.new({
        :cucumber => true,
        :cucumber_port => 2,
        :cucumber_env  => {'cuke' => 'yes'},
      })

      instance(:cucumber, runner).tap do |instance|
        expect(instance.port).to eq(2)
        expect(instance.env).to eq({'cuke' => 'yes'})
      end
    end

    it "has a spork instance for :test_unit when configured" do
      runner = Guard::Spork::Runner.new({
        :test_unit => true,
        :test_unit_port => 2,
        :test_unit_env  => {'unit' => 'yes'},
      })

      instance(:test_unit, runner).tap do |instance|
        expect(instance.port).to eq(2)
        expect(instance.env).to eq({'unit' => 'yes'})
      end
    end

    it "has a spork instance for :minitest when configured" do
      runner = Guard::Spork::Runner.new({
        :minitest => true,
        :minitest_port => 2,
        :minitest_env  => {'minitest' => 'yes'},
      })

      instance(:minitest, runner).tap do |instance|
        expect(instance.port).to eq(2)
        expect(instance.env).to eq({'minitest' => 'yes'})
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
        expect(instance(:test_unit)).to be_instance_of(spork_instance_class)
      end

      it "does not have bundler enabled for the test_unit instance" do
        expect(instance(:test_unit).options).to include(:bundler => false)
      end

      it "does not have a spork instance for :rspec" do
        expect(instance(:rspec)).to be_nil
      end

      it "does not have a spork instance for :cucumber" do
        expect(instance(:cucumber)).to be_nil
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
        expect(instance(:minitest, @runner)).to be_instance_of(spork_instance_class)
      end

      it "does not have bundler enabled for the test_unit instance" do
        expect(instance(:minitest, @runner).options).to include(:bundler => false)
      end

      it "does not have a spork instance for :rspec" do
        expect(instance(:rspec, @runner)).to be_nil
      end

      it "does not have a spork instance for :cucumber" do
        expect(instance(:cucumber, @runner)).to be_nil
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
        expect(instance(:rspec)).to be_instance_of(spork_instance_class)
      end

      it "does not have bundler enabled for the rspec instance" do
        expect(instance(:rspec).options).to include(:bundler => false)
      end

      it "does not have a spork instance for :test_unit" do
        expect(instance(:test_unit)).to be_nil
      end

      it "does not have a spork instance for :cucumber" do
        expect(instance(:cucumber)).to be_nil
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
        expect(instance(:cucumber)).to be_instance_of(spork_instance_class)
      end

      it "does not have bundler enabled for the cucumber instance" do
        expect(instance(:cucumber).options).to include(:bundler => false)
      end

      it "does not have a spork instance for :test_unit" do
        expect(instance(:test_unit)).to be_nil
      end

      it "does not have a spork instance for :rspec" do
        expect(instance(:rspec)).to be_nil
      end

      it "does not have a spork instance for :minitest" do
        expect(instance(:minitest)).to be_nil
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
        expect(instance(:rspec)).to be_instance_of(spork_instance_class)
      end

      it "has a spork instance for :cucumber" do
        expect(instance(:cucumber)).to be_instance_of(spork_instance_class)
      end

      it "has bundler enabled for the rspec instance" do
        expect(instance(:rspec).options).to include(:bundler => true)
      end

      it "has bundler enabled for the cucumber instance" do
        expect(instance(:cucumber).options).to include(:bundler => true)
      end

      it "does not have a spork instance for :test_unit" do
        expect(instance(:test_unit)).to be_nil
      end
    end

    context ".windows?" do
      describe Guard::Spork::SporkInstance do
        before { runner.class.stub(:windows? => false) }

        it "is created when not Windows OS is used" do
          expect(instance(:rspec, Guard::Spork::Runner.new)).to be_instance_of(Guard::Spork::SporkInstance)
        end
      end

      describe Guard::Spork::SporkWindowsInstance do
        before { runner.class.stub(:windows? => true) }

        it "is created when Windows OS is used" do
          expect(instance(:rspec, Guard::Spork::Runner.new)).to be_instance_of(Guard::Spork::SporkWindowsInstance)
        end
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
      allow(runner).to receive(:sleep)
    end

    context "with no type specified" do
      it "outputs an info message" do
        runner.stub(:spork_instances => [
          fake_instance("one"),
          fake_instance("two"),
          fake_instance("three"),
        ])
        expect(Guard::UI).to receive(:info).with("Kissing Spork for one, two, three", :reset => true)
        runner.launch_sporks("kiss")
      end

      it "starts all spork instances" do
        expect(rspec_instance).to receive(:start)
        expect(cucumber_instance).to receive(:start)
        runner.launch_sporks("")
      end

      it "waits for the spork instances to start" do
        expect(rspec_instance).to receive(:running?).and_return(false, false, false, true)
        cucumber_instance.stub(:running? => true)
        expect(runner).to receive(:sleep).with(1).exactly(4).times

        runner.launch_sporks("")
      end

      # This behavior is a bit weird, isn't it?
      it "does not wait longer than the configured wait duration + 60" do
        runner.options[:wait] = 7
        expect(runner).to receive(:sleep).with(1).exactly(67).times
        rspec_instance.stub(:running? => false)
        cucumber_instance.stub(:running? => true)

        expect {
          runner.launch_sporks("")
        }.to throw_symbol(:task_has_failed)
      end

      it "does not wait longer than the configured wait duration + retry_delay" do
        runner.options[:wait] = 7
        runner.options[:retry_delay] = 10
        expect(runner).to receive(:sleep).with(1).exactly(17).times
        rspec_instance.stub(:running? => false)
        cucumber_instance.stub(:running? => true)

        expect {
          runner.launch_sporks("")
        }.to throw_symbol(:task_has_failed)
      end

      context "when :wait is nil" do
        it "does not time out" do
          runner.options[:wait] = nil
          rspec_instance.stub(:running? => false)
          cucumber_instance.stub(:running? => true)

          expect {
            runner.launch_sporks("")
          }.not_to throw_symbol(:task_has_failed)
        end
      end
    end

    context "with a type specified" do
      it "outputs an info message" do
        runner.stub(:spork_instances => [
          fake_instance("one"),
          fake_instance("two"),
          fake_instance("three"),
        ])
        expect(Guard::UI).to receive(:info).with("Kissing Spork for two", :reset => true)
        runner.launch_sporks("kiss", "two")
      end

      it "starts the matching spork instance" do
        expect(rspec_instance).to receive(:start)
        expect(cucumber_instance).not_to receive(:start)
        runner.launch_sporks("", :rspec)
      end

      it "waits for the spork instances to start" do
        expect(rspec_instance).to receive(:running?).and_return(false, false, false, true)
        expect(runner).to receive(:sleep).with(1).exactly(4).times

        expect(cucumber_instance).not_to receive(:running?)
        runner.launch_sporks("", :rspec)
      end

      # This behavior is a bit weird, isn't it?
      it "does not wait longer than the configured wait duration + 60" do
        runner.options[:wait] = 7
        expect(runner).to receive(:sleep).with(1).exactly(67).times
        rspec_instance.stub(:running? => false)

        expect(cucumber_instance).not_to receive(:running?)
        expect {
          runner.launch_sporks("", :rspec)
        }.to throw_symbol(:task_has_failed)
      end

      # This behavior is a bit weird, isn't it?
      it "does not wait longer than the configured wait duration + retry_delay" do
        runner.options[:wait] = 7
        runner.options[:retry_delay] = 10
        expect(runner).to receive(:sleep).with(1).exactly(17).times
        rspec_instance.stub(:running? => false)

        expect(cucumber_instance).not_to receive(:running?)
        expect {
          runner.launch_sporks("", :rspec)
        }.to throw_symbol(:task_has_failed)
      end

      context "when :wait is nil" do
        it "does not time out" do
          runner.options[:wait] = nil
          rspec_instance.stub(:running? => false)

          expect(cucumber_instance).not_to receive(:running?)
          expect {
            runner.launch_sporks("", :rspec)
          }.not_to throw_symbol(:task_has_failed)
        end
      end
    end
  end

  describe "#kill_sporks(type)" do
    context "without a type" do
      it "kills all alive spork instances" do
        alive = double("alive instance", :alive? => true, :pid => 111)
        dead = double("dead instance", :alive? => false, :pid => 222)
        runner.stub(:spork_instances => [alive, dead])

        expect(Guard::UI).to receive(:debug).with(/111/)
        expect(alive).to receive(:stop)
        expect(dead).not_to receive(:stop)

        runner.kill_sporks
      end
    end

    context "with a given type" do
      it "kills the matching spork instance" do
        matching = double("alive instance", :alive? => true, :pid => 111, :type => :matching)
        other = double("dead instance", :alive? => true, :pid => 222, :type => :other)
        runner.stub(:spork_instances => [matching, other])

        expect(Guard::UI).to receive(:debug).with(/111/)
        expect(matching).to receive(:stop)
        expect(other).not_to receive(:stop)

        runner.kill_sporks(:matching)
      end
    end
  end

  describe "#kill_global_sporks" do
    context "when configured to do aggressive killing" do
      before(:each) { runner.options[:aggressive_kill] = true }

      it "calls #kill_pids" do
        expect(runner).to receive(:kill_pids)
        runner.kill_global_sporks
      end

      it "calls a KILL command for each Spork server running on the system" do
        expect(runner.class.spork_instance_class).to receive(:spork_pids).and_return([666, 999])

        expect(Guard::UI).to receive(:debug).with('Killing Spork servers with PID: 666, 999')
        expect(Process).to receive(:kill).with('KILL', 666)
        expect(Process).to receive(:kill).with('KILL', 999)

        runner.kill_global_sporks
      end
    end

    context "when configured to not do aggressive killing" do
      before(:each) { runner.options[:aggressive_kill] = false }

      it "does not call #kill_pids" do
        expect(runner).not_to receive(:kill_pids)
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
        it {is_expected.to be_truthy}
      end

      context "with an option set to false" do
        before(:each) {runner.options[:what] = false}
        it {is_expected.to be_falsey}
      end

      context "with an option set to true" do
        before(:each) {runner.options[:what] = true}
        it {is_expected.to be_truthy}
      end
    end

    context "with the detection failing" do
      before(:each) { runner.stub(:detect_what => false) }

      # Not sure this is the best way of testing this, but since the behavior is the same regardless of the argument...
      subject {runner.send(:should_use?, :what)}
      context "with no option specified" do
        it {is_expected.to be_falsey}
      end

      context "with an option set to false" do
        before(:each) {runner.options[:what] = false}
        it {is_expected.to be_falsey}
      end

      context "with an option set to true" do
        before(:each) {runner.options[:what] = true}
        it {is_expected.to be_truthy}
      end
    end
  end

end
