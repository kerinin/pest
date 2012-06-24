require 'spec_helper'

describe Pest::Estimator::Frequency do
  before(:each) do
    @class = Pest::Estimator::Frequency
    @v1 = Pest::Variable.new(:name => :foo)
    @v2 = Pest::Variable.new(:name => :bar)
    @data = Pest::DataSet::NArray.from_hash @v1 => [1,1,2,3], @v2 => [1,1,1,1]
    @test = Pest::DataSet::NArray.from_hash @v1 => [1,2,4], @v2 => [1,1,1]
    @instance = @class.new(@data)
  end

  it "inherits from set" do
    @instance.should be_a(Pest::Estimator)
  end

  it "generates marginal probabilities" do
    @instance.p(@v2).in(@test).should === NArray[[1.0, 1.0, 1.0]]
  end

  it "generates joint probability" do
    @instance.p(@v1, @v2).in(@test).should == NArray[[0.5, 0.25, 0]]
  end

  it "generates conditional probability" do
    @instance.p(@v1).given(@v2).in(@test).should == NArray[[0.5, 0.25, 0]]
  end

  describe Pest::Estimator::Frequency::Distribution do
    before(:each) do
      @dist = @instance.distributions[@data.variables.values.to_set]
    end

    describe "#cache_model" do
      it "determines vector frequency" do
        @dist.cache_model
        @dist.frequencies[[1,1]].should == 2
      end

      it "defaults to 0" do
        @dist.cache_model
        @dist.frequencies[[4,1]].should == 0
      end
    end

    describe "#probability" do
      it "returns an NArray" do
        @dist.probability(@test).should be_a(NArray)
      end

      it "calculates vector frequency / dataset length"  do
        @dist.probability(@test).should == NArray[[0.5,0.25,0]]        
      end
    end
    
    describe "#entropy" do
      it "returns a Float" do
        @dist.entropy.should be_a(Float)
      end

      it "calculates -sum(PlogP)" do
        # Outcomes = ([1,1]: 2, [2,1]: 1, [3,1]: 1)
        # P = (0.5, 0.25, 0.25)
        # logP = (-1, -2, -2) (log base 2 for bits)
        # -sum(PlogP) = (0.5, 0.5, 0.5).sum
        @dist.entropy.should == 1.5
      end
    end
  end
end
