require 'spec_helper'

class Guard::Spork
  describe SporkInstance do
    let(:env) { Hash.new }

    describe "rspec on port 1337" do
      let(:options) { Hash.new }
      subject { SporkInstance.new(:rspec, 1337, env, options) }

      its(:command) { should == "spork -p 1337" }
      its(:port) { should == 1337 }

      context "with bundler enabled" do
        let(:options) { {:bundler => true} }

        its(:command) { should == "bundle exec spork -p 1337" }
      end
    end

    describe "cucumber on port 1337" do
      let(:options) { Hash.new }
      subject { SporkInstance.new(:cucumber, 1337, env, options) }

      its(:command) { should == "spork cu -p 1337" }
      its(:port) { should == 1337 }

      context "with bundler enabled" do
        let(:options) { {:bundler => true} }

        its(:command) { should == "bundle exec spork cu -p 1337" }
      end
    end

    describe "test_unit on port 1337" do
      let(:options) { Hash.new }
      subject { SporkInstance.new(:test_unit, 1337, env, options) }

      its(:command) { should == "spork testunit -p 1337" }
      its(:port) { should == 1337 }

      context "with bundler enabled" do
        let(:options) { {:bundler => true} }

        its(:command) { should == "bundle exec spork testunit -p 1337" }
      end
    end
  end
end
