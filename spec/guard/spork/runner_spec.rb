require 'spec_helper'

describe Guard::Spork::Runner do
  subject { Guard::Spork::Runner.new }

  describe "#initialize" do
    it "default options are { :wait => 20, :cucumber_port => 8990, :rspec_port => 8989, :rspec_env => nil, :cucumber_env => nil }" do
      subject.options.should == {
        :wait => 20,
        :cucumber_port => 8990,
        :rspec_port => 8989,
        :rspec_env => nil,
        :cucumber_env => nil
      }
    end
  end

  describe "#launch_sporks" do
    before(:each) do
      Dir.stub(:pwd) { "" }
    end

    context "with RSpec only" do
      before(:each) do
        File.should_receive(:exist?).any_number_of_times.with('/spec').and_return(true)
        File.should_receive(:exist?).any_number_of_times.with('/features').and_return(false)
        File.should_receive(:exist?).any_number_of_times.with('/Gemfile').and_return(false)
        TCPSocket.should_receive(:new).with('localhost', 8989) { socket_mock }
      end

      it "launches Spork server for RSpec" do
        subject.should_receive(:spawn_child).with(nil, "spork -p 8989")
        subject.launch_sporks("start")
      end
    end

    context "with Cucumber only" do
      before(:each) do
        File.should_receive(:exist?).any_number_of_times.with('/spec').and_return(false)
        File.should_receive(:exist?).any_number_of_times.with('/features').and_return(true)
        File.should_receive(:exist?).any_number_of_times.with('/Gemfile').and_return(false)
        TCPSocket.should_receive(:new).with('localhost', 8990) { socket_mock }
      end

      it "launches Spork server for Cucumber" do
        subject.should_receive(:spawn_child).with(nil, "spork cu -p 8990")
        subject.launch_sporks("start")
      end
    end

    context "with RSpec & Cucumber" do
      before(:each) do
        File.should_receive(:exist?).any_number_of_times.with('/spec').and_return(true)
        File.should_receive(:exist?).any_number_of_times.with('/features').and_return(true)
        File.should_receive(:exist?).any_number_of_times.with('/Gemfile').and_return(false)
        TCPSocket.should_receive(:new).with('localhost', 8989) { socket_mock }
        TCPSocket.should_receive(:new).with('localhost', 8990) { socket_mock }
      end

      it "launches Spork servers for RSpec & Cucumber" do
        subject.should_receive(:spawn_child).with(nil, "spork -p 8989")
        subject.should_receive(:spawn_child).with(nil, "spork cu -p 8990")
        subject.launch_sporks("start")
      end
    end

    context "with RSpec, Cucumber & Bundler" do
      before(:each) do
        File.should_receive(:exist?).any_number_of_times.with('/spec').and_return(true)
        File.should_receive(:exist?).any_number_of_times.with('/features').and_return(true)
        File.should_receive(:exist?).any_number_of_times.with('/Gemfile').and_return(true)
        TCPSocket.should_receive(:new).with('localhost', 8989) { socket_mock }
        TCPSocket.should_receive(:new).with('localhost', 8990) { socket_mock }
      end

      it "launches Spork servers for RSpec & Cucumber with 'bundle exec'" do
        subject.should_receive(:spawn_child).with(nil, "bundle exec spork -p 8989")
        subject.should_receive(:spawn_child).with(nil, "bundle exec spork cu -p 8990")
        subject.launch_sporks("start")
      end
    end

    describe ":rspec_env & :cucumber_env options" do
      before(:each) do
        subject.options = {
          :wait => 20,
          :cucumber_port => 8990,
          :rspec_port => 8989,
          :rspec_env => { 'RAILS_ENV' => 'test' },
          :cucumber_env => { 'RAILS_ENV' => 'cucumber' }
        }
        Dir.stub(:pwd) { "" }
      end

      context "with RSpec only" do
        before(:each) do
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

      context "with RSpec, Cucumber & Bundler" do
        before(:each) do
          File.should_receive(:exist?).any_number_of_times.with('/spec').and_return(true)
          File.should_receive(:exist?).any_number_of_times.with('/features').and_return(true)
          File.should_receive(:exist?).any_number_of_times.with('/Gemfile').and_return(true)
          TCPSocket.should_receive(:new).with('localhost', 8989) { socket_mock }
          TCPSocket.should_receive(:new).with('localhost', 8990) { socket_mock }
        end

        it "launches Spork servers for RSpec & Cucumber with 'bundle exec'" do
          subject.should_receive(:spawn_child).with({ 'RAILS_ENV' => 'test' }, "bundle exec spork -p 8989")
          subject.should_receive(:spawn_child).with({ 'RAILS_ENV' => 'cucumber' }, "bundle exec spork cu -p 8990")
          subject.launch_sporks("start")
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
      subject.should_receive(:spork_pids).twice.and_return([666, 999])
      Guard::UI.should_receive(:debug).with("Killing Spork servers with PID: 666, 999")
      Process.should_receive(:kill).with("KILL", 666)
      Process.should_receive(:kill).with("KILL", 999)
      subject.kill_sporks
    end
  end

private

  def socket_mock
    @socket_mock ||= mock(TCPSocket, :close => true)
  end
end
