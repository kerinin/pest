require 'spec_helper'

class ProbabilityTestClass
  include Pest::Estimator
  include Pest::Function::Probability
end

describe Pest::Function::Probability do
  before(:each) do
    @instance = ProbabilityTestClass.new
    @instance.stub(:data).and_return(Pest::DataSet::Hash.from_hash(:foo => [1], :bar => [1]))
    @instance.stub(:variables).and_return([:foo,:bar].to_set)
  end

  describe "#batch_probability" do
    it "returns a Builder" do
      @instance.batch_probability.should be_a(Pest::Function::Probability::BatchBuilder)
    end

    it "is aliased as batch_p" do
      @instance.batch_p.should be_a(Pest::Function::Probability::BatchBuilder)
    end
  end

  describe "#probability" do
    it "returns a Builder" do
      @instance.probability.should be_a(Pest::Function::Probability::Builder)
    end

    it "is aliased as p" do
      @instance.p.should be_a(Pest::Function::Probability::Builder)
    end
  end

  describe Pest::Function::Probability::BatchBuilder do
    describe "::new" do
      before(:each) { @builder = ProbabilityTestClass::BatchBuilder.new(@instance, [:foo, :bar]) }

      it "sets estimator" do
        @builder.estimator.should == @instance
      end

      it "sets event" do
        @builder.event.should == [:foo, :bar].to_set
      end

      it "fails if variable undefined for estimator" do
        pending "slow - necessary?"
        lambda { ProbabilityTestClass::BatchBuilder.new(@instance, [:foo, :baz]) }.should raise_error(ArgumentError)
      end

      it "constructs dataset if passed hash"
    end

    describe "#given" do
      before(:each) { @builder = ProbabilityTestClass::BatchBuilder.new(@instance, [:foo]) }

      it "sets givens" do
        @builder.given(:bar)
        @builder.givens.should include(:bar)
      end

      it "returns self" do
        @builder.given(:bar).should be_a(ProbabilityTestClass::BatchBuilder)
      end

      it "fails if variables aren't variables on the estimator" do
        pending "slow - necessary?"
        lambda { @builder.given(:baz) }.should raise_error(ArgumentError)
      end

      it "adds to dataset if passed hash"

      it "raises error if passed hash with existing (non hash) dataset"
    end

    describe "#in" do
      it "sets data source" do
        data_set = double('DataSet')
        ProbabilityTestClass::BatchBuilder.new(@instance,[:foo]).in(data_set).data_source.should == data_set
      end

      it "raises error if existing data source"
    end

    describe "#evaluate" do
      it "generates dataset if not specified"

      it "gets probability of event" do
        event = double('EventDist')
        @instance.distributions.stub(:[]).with(:foo).and_return(event)
        event.should_receive(:probability).and_return NArray[0.5]

        ProbabilityTestClass::BatchBuilder.new(@instance,[:foo]).evaluate
      end

      it "gets probability of givens" do
        event = double('EventDist')
        given = double('GivenDist')
        @instance.distributions.stub(:[]).with(:foo, :bar).and_return(event)
        @instance.distributions.stub(:[]).with(:bar).and_return(given)
        event.stub(:probability).and_return NArray[0.5]
        given.should_receive(:probability).and_return NArray[0.5]

        ProbabilityTestClass::BatchBuilder.new(@instance,[:foo]).given(:bar).evaluate
      end

      it "returns Pr event / givens (if givens)" do
        event = double('EventDist')
        given = double('GivenDist')
        @instance.distributions.stub(:[]).with(:foo, :bar).and_return(event)
        @instance.distributions.stub(:[]).with(:bar).and_return(given)
        event.stub(:probability).and_return NArray[0.5]
        given.stub(:probability).and_return NArray[0.5]

        ProbabilityTestClass::BatchBuilder.new(@instance,[:foo]).given(:bar).evaluate.should == [1.0]
      end

      it "returns Pr event (if no givens)" do
        event = double('EventDist')
        @instance.distributions.stub(:[]).with(:foo).and_return(event)
        event.stub(:probability).and_return NArray[0.5]

        ProbabilityTestClass::BatchBuilder.new(@instance,[:foo]).evaluate.should == [0.5]
      end
    end
  end

  describe Pest::Function::Probability::Builder do
    describe "::new" do
      before(:each) { @builder = ProbabilityTestClass::Builder.new(@instance, [:foo, :bar]) }

      it "sets estimator" do
        @builder.estimator.should == @instance
      end

      it "sets event" do
        pending "do you need this?"
        @builder.event.should == [:foo, :bar].to_set
      end

      it "fails if variable undefined for estimator" do
        pending "do you need this?"
        lambda { ProbabilityTestClass::Builder.new(@instance, [:foo, :baz]) }.should raise_error(ArgumentError)
      end
    end

    describe "#given" do
      before(:each) { @builder = ProbabilityTestClass::Builder.new(@instance, {:foo => 1}) }

      it "sets givens" do
        @builder.given(:bar => 2)
        @builder.givens.should == {:bar => 2}
      end

      it "returns self" do
        @builder.given(:bar => 2).should be_a(ProbabilityTestClass::Builder)
      end

      it "fails if variables aren't variables on the estimator" do
        pending "slow - necessary?"
        lambda { @builder.given(:baz => 3) }.should raise_error(ArgumentError)
      end

      it "adds to dataset if passed hash" do
        @builder.given(:foo => 2)
        @builder.given(:foo => 3, :bar => 4)
        @builder.givens.should == {:foo => 3, :bar => 4}
      end
    end

    describe "#evaluate" do
      it "gets probability of event" do
        pending "is this really worth testing?"
      end

      it "gets probability of givens" do
        pending "is this really worth testing?"
      end

      it "returns Pr event / givens (if givens)" do
        pending "is this really worth testing?"
      end

      it "returns Pr event (if no givens)" do
        pending "is this really worth testing?"
      end
    end
  end
end
