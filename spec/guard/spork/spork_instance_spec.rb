require "guard/spork"

module Guard
  class Spork
    RSpec.describe SporkInstance do
      it "remembers instances" do
        SporkInstance.new('type', 0, {}, {})
      end

      describe "rspec on port 1337" do
        let(:options) { Hash.new }
        subject { SporkInstance.new(:rspec, 1337, {}, options) }

        describe '#command' do
          subject { super().command }
          it { is_expected.to eq(%w{spork -p 1337}) }
        end

        describe '#port' do
          subject { super().port }
          it { is_expected.to eq(1337) }
        end

        describe '#type' do
          subject { super().type }
          it { is_expected.to eq(:rspec) }
        end

        describe '#to_s' do
          subject { super().to_s }
          it { is_expected.to eq("RSpec") }
        end

        context "with bundler enabled" do
          let(:options) { {:bundler => true} }

          describe '#command' do
            subject { super().command }
            it { is_expected.to eq(%w{bundle exec spork -p 1337}) }
          end
        end

        context "with foreman enabled" do
          let(:options) { { :foreman => true, :bundler => true } }

          describe '#command' do
            subject { super().command }
            it { is_expected.to eq(%w{bundle exec foreman run spork -p 1337}) }
          end
        end

        context "with quiet enabled" do
          let(:options) { { :quiet => true } }

          describe '#command' do
            subject { super().command }
            it { is_expected.to eq(%w{spork -p 1337 -q}) }
          end
        end
      end

      describe "cucumber on port 1337" do
        let(:options) { Hash.new }
        subject { SporkInstance.new(:cucumber, 1337, {}, options) }

        describe '#command' do
          subject { super().command }
          it { is_expected.to eq(%w{spork cu -p 1337}) }
        end

        describe '#port' do
          subject { super().port }
          it { is_expected.to eq(1337) }
        end

        describe '#type' do
          subject { super().type }
          it { is_expected.to eq(:cucumber) }
        end

        describe '#to_s' do
          subject { super().to_s }
          it { is_expected.to eq("Cucumber") }
        end

        context "with bundler enabled" do
          let(:options) { {:bundler => true} }

          describe '#command' do
            subject { super().command }
            it { is_expected.to eq(%w{bundle exec spork cu -p 1337}) }
          end
        end

        context "with foreman enabled" do
          let(:options) { { :foreman => true, :bundler => true } }

          describe '#command' do
            subject { super().command }
            it { is_expected.to eq(%w{bundle exec foreman run spork cu -p 1337}) }
          end
        end

        context "with foreman enabled and env name option" do
          let(:options) { { :foreman => { :env => ".env.test" }, :bundler => true } }

          describe '#command' do
            subject { super().command }
            it { is_expected.to eq(%w{bundle exec foreman run spork cu -p 1337 -e=.env.test})}
          end
        end
      end

      describe "test_unit on port 1337" do
        let(:options) { Hash.new }
        subject { SporkInstance.new(:test_unit, 1337, {}, options) }

        describe '#command' do
          subject { super().command }
          it { is_expected.to eq(%w{spork testunit -p 1337}) }
        end

        describe '#port' do
          subject { super().port }
          it { is_expected.to eq(1337) }
        end

        describe '#type' do
          subject { super().type }
          it { is_expected.to eq(:test_unit) }
        end

        describe '#to_s' do
          subject { super().to_s }
          it { is_expected.to eq("Test::Unit") }
        end

        context "with bundler enabled" do
          let(:options) { {:bundler => true} }

          describe '#command' do
            subject { super().command }
            it { is_expected.to eq(%w{bundle exec spork testunit -p 1337}) }
          end
        end

        context "with foreman enabled" do
          let(:options) { { :foreman => true, :bundler => true } }

          describe '#command' do
            subject { super().command }
            it { is_expected.to eq(%w{bundle exec foreman run spork testunit -p 1337}) }
          end
        end

        context "with foreman enabled and env name option" do
          let(:options) { { :foreman => { :env => ".env.test" }, :bundler => true } }

          describe '#command' do
            subject { super().command }
            it { is_expected.to eq(%w{bundle exec foreman run spork testunit -p 1337 -e=.env.test})}
          end
        end
      end

      describe "minitest on port 1338" do
        let(:options) { Hash.new }
        subject { SporkInstance.new(:minitest, 1338, {}, options) }

        describe '#command' do
          subject { super().command }
          it { is_expected.to eq(%w{spork minitest -p 1338}) }
        end

        describe '#port' do
          subject { super().port }
          it { is_expected.to eq(1338) }
        end

        describe '#type' do
          subject { super().type }
          it { is_expected.to eq(:minitest) }
        end

        describe '#to_s' do
          subject { super().to_s }
          it { is_expected.to eq("MiniTest") }
        end

        context "with bundler enabled" do
          let(:options) { {:bundler => true} }

          describe '#command' do
            subject { super().command }
            it { is_expected.to eq(%w{bundle exec spork minitest -p 1338}) }
          end
        end

        context "with foreman enabled" do
          let(:options) { { :foreman => true, :bundler => true } }

          describe '#command' do
            subject { super().command }
            it { is_expected.to eq(%w{bundle exec foreman run spork minitest -p 1338})}
          end
        end

        context "with foreman enabled and env name option" do
          let(:options) { { :foreman => { :env => ".env.test" }, :bundler => true } }

          describe '#command' do
            subject { super().command }
            it { is_expected.to eq(%w{bundle exec foreman run spork minitest -p 1338 -e=.env.test})}
          end
        end
      end

    end

    RSpec.describe SporkInstance, "spawning" do
      let(:instance) { SporkInstance.new(:test, 1, {}, {}) }
      before(:each) do
        allow(instance).to receive_messages(:command => "")
        allow(Guard::Compat::UI).to receive(:debug)
      end

      describe "#start" do
        after(:each) { ENV.delete('SPORK_PIDS') }

        it "uses ChildProcess and stores the pid" do
          process = double("process").as_null_object
          expect(ChildProcess).to receive(:build).and_return(process)
          allow(process).to receive_messages(:pid => "a pid")
          expect {
            instance.start
          }.to change(instance, :pid).from(nil).to("a pid")
        end

        it "passes environment to the ChildProcess" do
          allow(instance).to receive_messages(:command => "command", :env => {:environment => true})
          process = double("process").as_null_object
          expect(ChildProcess).to receive(:build).and_return(process)
          process_env = {}
          expect(process).to receive(:environment).and_return(process_env)
          expect(process_env).to receive(:merge!).with(:environment => true)
          instance.start
        end
      end

      describe "#stop" do
        it "delegates to ChildProcess#stop" do
          process = double("a process")
          allow(instance).to receive(:process).and_return(process)
          expect(process).to receive(:stop)
          instance.stop
        end
      end

      describe "(alive)" do
        subject { instance }
        before(:each) do
          allow(instance).to receive_messages(:pid => nil)
        end

        context "when no pid is set" do
          it { is_expected.not_to be_alive }
        end

        context "when the pid is a running process" do
          before(:each) do
            allow(instance).to receive_messages(:pid => 42)
            process = double("a process")
            allow(instance).to receive_messages(:process => process)
            allow(process).to receive_messages(:alive? => true)
          end

          it { is_expected.to be_alive }
        end

        context "when the pid is a stopped process" do
          subject { instance }
          before(:each) do
            allow(instance).to receive_messages(:pid => 42)
            process = double("a process")
            allow(instance).to receive_messages(:process => process)
            allow(process).to receive_messages(:alive? => false)
          end

          it { is_expected.not_to be_alive }
        end
      end

      describe "(running)" do
        let(:socket) { double(:close => nil) }
        subject { instance }

        before(:each) do
          allow(instance).to receive_messages(:pid => 42, :port => 1337)
          allow(TCPSocket).to receive_messages(:new => socket)
        end

        context "when no pid is specified" do
          before(:each) { allow(instance).to receive_messages(:pid => nil) }
          it { is_expected.not_to be_running }
        end

        context "when process is not alive" do
          before(:each) { allow(instance).to receive_messages(:alive? => false)}
          it { is_expected.not_to be_running }
        end

        context "when spork does not respond" do
          before(:each) do
            expect(TCPSocket).to receive(:new).with('127.0.0.1', 1337).and_raise(Errno::ECONNREFUSED)
            allow(instance).to receive_messages(:alive? => true)
          end

          it { is_expected.not_to be_running }
        end

        context "when spork accepts the connection" do
          before(:each) do
            expect(TCPSocket).to receive(:new).with('127.0.0.1', 1337).and_return(socket)
            allow(instance).to receive_messages(:alive? => true)
          end

          it { is_expected.to be_running }
        end
      end

      describe ".spork_pids" do
        it "returns all the pids belonging to spork" do
          allow(instance.class).to receive(:`) { |command| raise "Unexpected command: #{command}" }
          expect(instance.class).to receive(:`).
            with(%q[ps aux | grep -v guard | awk '/spork/&&!/awk/{print $2;}']).
            and_return("666\n999")

          expect(instance.class.spork_pids).to eq([666, 999])
        end
      end
    end
  end
end
