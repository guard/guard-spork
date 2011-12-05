require 'spec_helper'

describe Guard::Spork do
  subject { Guard::Spork.new }
  let(:runner) { subject.runner }

  describe '#initialize' do
    let(:runner) { double('runner instance', :reevaluate => nil) }
    before(:each) { Guard::Spork::Runner.stub(:new => runner) }

    it "instantiates Runner with the given options" do
      Guard::Spork::Runner.should_receive(:new).with(:bundler => false).and_return(runner)
      Guard::Spork.new [], :bundler => false
    end

    it "kills any orphan spork instances" do
      runner.should_receive(:reevaluate)
      Guard::Spork.new []
    end
  end

  describe "#start" do
    it "calls Runner#kill_global_sporks and Runner#launch_sporks with 'start'" do
      runner.should_receive(:kill_global_sporks)
      runner.should_receive(:launch_sporks).with("start")
      subject.start
    end
  end

  describe "#reload" do
    it "calls Runner#kill_sporks and Runner#launch_sporks with 'reload'" do
      runner.should_receive(:kill_sporks)
      runner.should_receive(:launch_sporks).with("reload")
      subject.reload
    end
  end

  describe "#run_on_change" do
    context "with files" do
      it "calls Runner#kill_sporks and Runner#launch_sporks with 'reload'" do
        runner.should_receive(:kill_sporks)
        runner.should_receive(:launch_sporks).with("reload")
        subject.run_on_change(["spec/spec_helper.rb"])
      end
    end

    context "with a symbol" do
      it "restarts the spork instance matching the symbol" do
        runner.should_receive(:kill_sporks).with(:symbol)
        runner.should_receive(:launch_sporks).with("reload", :symbol)
        subject.run_on_change(:symbol)
      end
    end
  end

  describe "#stop" do
    it "calls Runner#kill_sporks" do
      runner.should_receive(:kill_sporks)
      subject.stop
    end
  end
end
