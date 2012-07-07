require 'spec_helper'

# NOTE: make sure you're clear on the relationship between variables,
# their names, and the keys used in @hash.  I think they're getting
# conflated

describe Pest::DataSet::Hash do
  before(:each) do
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
    it "gets variables from keys" do
      @instance = Pest::DataSet::Hash.from_hash(:foo => [1,2,3], :bar => [3,4,5])
      @instance.variables.should == [:foo, :bar].to_set
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
      @instance = @class.from_hash :foo => [1,2,3], :bar => [4,5,6]
    end

    it "accepts a single symbol string" do
      @instance.pick(:foo).to_a.first.should == [1,2,3]
    end

    it "accepts a single variable" do
      @instance.pick(:foo).to_a.first.should == [1,2,3]
    end

    it "accepts multiple variables" do
      @instance.pick(:bar, :foo).to_a.should == [[4,5,6],[1,2,3]]
   end
  end

  describe "#[]" do
    before(:each) do
      @all = @class.from_hash :foo => [1,2,3,4], :bar => [5,6,7,8]
      @range_subset = @class.from_hash :foo => [1,2], :bar => [5,6]
      @index_subset = @class.from_hash :foo => [4], :bar => [8]
      @union_subset = @class.from_hash :foo => [4,1,2], :bar => [8,5,6]
    end

    context "with integer argument" do
      before(:each) do
        @result = @all[3]
      end

      it "returns a copy with the vector at the passed index" do
        @result.should == @index_subset
      end

      it "sets variables" do
        @result.variables.should == @all.variables
      end
    end

    context "with a range argument" do
      before(:each) do
        @result = @all[0..1]
      end

      it "returns a copy with the vectors specified by the range" do
        @result.should == @range_subset
      end

      it "sets variables" do
        @result.variables.should == @all.variables
      end
    end

    context "with multiple arguments" do
      before(:each) do
        @result = @all[3,0..1]
      end

      it "returns a copy with the union of the passed arguments" do
        @result.should == @union_subset
      end

      it "sets variables" do
        @result.variables.should == @all.variables
      end
    end
  end

  describe "#+" do
    before(:each) do
      @all = @class.from_hash :foo => [1,2,4], :bar => [5,6,8]
      @set_1 = @class.from_hash :foo => [1,2], :bar => [5,6]
      @set_2 = @class.from_hash :foo => [4], :bar => [8]
      @result = @set_1 + @set_2
    end

    it "returns the union of self and other" do
      @result.should == @all
    end

    it "sets variables" do
      @result.variables.should == @all.variables
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
      @instance = @class.from_hash :foo => [1,2,3], :bar => [4,5,6]
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
      @instance = @class.from_hash :foo => [1,2,3], :bar => [4,5,6]
    end

    it "works" do
      @instance.map {|i| i}.should == [[1,4],[2,5],[3,6]]
    end
  end

  describe "#merge" do
    before(:each) do
      @other    = @class.from_hash :foo => [10,11,12,13], :baz => [1,2,3,4]
      @instance = @class.from_hash :foo => [1,2,3,4], :bar => [5,6,7,8]
    end

    it "accepts a dataset and returns dataset" do
      @instance.merge(@other).should be_a(@class)
    end

    it "accepts a hash and returns dataset" do
      @instance.merge(:foo => [10,11,12,13], :baz => [1,2,3,4]).should be_a(@class)
    end

    it "requires the dataset to have the same length" do
      expect { @instance.merge(:foo => [1,2,3,4,5]) }.to raise_error(ArgumentError)
    end

    it "adds the passed variable to self" do
      @instance.merge(@other).variables.should include(:baz)
    end

    it "adds the passed data to self" do
      @instance.merge(@other).pick(:baz).to_a.flatten.should == [1,2,3,4]
    end

    it "over-writes variables in self with variables in other" do
      @instance.merge(@other).pick(:foo).to_a.flatten.should == [10,11,12,13]
    end
  end
end
