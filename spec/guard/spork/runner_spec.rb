require 'spec_helper'

describe Guard::Spork::Runner do
  subject { Guard::Spork::Runner.new(:wait => 1) }
  
  its(:options) { should == { :cucumber_port => 8990, 
    :rspec_port => 8989,
    :test_unit_port => 8988,
    :wait => 1 } 
  }
  
  describe "#launch_sporks" do
    before(:each) do
      subject.stub(:system) { true }
      Dir.stub(:pwd) { "" }
    end
    
    context "with rspec" do
      before(:each) do
        File.should_receive(:exist?).any_number_of_times.with('/spec') { true }
        File.should_receive(:exist?).any_number_of_times.with('/features') { false }
        File.should_receive(:exist?).any_number_of_times.with('/test') { false }
        File.should_receive(:exist?).any_number_of_times.with('/Gemfile') { false }
        TCPSocket.should_receive(:new).with('localhost', 8989) { socket_mock }
      end
      
      it "should launch rspec spork server" do
        subject.should_receive(:system).with("spork -p 8989 >/dev/null 2>&1 < /dev/null &")
        subject.launch_sporks("start")
      end
    end

    context "with test::unit" do
      before(:each) do
        File.should_receive(:exist?).any_number_of_times.with('/test') { true }
        File.should_receive(:exist?).any_number_of_times.with('/spec') { false }
        File.should_receive(:exist?).any_number_of_times.with('/features') { false }
        File.should_receive(:exist?).any_number_of_times.with('/Gemfile') { false }
        TCPSocket.should_receive(:new).with('localhost', 8988) { socket_mock }
      end
      
      it "should launch test::unit spork server" do
        subject.should_receive(:system).with("spork -p 8988 >/dev/null 2>&1 < /dev/null &")
        subject.launch_sporks("start")
      end
    end
    
    context "with cucumber" do
      before(:each) do
        File.should_receive(:exist?).any_number_of_times.with('/spec') { false }
        File.should_receive(:exist?).any_number_of_times.with('/features') { true }
        File.should_receive(:exist?).any_number_of_times.with('/test') { false }
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
        File.should_receive(:exist?).any_number_of_times.with('/test') { false }
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
        File.should_receive(:exist?).any_number_of_times.with('/test') { false }
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
    it "should kill command" do
      subject.should_receive(:spork_pids) { [999] }
      Process.should_receive(:kill).with("KILL",999)
      subject.kill_sporks
    end
  end
  
private
  
  def socket_mock
    @socket_mock ||= mock(TCPSocket, :close => true)
  end
  
end
