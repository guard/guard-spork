require 'spec_helper'

describe Guard::Spork::Runner do
  subject { Guard::Spork::Runner.new }

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
    subject.stub(:sleep)
  end

  describe "#launch_sporks" do
    before(:each) do
      Dir.stub(:pwd) { "" }
    end

    context "with Test::Unit only" do
      before(:each) do
        File.should_receive(:exist?).any_number_of_times.with('/test/test_helper.rb').and_return(true)
        File.should_receive(:exist?).any_number_of_times.with('/spec').and_return(false)
        File.should_receive(:exist?).any_number_of_times.with('/features').and_return(false)
        File.should_receive(:exist?).any_number_of_times.with('/Gemfile').and_return(false)
        TCPSocket.should_receive(:new).with('localhost', 8988) { socket_mock }
      end

      it "launches Spork server for Test::Unit" do
        subject.should_receive(:spawn_child).with({}, "spork testunit -p 8988")
        subject.launch_sporks("start")
      end
    end

    context "with RSpec only" do
      before(:each) do
        File.should_receive(:exist?).any_number_of_times.with('/test/test_helper.rb').and_return(false)
        File.should_receive(:exist?).any_number_of_times.with('/spec').and_return(true)
        File.should_receive(:exist?).any_number_of_times.with('/features').and_return(false)
        File.should_receive(:exist?).any_number_of_times.with('/Gemfile').and_return(false)
        TCPSocket.should_receive(:new).with('localhost', 8989) { socket_mock }
      end

      it "launches Spork server for RSpec" do
        subject.should_receive(:spawn_child).with({}, "spork -p 8989")
        subject.launch_sporks("start")
      end
    end

    context "with Cucumber only" do
      before(:each) do
        File.should_receive(:exist?).any_number_of_times.with('/test/test_helper.rb').and_return(false)
        File.should_receive(:exist?).any_number_of_times.with('/spec').and_return(false)
        File.should_receive(:exist?).any_number_of_times.with('/features').and_return(true)
        File.should_receive(:exist?).any_number_of_times.with('/Gemfile').and_return(false)
        TCPSocket.should_receive(:new).with('localhost', 8990) { socket_mock }
      end

      it "launches Spork server for Cucumber" do
        subject.should_receive(:spawn_child).with({}, "spork cu -p 8990")
        subject.launch_sporks("start")
      end
    end

    context "with RSpec & Cucumber" do
      before(:each) do
        File.should_receive(:exist?).any_number_of_times.with('/test/test_helper.rb').and_return(false)
        File.should_receive(:exist?).any_number_of_times.with('/spec').and_return(true)
        File.should_receive(:exist?).any_number_of_times.with('/features').and_return(true)
        File.should_receive(:exist?).any_number_of_times.with('/Gemfile').and_return(false)
        TCPSocket.should_receive(:new).with('localhost', 8989) { socket_mock }
        TCPSocket.should_receive(:new).with('localhost', 8990) { socket_mock }
      end

      it "launches Spork servers for RSpec & Cucumber" do
        subject.should_receive(:spawn_child).with({}, "spork -p 8989")
        subject.should_receive(:spawn_child).with({}, "spork cu -p 8990")
        subject.launch_sporks("start")
      end
    end

    context "with Test::Unit, RSpec, Cucumber & Bundler" do
      before(:each) do
        File.should_receive(:exist?).any_number_of_times.with('/test/test_helper.rb').and_return(true)
        File.should_receive(:exist?).any_number_of_times.with('/spec').and_return(true)
        File.should_receive(:exist?).any_number_of_times.with('/features').and_return(true)
        File.should_receive(:exist?).any_number_of_times.with('/Gemfile').and_return(true)
        TCPSocket.should_receive(:new).with('localhost', 8988) { socket_mock }
        TCPSocket.should_receive(:new).with('localhost', 8989) { socket_mock }
        TCPSocket.should_receive(:new).with('localhost', 8990) { socket_mock }
      end

      it "launches Spork servers for Test::Unit, RSpec & Cucumber with 'bundle exec'" do
        subject.should_receive(:spawn_child).with({}, "bundle exec spork testunit -p 8988")
        subject.should_receive(:spawn_child).with({}, "bundle exec spork -p 8989")
        subject.should_receive(:spawn_child).with({}, "bundle exec spork cu -p 8990")
        subject.launch_sporks("start")
      end
    end

    describe ":test_unit_env & :rspec_env & :cucumber_env options" do
      before(:each) do
        subject.options = {
          :wait => 20,
          :cucumber_port => 8990,
          :rspec_port => 8989,
          :test_unit_port => 8988,
          :test_unit_env => { 'RAILS_ENV' => 'test' },
          :rspec_env => { 'RAILS_ENV' => 'test' },
          :cucumber_env => { 'RAILS_ENV' => 'cucumber' }
        }
        Dir.stub(:pwd) { "" }
      end

      context "with Test::Unit only" do
        before(:each) do
          File.should_receive(:exist?).any_number_of_times.with('/test/test_helper.rb').and_return(true)
          File.should_receive(:exist?).any_number_of_times.with('/spec').and_return(false)
          File.should_receive(:exist?).any_number_of_times.with('/features').and_return(false)
          File.should_receive(:exist?).any_number_of_times.with('/Gemfile').and_return(false)
          TCPSocket.should_receive(:new).with('localhost', 8988) { socket_mock }
        end

        it "launches Spork server for Test::Unit" do
          subject.should_receive(:spawn_child).with({ 'RAILS_ENV' => 'test' }, "spork testunit -p 8988")
          subject.launch_sporks("start")
        end
      end

      context "with RSpec only" do
        before(:each) do
          File.should_receive(:exist?).any_number_of_times.with('/test/test_helper.rb').and_return(false)
          File.should_receive(:exist?).any_number_of_times.with('/spec').and_return(true)
          File.should_receive(:exist?).any_number_of_times.with('/features').and_return(false)
          File.should_receive(:exist?).any_number_of_times.with('/Gemfile').and_return(false)
          TCPSocket.should_receive(:new).with('localhost', 8989) { socket_mock }
        end

        it "launches Spork server for RSpec" do
          subject.should_receive(:spawn_child).with({ 'RAILS_ENV' => 'test' }, "spork -p 8989")
          subject.launch_sporks("start")
        end
      end

      context "with Cucumber only" do
        before(:each) do
          File.should_receive(:exist?).any_number_of_times.with('/test/test_helper.rb').and_return(false)
          File.should_receive(:exist?).any_number_of_times.with('/spec').and_return(false)
          File.should_receive(:exist?).any_number_of_times.with('/features').and_return(true)
          File.should_receive(:exist?).any_number_of_times.with('/Gemfile').and_return(false)
          TCPSocket.should_receive(:new).with('localhost', 8990) { socket_mock }
        end

        it "launches Spork server for Cucumber" do
          subject.should_receive(:spawn_child).with({ 'RAILS_ENV' => 'cucumber' }, "spork cu -p 8990")
          subject.launch_sporks("start")
        end
      end

      context "with RSpec & Cucumber" do
        before(:each) do
          File.should_receive(:exist?).any_number_of_times.with('/test/test_helper.rb').and_return(false)
          File.should_receive(:exist?).any_number_of_times.with('/spec').and_return(true)
          File.should_receive(:exist?).any_number_of_times.with('/features').and_return(true)
          File.should_receive(:exist?).any_number_of_times.with('/Gemfile').and_return(false)
          TCPSocket.should_receive(:new).with('localhost', 8989) { socket_mock }
          TCPSocket.should_receive(:new).with('localhost', 8990) { socket_mock }
        end

        it "launches Spork servers for RSpec & Cucumber" do
          subject.should_receive(:spawn_child).with({ 'RAILS_ENV' => 'test' }, "spork -p 8989")
          subject.should_receive(:spawn_child).with({ 'RAILS_ENV' => 'cucumber' }, "spork cu -p 8990")
          subject.launch_sporks("start")
        end
      end

      context "with Test::Unit, RSpec, Cucumber & Bundler" do
        before(:each) do
          File.should_receive(:exist?).any_number_of_times.with('/test/test_helper.rb').and_return(true)
          File.should_receive(:exist?).any_number_of_times.with('/spec').and_return(true)
          File.should_receive(:exist?).any_number_of_times.with('/features').and_return(true)
          File.should_receive(:exist?).any_number_of_times.with('/Gemfile').and_return(true)
          TCPSocket.should_receive(:new).with('localhost', 8988) { socket_mock }
          TCPSocket.should_receive(:new).with('localhost', 8989) { socket_mock }
          TCPSocket.should_receive(:new).with('localhost', 8990) { socket_mock }
        end

        it "launches Spork servers for Test::Unit, RSpec & Cucumber with 'bundle exec'" do
          subject.should_receive(:spawn_child).with({ 'RAILS_ENV' => 'test' }, "bundle exec spork testunit -p 8988")
          subject.should_receive(:spawn_child).with({ 'RAILS_ENV' => 'test' }, "bundle exec spork -p 8989")
          subject.should_receive(:spawn_child).with({ 'RAILS_ENV' => 'cucumber' }, "bundle exec spork cu -p 8990")
          subject.launch_sporks("start")
        end
      end
      
      context "failed to start" do
        before(:each) do
          File.should_receive(:exist?).any_number_of_times.with('/test/test_helper.rb').and_return(true)
          File.should_receive(:exist?).any_number_of_times.with('/spec').and_return(true)
          File.should_receive(:exist?).any_number_of_times.with('/features').and_return(true)
          File.should_receive(:exist?).any_number_of_times.with('/Gemfile').and_return(true)
          subject.should_receive(:spawn_child).with({ 'RAILS_ENV' => 'test' }, "bundle exec spork testunit -p 8988")
          subject.should_receive(:spawn_child).with({ 'RAILS_ENV' => 'test' }, "bundle exec spork -p 8989")
          subject.should_receive(:spawn_child).with({ 'RAILS_ENV' => 'cucumber' }, "bundle exec spork cu -p 8990")
        end
        
        context "fails on both attempts" do
          it "waits first for configured time, then for an additional 60 seconds, then fails the task" do
            subject.should_receive(:wait_for_launch).with(20).and_return(false)
            subject.should_receive(:wait_for_launch).with(60).and_return(false)
            lambda { subject.launch_sporks("start") }.should throw_symbol(:task_has_failed)
          end
        end
        
        context "succeeds in grace period" do
          it "waits first for configured time, then for an additional 60 seconds, and succeeds" do
            subject.should_receive(:wait_for_launch).with(20).and_return(false)
            subject.should_receive(:wait_for_launch).with(60).and_return(true)
            subject.launch_sporks("start")
          end
        end
      end

    end
  end

  describe "#swap_env" do
    before(:each) do
      ENV['FOO_ENV'] = 'foo'
    end

    it "doesn't change current ENV" do
      ENV['FOO_ENV'].should == 'foo'
      subject.send(:swap_env, { 'FOO_ENV' => 'test' }) { "Foo" }
      ENV['FOO_ENV'].should == 'foo'
    end
  end

  describe "#kill_sporks" do
    it "calls a KILL command for each Spork server" do
      ENV['SPORK_PIDS'] = '666, 999'
      Guard::UI.should_receive(:debug).with('Killing Spork servers with PID: 666, 999')
      Process.should_receive(:kill).with('KILL', 666)
      Process.should_receive(:kill).with('KILL', 999)
      subject.kill_sporks
      ENV['SPORK_PIDS'].should eql('')
      ENV['SPORK_PIDS'] = nil
    end

    it "calls a KILL command for each Spork server getting from aggressive ps spork pids" do
      ENV['SPORK_PIDS'] = ''
      subject.should_receive(:ps_spork_pids).twice.and_return([666,999])
      Guard::UI.should_receive(:debug).with('Killing Spork servers with PID: 666, 999')
      Process.should_receive(:kill).with('KILL', 666)
      subject.should_receive(:remove_children).with(666)
      Process.should_receive(:kill).with('KILL', 999)
      subject.should_receive(:remove_children).with(999)
      subject.kill_sporks
    end
  end

private

  def socket_mock
    @socket_mock ||= mock(TCPSocket, :close => true)
  end
end
