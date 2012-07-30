require 'spec_helper'

describe Pest::Estimator::ParametricR do
  before(:each) do
    @class = Pest::Estimator::ParametricR
    @data = Pest::DataSet::R.from_hash :foo => [1,1,2,3], :bar => [1,1,1,2]
    @test = Pest::DataSet::R.from_hash :foo => [1,2,4], :bar => [1,1,2]
    @instance = @class.new @data
  end

  it("inherits from estimator")                 { @instance.should be_a(Pest::Estimator) }

  # These models involve numeric optimization, so we'll just check return types
  it("generates marginal probabilities")        { @instance.p(:foo => 1).evaluate.should be_a Float }
  it("generates joint probability")             { @instance.p(:foo => 2, :bar => 1).evaluate.should be_a Float }
  it("generates conditional probability")       { @instance.p(:foo => 2).given(:bar => 1).evaluate.should be_a Float }
  it("generates marginal batch_probabilities")  { @instance.batch_p(:bar).in(@test).evaluate.should be_a Array }
  it("generates joint batch_probability")       { @instance.batch_p(:foo, :bar).in(@test).evaluate.should be_a Array }
  it("generates conditional batch_probability") { @instance.batch_p(:foo).given(:bar).in(@test).evaluate.should be_a Array }

  describe "::new" do
    it("sets data")                             { @class.new(@data).data.should == @data }
    it("requires data")                         { expect { @class.new }.to raise_error(ArgumentError) }
    it("sets admissible model")                 { @class.new(@data, :model => :skew_normal).model.should == :skew_normal }
    it("complains about inadmissible models")   { expect { @class.new(@data, :model => 'ls') }.to raise_error(ArgumentError) }
  end

  describe Pest::Estimator::ParametricR::Distribution do
    before(:each) do
      @dist = @instance.distributions[*@data.variables]
    end

    describe "#probability" do
      it("returns an array")                    { @dist.probability(@test).should be_a(NArray) }
    end
    
    describe "#entropy" do
      # it("returns a Float")                     { @dist.entropy.should be_a(Float) }

      it "calculates -sum(PlogP)" do
        pending
        # Outcomes = ([1,1]: 2, [2,1]: 1, [3,1]: 1)
        # P = (0.5, 0.25, 0.25)
        # logP = (-1, -2, -2) (log base 2 for bits)
        # -sum(PlogP) = (0.5, 0.5, 0.5).sum
        @dist.entropy.should == 1.5
      end
    end
  end
end

