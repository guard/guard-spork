require 'spec_helper'

describe Guard::Spork::Runner do
  subject { Guard::Spork::Runner.new }
  
  its(:options) { should == { :cucumber_port => 8990, :rspec_port => 8989 } }
  
  describe "#launch_sporks" do
    before(:each) do
      subject.stub(:system) { true }
      Dir.stub(:pwd) { "" }
    end
    
    # context "with rspec" do
    #   before(:each) do
    #     File.should_receive(:exist?).with('/spec') { true }
    #     File.should_receive(:exist?).with('/cucumber') { false }
    #   end
    #   
    #   it "should launch rspec spork server" do
    #     subject.should_receive(:system).with("kill $(ps aux | awk '/spork/&&!/awk/{print $2;}') >/dev/null 2>&1")
    #     subject.launch_sporks("start")
    #   end
    #   
    # end
    
    
  end
  
  describe "#kill_sporks" do
    it "should use magic kill command" do
      subject.should_receive(:system).with("kill $(ps aux | awk '/spork/&&!/awk/{print $2;}') >/dev/null 2>&1")
      subject.kill_sporks
    end
  end
  
  
end
