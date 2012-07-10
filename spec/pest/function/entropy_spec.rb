require 'spec_helper'

class EntropyTestClass
  include Pest::Estimator
  include Pest::Function::Entropy
end

describe Pest::Function::Entropy do
  before(:each) do
    @instance = EntropyTestClass.new
    @instance.stub(:variables).and_return([:foo, :bar].to_set)
  end

  describe "#mutual_information" do
    before(:each) { @instance.stub(:h).and_return(-1) }

    it "determines H(first)" do
      @instance.should_receive(:h).with(:foo)

      @instance.mutual_information(:foo, :bar)
    end
    
    it "determines H(second)" do
      @instance.should_receive(:h).with(:bar)

      @instance.mutual_information(:foo, :bar)
    end

    it "determines H(first & second)" do
      @instance.should_receive(:h).with(:foo, :bar)

      @instance.mutual_information(:foo, :bar)
    end

    it "returns H(first) + H(second) - H(first & second)" do
      @instance.stub(:h).with(:foo).and_return 1
      @instance.stub(:h).with(:bar).and_return 10
      @instance.stub(:h).with(:foo, :bar).and_return 100

      @instance.mutual_information(:foo, :bar).should == (1+10-100)
    end
  end

  describe "#entropy" do
    it "returns a Builder" do
      @instance.entropy.should be_a(Pest::Function::Entropy::Builder)
    end

    it "is aliased as h" do
      @instance.h.should be_a(Pest::Function::Entropy::Builder)
    end
  end

  describe Pest::Function::Entropy::Builder do
    describe "::new" do
      before(:each) { @builder = EntropyTestClass::Builder.new(@instance, [:foo, :bar]) }

      it "sets estimator" do
        @builder.estimator.should == @instance
      end

      it "sets event" do
        @builder.event.should == [:foo, :bar].to_set
      end

      it "fails if variable undefined for estimator" do
        pending "slow - necessary?"
        lambda { EntropyTestClass::Builder.new(@instance, [:foo, :baz]) }.should raise_error(ArgumentError)
      end
    end

    describe "#given" do
      before(:each) { @builder = EntropyTestClass::Builder.new(@instance, [:foo]) }

      it "sets givens" do
        @builder.given(:bar)
        @builder.givens.should include(:bar)
      end

      it "is idempotent" do
        @builder.given(:bar)
        @builder.given(:baz)
        @builder.givens.should include(:bar)
        @builder.givens.should include(:baz)
      end

      it "returns self" do
        @builder.given(:bar).should be_a(EntropyTestClass::Builder)
      end

      it "fails if variables aren't variables on the estimator" do
        pending "slow - necessary?"
        lambda { @builder.given(:baz) }.should raise_error(ArgumentError)
      end
    end

    describe "#evaluate" do
      context "marginal entropy" do
        it "gets entropy of event" do
          event = double('EntropyEventDist')
          @instance.distributions.stub(:[]).with(:foo).and_return(event)
          event.should_receive(:entropy).and_return 0.5

          EntropyTestClass::Builder.new(@instance,[:foo]).evaluate
        end

        it "returns H event (if no givens)" do
          event = double("EntropyEventDist", :entropy => 0.5)
          @instance.distributions.stub(:[]).with(:foo).and_return(event)

          EntropyTestClass::Builder.new(@instance,[:foo]).evaluate.should == 0.5
        end
      end

      context "conditional entropy" do
        it "gets joint entropy of event + givens" do
          joint = double("EntropyJointDist", :entropy => 0.5)
          given = double("EntropyGivenDist", :entropy => 0.25)
          @instance.distributions.stub(:[]).with(:foo, :bar).and_return(joint)
          @instance.distributions.stub(:[]).with(:bar).and_return(given)
          joint.should_receive(:entropy).and_return 0.5

          EntropyTestClass::Builder.new(@instance,[:foo]).given(:bar).evaluate
        end

        it "gets entropy of givens" do
          joint = double("EntropyJointDist", :entropy => 0.5)
          given = double("EntropyGivenDist", :entropy => 0.25)
          @instance.distributions.stub(:[]).with(:foo, :bar).and_return(joint)
          @instance.distributions.stub(:[]).with(:bar).and_return(given)
          given.should_receive(:entropy).and_return 0.25

          EntropyTestClass::Builder.new(@instance,[:foo]).given(:bar).evaluate
        end

        it "returns H joint - givens (if givens)" do
          joint = double("EntropyJointDist", :entropy => 0.5)
          given = double("EntropyGivenDist", :entropy => 0.1)
          @instance.distributions.stub(:[]).with(:foo, :bar).and_return(joint)
          @instance.distributions.stub(:[]).with(:bar).and_return(given)

          EntropyTestClass::Builder.new(@instance,[:foo]).given(:bar).evaluate.should == 0.4
        end
      end
    end
  end
end
