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
      @instance = TestClass.new
      @instance.stub(:variables).and_return([:foo, :bar].to_set)
    end

    it "accepts a set of variables" do
      @instance.distributions[:foo, :bar].should be_a(Pest::Estimator::Distribution)
    end

    it "returns an estimator for the passed variables" do
      @instance.distributions[:foo, :bar].variables.should == [:foo, :bar].to_set
    end

    it "returns an estimator for the passed strings" do
      @instance.distributions[:foo, :bar].variables.should == [:foo, :bar].to_set
    end

    it "is variable order agnostic" do
      @instance.distributions[:foo, :bar].should == @instance.distributions[:bar, :foo]
    end

    it "fails if a set variable isn't defined" do
      lambda { @instance.distributions[:foo, :baz] }.should raise_error(ArgumentError)
    end
  end

  describe Pest::Estimator::Distribution do
    before(:each) do
      @class = TestClass::Distribution
      @estimator = TestClass.new
      @estimator.stub(:variables).and_return({:foo => :foo, :bar => :bar})
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
