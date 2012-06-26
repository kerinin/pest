require 'spec_helper'

class TestClass
  include Pest::Estimator
  def distribution_class; Distribution end
  class Distribution
    include Pest::Estimator::Distribution
  end
end

describe Pest::Estimator do
  before(:each) do
    @data = Pest::DataSet::NArray.from_hash :foo => [1,1,2,3], :bar => [1,1,1,1]
    @class = TestClass
  end

  describe "::new" do
    it "accepts a dataset" do
      @class.new(@data).data.should == @data
    end
  end

  describe "#variables" do
    it "proxies data set" do
      @class.new(@data).variables.should == @data.variables
    end
  end

  describe "#estimates" do
    before(:each) do
      @v1 = Pest::Variable.new(:name => :foo)
      @v2 = Pest::Variable.new(:name => :bar)
      @v3 = Pest::Variable.new(:name => :baz)

      @instance = TestClass.new
      @instance.stub(:variables).and_return({:foo => @v1, :bar => @v2})
    end

    it "accepts a set of variables" do
      @instance.distributions[@v1, @v2].should be_a(Pest::Estimator::Distribution)
    end

    it "returns an estimator for the passed variables" do
      @instance.distributions[@v1, @v2].variables.should == [@v1, @v2].to_set
    end

    it "returns an estimator for the passed strings" do
      @instance.distributions[:foo, :bar].variables.should == [@v1, @v2].to_set
    end

    it "is variable order agnostic" do
      @instance.distributions[@v1, @v2].should == @instance.distributions[@v2, @v1]
    end

    it "fails if a set variable isn't defined" do
      lambda { @instance.distributions[@v1, @v3] }.should raise_error(ArgumentError)
    end
  end

  describe Pest::Estimator::Distribution do
    before(:each) do
      @class = TestClass::Distribution
      @estimator = TestClass.new
      @estimator.stub(:variables).and_return({:foo => @v1, :bar => @v2})
      @instance = @class.new(@estimator, @estimator.variables) 
    end

    describe "#batch_probability" do
      it "raises no implemented" do
        expect { @instance.batch_probability }.to raise_error(NotImplementedError)
      end
    end

    describe "#probability" do
      it "raises no implemented" do
        expect { @instance.probability }.to raise_error(NotImplementedError)
      end
    end
  end
end
