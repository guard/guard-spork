require 'spec_helper'

describe Guard::Spork::Runner do
  subject { Guard::Spork::Runner.new(:wait => 1) }
  
  its(:options) { should == { :cucumber_port => 8990, :rspec_port => 8989, :wait => 1 } }
  
  describe "#launch_sporks" do
    before(:each) do
      subject.stub(:system) { true }
      Dir.stub(:pwd) { "" }
    end
    
    context "with rspec" do
      before(:each) do
        File.should_receive(:exist?).any_number_of_times.with('/spec') { true }
        File.should_receive(:exist?).any_number_of_times.with('/features') { false }
        File.should_receive(:exist?).any_number_of_times.with('/Gemfile') { false }
        TCPSocket.should_receive(:new).with('localhost', 8989) { socket_mock }
      end
      
      it "should launch rspec spork server" do
        subject.should_receive(:system).with("spork -p 8989 >/dev/null 2>&1 < /dev/null &")
        subject.launch_sporks("start")
      end
    end
    
    context "with cucumber" do
      before(:each) do
        File.should_receive(:exist?).any_number_of_times.with('/spec') { false }
        File.should_receive(:exist?).any_number_of_times.with('/features') { true }
        File.should_receive(:exist?).any_number_of_times.with('/Gemfile') { false }
        TCPSocket.should_receive(:new).with('localhost', 8990) { socket_mock }
      end
      
      it "should launch cucumber spork server" do
        subject.should_receive(:system).with("spork cu -p 8990 >/dev/null 2>&1 < /dev/null &")
        subject.launch_sporks("start")
      end
    end
    
    context "with rspec & cucumber" do
      before(:each) do
        File.should_receive(:exist?).any_number_of_times.with('/spec') { true }
        File.should_receive(:exist?).any_number_of_times.with('/features') { true }
        File.should_receive(:exist?).any_number_of_times.with('/Gemfile') { false }
        TCPSocket.should_receive(:new).with('localhost', 8989) { socket_mock }
        TCPSocket.should_receive(:new).with('localhost', 8990) { socket_mock }
      end
      
      it "should launch rspec & cucumber spork server" do
        subject.should_receive(:system).with("spork -p 8989 >/dev/null 2>&1 < /dev/null &")
        subject.should_receive(:system).with("spork cu -p 8990 >/dev/null 2>&1 < /dev/null &")
        subject.launch_sporks("start")
      end
    end
    
    context "with rspec, cucumber & bundler" do
      before(:each) do
        File.should_receive(:exist?).any_number_of_times.with('/spec') { true }
        File.should_receive(:exist?).any_number_of_times.with('/features') { true }
        File.should_receive(:exist?).any_number_of_times.with('/Gemfile') { true }
        TCPSocket.should_receive(:new).with('localhost', 8989) { socket_mock }
        TCPSocket.should_receive(:new).with('localhost', 8990) { socket_mock }
      end
      
      it "should launch rspec & cucumber spork server" do
        subject.should_receive(:system).with("bundle exec spork -p 8989 >/dev/null 2>&1 < /dev/null &")
        subject.should_receive(:system).with("bundle exec spork cu -p 8990 >/dev/null 2>&1 < /dev/null &")
        subject.launch_sporks("start")
      end
    end
    
  end
  
  describe "#kill_sporks" do
    it "should use magic kill command" do
      subject.should_receive(:system).with("kill $(ps aux | awk '/spork/&&!/awk/{print $2;}') >/dev/null 2>&1")
      subject.kill_sporks
    end
  end
  
private
  
  def socket_mock
    @socket_mock ||= mock(TCPSocket, :close => true)
  end
  
end