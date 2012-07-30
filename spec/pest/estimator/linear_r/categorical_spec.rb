require 'spec_helper'
describe Pest::Estimator::LinearR::Categorical do
  before(:each) do
    @class = Pest::Estimator::LinearR::Categorical
    @data = Pest::DataSet::R.from_hash :foo => [1,1,2,3], :bar => [1,1,1,1]
    @test = Pest::DataSet::R.from_hash :foo => [1,2,4], :bar => [1,1,1]
    @instance = @class.new @data
  end

  it("inherits from estimator")                 { @instance.should be_a(Pest::Estimator) }
  it("generates marginal probabilities")        { estimator.p(:bar => 1).should == 1.0 }
  it("generates joint probability")             { estimator.p(:foo => 2, :bar => 1).should == 0.25 }
  it("generates conditional probability")       { estimator.p(:foo => 2).given(:bar => 1).should == 0.25 }
  it("generates marginal batch_probabilities")  { estimator.batch_p(:bar).in(@test).should == [1.0, 1.0, 1.0] }
  it("generates joint batch_probability")       { estimator.batch_p(:foo, :bar).in(@test).should == [0.5, 0.25, 0] }
  it("generates conditional batch_probability") { estimator.batch_p(:foo).given(:bar).in(@test).should == [0.5, 0.25, 0] }

  describe "::new" do
    it("sets data")                             { @class.new(@data).data.should == @data }
    it("requires data")                         { expect { @class.new }.to raise_error(ArgumentError) }
    it("sets admissible model")                 { @class.new(@data, :model => 'logit').model.should == 'logit' }
    it("complains about inadmissible models")   { expect { @class.new(@data, :model => 'ls') }.to raise_error(ArgumentError) }
  end

  describe Pest::Estimator::LinearR::Categorical::Distribution do
    before(:each) do
      @dist = @instance.distributions[*@data.variables]
    end

    describe "#probability" do
      it("returns an array")                    { @dist.probability(@test).should be_a(Array) }
      it("calculates probability")              { @dist.probability(@test).to_a.should == [0.5] }
    end
    
    describe "#entropy" do
      it("returns a Float")                     { @dist.entropy.should be_a(Float) }

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
