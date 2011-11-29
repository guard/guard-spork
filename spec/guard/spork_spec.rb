require 'spec_helper'

describe Guard::Spork do
  subject { Guard::Spork.new }

  describe '#initialize' do
    it "instantiates Runner with the given options" do
      Guard::Spork::Runner.should_receive(:new).with(:bundler => false)
      Guard::Spork.new [], { :bundler => false }
    end
  end

  describe "#start" do
    it "calls Runner#kill_global_sporks and Runner#launch_sporks with 'start'" do
      subject.runner.should_receive(:kill_global_sporks)
      subject.runner.should_receive(:launch_sporks).with("start")
      subject.start
    end
  end

  describe "#reload" do
    it "calls Runner#kill_sporks and Runner#launch_sporks with 'reload'" do
      subject.runner.should_receive(:kill_sporks)
      subject.runner.should_receive(:launch_sporks).with("reload")
      subject.reload
    end
  end

  describe "#run_on_change" do
    it "calls Runner#kill_sporks and Runner#launch_sporks with 'reload'" do
      subject.runner.should_receive(:kill_sporks)
      subject.runner.should_receive(:launch_sporks).with("reload")
      subject.run_on_change(["spec/spec_helper.rb"])
    end
  end

  describe "#stop" do
    it "calls Runner#kill_sporks" do
      subject.runner.should_receive(:kill_sporks)
      subject.stop
    end
  end
end
