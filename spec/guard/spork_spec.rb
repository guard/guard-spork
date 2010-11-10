require 'spec_helper'

describe Guard::Spork do
  subject { Guard::Spork.new }
  
  describe '#initialize' do
    it 'should instanciate runner with option' do
      Guard::Spork::Runner.should_receive(:new).with(:bundler => false)
      Guard::Spork.new [], { :bundler => false }
    end
  end
  
  describe "start" do
    it "should start sporks" do
      subject.runner.should_receive(:launch_sporks).with("start")
      subject.start
    end
  end
  
  describe "reload" do
    it "should kill & relaund sporks'" do
      subject.runner.should_receive(:kill_sporks)
      subject.runner.should_receive(:launch_sporks).with("reload")
      subject.reload
    end
  end
  
  describe "run_on_change" do
    it "should kill & relaund sporks'" do
      subject.runner.should_receive(:kill_sporks)
      subject.runner.should_receive(:launch_sporks).with("reload")
      subject.run_on_change(["spec/spec_helper.rb"])
    end
  end
  
end
