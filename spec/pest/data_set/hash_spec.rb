require 'spec_helper'

# NOTE: make sure you're clear on the relationship between variables,
# their names, and the keys used in @hash.  I think they're getting
# conflated

describe Pest::DataSet::Hash do
  before(:each) do
    @v1 = Pest::Variable.new(:name => :foo)
    @v2 = Pest::Variable.new(:name => :bar)
    @v3 = Pest::Variable.new(:name => :baz)
    @class = Pest::DataSet::Hash
  end

  describe "::translators" do
    it "maps String => from_file" do
      @class.translators[String].should == :from_file
    end

    it "maps Symbol => from_file" do
      @class.translators[Symbol].should == :from_file
    end
  end

  describe "::from_hash" do
    it "parses symbol keys into variables" do
      @instance = Pest::DataSet::Hash.from_hash(:foo => [1,2,3], :bar => [3,4,5])
      @instance.variables.keys.should == [:foo, :bar]
    end

    it "retains variable names if passed" do
      @instance = Pest::DataSet::Hash.from_hash(@v1 => [1,2,3], @v2 => [3,4,5])
      @instance.variables.keys.should == [:foo, :bar]
    end
    
    it "retains variables if passed" do
      @instance = Pest::DataSet::Hash.from_hash(@v1 => [1,2,3], @v2 => [3,4,5])
      @instance.variables.values.should == [@v1, @v2]
    end
  end

  before(:each) do
    @data = {:foo => [1,2,3], :bar => [3,4,5]}
    @instance = Pest::DataSet::Hash.from_hash(@data)
  end

  describe "#to_hash" do
    it "returns a hash" do
      @instance.to_hash.should == @data
    end
  end

  describe "#pick" do
    before(:each) do
      @instance = @class.from_hash @v1 => [1,2,3], @v2 => [4,5,6]
    end

    it "accepts a single symbol string" do
      @instance.pick(:foo).data.to_a.first.should == [1,2,3]
    end

    it "accepts a single variable" do
      @instance.pick(@v1).data.to_a.first.should == [1,2,3]
    end

    it "accepts multiple variables" do
      @instance.pick(:bar, :foo).data.to_a.should == [[4,5,6],[1,2,3]]
   end
  end

  describe "#length" do
    before(:each) do
      @data = {:foo => [1,2,3], :bar => [3,4,5]}
      @instance = Pest::DataSet::Hash.from_hash(@data)
    end

    it "delegates to hash" do
      @instance.length.should == 3
    end
  end

  describe "#each" do
    before(:each) do
      @instance = @class.from_hash @v1 => [1,2,3], @v2 => [4,5,6]
    end

    it "yields vectors" do
      block = double("block")
      block.should_receive(:yielding).with([1,4])
      block.should_receive(:yielding).with([2,5])
      block.should_receive(:yielding).with([3,6])
      @instance.each {|i| block.yielding(i)}
    end
  end

  describe "#map" do
    before(:each) do
      @instance = @class.from_hash @v1 => [1,2,3], @v2 => [4,5,6]
    end

    it "works" do
      @instance.map {|i| i}.should == [[1,4],[2,5],[3,6]]
    end
  end

  describe "#merge" do
    before(:each) do
      @other    = @class.from_hash @v1 => [10,11,12,13], @v3 => [1,2,3,4]
      @instance = @class.from_hash @v1 => [1,2,3,4], @v2 => [5,6,7,8]
    end

    it "accepts a dataset and returns dataset" do
      @instance.merge(@other).should be_a(@class)
    end

    it "accepts a hash and returns dataset" do
      @instance.merge(@v1 => [10,11,12,13], @v3 => [1,2,3,4]).should be_a(@class)
    end

    it "requires the dataset to have the same length" do
      expect { @instance.merge(@v1 => [1,2,3,4,5]) }.to raise_error(ArgumentError)
    end

    it "adds the passed variable to self" do
      @instance.merge(@other)
      @instance.variables.values.should include(@v3)
    end

    it "adds the passed data to self" do
      @instance.merge(@other)
      @instance.pick(@v3).to_a.flatten.should == [1,2,3,4]
    end

    it "over-writes variables in self with variables in other" do
      @instance.merge(@other)
      @instance.pick(@v1).to_a.flatten.should == [10,11,12,13]
    end
  end
end
