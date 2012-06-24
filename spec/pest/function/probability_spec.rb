require 'spec_helper'

class ProbabilityTestClass
  include Pest::Estimator
  include Pest::Function::Probability
end

describe Pest::Function::Probability do
  before(:each) do
    @v1 = Pest::Variable.new(:name => :foo)
    @v2 = Pest::Variable.new(:name => :bar)
    @v3 = Pest::Variable.new(:name => :baz)
    @instance = ProbabilityTestClass.new
    @instance.stub(:variables).and_return({:foo => @v1, :bar => @v2})
  end

  describe "#batch_probability" do
    it "returns a Builder" do
      @instance.batch_probability.should be_a(Pest::Function::Probability::BatchBuilder)
    end

    it "is aliased as batch_p" do
      @instance.batch_p.should be_a(Pest::Function::Probability::BatchBuilder)
    end
  end

  describe Pest::Function::Probability::BatchBuilder do
    describe "::new" do
      before(:each) { @builder = ProbabilityTestClass::BatchBuilder.new(@instance, [@v1, :bar]) }

      it "sets estimator" do
        @builder.estimator.should == @instance
      end

      it "sets event" do
        @builder.event.should == [@v1, @v2].to_set
      end

      it "fails if variable undefined for estimator" do
        lambda { ProbabilityTestClass::BatchBuilder.new(@instance, [@v1, @v3]) }.should raise_error(ArgumentError)
      end

      it "constructs dataset if passed hash"
    end

    describe "#given" do
      before(:each) { @builder = ProbabilityTestClass::BatchBuilder.new(@instance, [:foo]) }

      it "sets givens" do
        @builder.given(:bar)
        @builder.givens.should include(@v2)
      end

      it "returns self" do
        @builder.given(:bar).should be_a(ProbabilityTestClass::BatchBuilder)
      end

      it "fails if variables aren't variables on the estimator" do
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
        @instance.distributions.stub(:[]).with([@v1].to_set).and_return(event)
        event.should_receive(:batch_probability).and_return 0.5

        ProbabilityTestClass::BatchBuilder.new(@instance,[:foo]).evaluate
      end

      it "gets probability of givens" do
        event = double('EventDist')
        given = double('GivenDist')
        @instance.distributions.stub(:[]).with([@v1].to_set).and_return(event)
        @instance.distributions.stub(:[]).with([@v2].to_set).and_return(given)
        event.stub(:batch_probability).and_return 0.5
        given.should_receive(:batch_probability).and_return 0.5

        ProbabilityTestClass::BatchBuilder.new(@instance,[:foo]).given(:bar).evaluate
      end

      it "returns Pr event / givens (if givens)" do
        event = double('EventDist')
        given = double('GivenDist')
        @instance.distributions.stub(:[]).with([@v1].to_set).and_return(event)
        @instance.distributions.stub(:[]).with([@v2].to_set).and_return(given)
        event.stub(:batch_probability).and_return 0.5
        given.stub(:batch_probability).and_return 0.5

        ProbabilityTestClass::BatchBuilder.new(@instance,[:foo]).given(:bar).evaluate.should == 1.0
      end

      it "returns Pr event (if no givens)" do
        event = double('EventDist')
        @instance.distributions.stub(:[]).with([@v1].to_set).and_return(event)
        event.stub(:batch_probability).and_return 0.5

        ProbabilityTestClass::BatchBuilder.new(@instance,[:foo]).evaluate.should == 0.5
      end
    end
  end
end
