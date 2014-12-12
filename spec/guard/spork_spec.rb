require 'spec_helper'

describe Guard::Spork do
  subject { Guard::Spork.new }
  let(:runner) { subject.runner }

  describe '#initialize' do
    let(:runner) { double('runner instance', :reevaluate => nil) }
    before(:each) { allow(Guard::Spork::Runner).to receive_messages(:new => runner) }

    it "instantiates Runner with the given options" do
      expect(Guard::Spork::Runner).to receive(:new).with(:bundler => false).and_return(runner)
      Guard::Spork.new :bundler => false
    end
  end

  describe "#start" do
    it "calls Runner#kill_global_sporks and Runner#launch_sporks with 'start'" do
      expect(runner).to receive(:kill_global_sporks)
      expect(runner).to receive(:launch_sporks).with("start")
      subject.start
    end
  end

  describe "#reload" do
    it "calls Runner#kill_sporks and Runner#launch_sporks with 'reload'" do
      expect(runner).to receive(:kill_sporks)
      expect(runner).to receive(:launch_sporks).with("reload")
      subject.reload
    end
  end

  describe "#run_on_modifications" do
    it "calls Runner#kill_sporks and Runner#launch_sporks with 'reload'" do
      expect(runner).to receive(:kill_sporks)
      expect(runner).to receive(:launch_sporks).with("reload")
      subject.run_on_modifications(["spec/spec_helper.rb"])
    end
  end

  describe "#run_on_additions" do
    it "calls Runner#kill_sporks and Runner#launch_sporks with 'reload'" do
      expect(runner).to receive(:kill_sporks)
      expect(runner).to receive(:launch_sporks).with("reload")
      subject.run_on_additions(["spec/spec_helper.rb"])
    end
  end

  describe "#stop" do
    it "calls Runner#kill_sporks" do
      expect(runner).to receive(:kill_sporks)
      subject.stop
    end
  end
end
