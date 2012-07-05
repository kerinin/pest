require 'spec_helper'
require 'narray'

describe Pest::DataSet::NArray do
  before(:each) do
    @class = Pest::DataSet::NArray
  end

  describe "::translators" do
    it "maps Pest::DataSet::Hash => from_hash" do
      @class.translators[Pest::DataSet::Hash].should == :from_hash
    end

    it "maps File => from_file" do
      @class.translators[File].should == :from_file
    end

    it "maps String => from_file" do
      @class.translators[String].should == :from_file
    end
  end

  describe "::from_file" do
    it "delegates to from_csv" do
      @class.should_receive(:from_csv)
      @class.from_file('foo')
    end
  end

  describe "::from_hash" do
    before(:each) do
      @matrix = NArray.to_na [[1,2,3],[4,5,6]]
    end

    it "creates a NArray" do
      @class.from_hash({:foo => [1,2,3], :bar => [4,5,6]}).data.should == @matrix
    end

    it "sets variables" do
      @class.from_hash({:foo => [1,2,3], :bar => [4,5,6]}).variables.should == [:foo, :bar].to_set
    end
  end

  describe "::from_csv" do
    before(:each) do
      @file = Tempfile.new('test_csv')
      CSV.open(@file.path, 'w', :col_sep => "\t") do |csv|
        csv << ["foo", "bar"]
        csv << [1,1]
        csv << [1,2]
        csv << [1,3]
      end
    end

    it "creates variables from first line" do
      @instance = @class.from_csv @file.path
      @instance.variables.should == ["foo", "bar"].to_set
    end

    it "creates data from the rest" do
      @instance = @class.from_csv @file.path
      @instance.to_hash.should == {"foo" => [1,1,1], "bar" => [1,2,3]}
    end

    it "accepts a filename" do
      @instance = @class.from_csv @file.path
      @instance.to_hash.should == {"foo" => [1,1,1], "bar" => [1,2,3]}
    end

    it "accepts an IO" do
      @instance = @class.from_csv @file
      @instance.to_hash.should == {"foo" => [1,1,1], "bar" => [1,2,3]}
    end
  end

  describe "#to_hash" do
    before(:each) do
      @instance = @class.from_hash :foo => [1,2,3], :bar => [4,5,6]
    end

    it "sets keys" do
      @instance.to_hash.keys.to_set.should == @instance.variables
    end

    it "sets values" do
      @instance.to_hash.values.should == [[1,2,3],[4,5,6]]
    end
  end

  describe "#pick" do
    before(:each) do
      @instance = @class.from_hash :foo => [1,2,3], :bar => [4,5,6]
    end

    it "accepts a single symbol string" do
      @instance.pick(:foo).data.to_a.first.should == [1,2,3]
    end

    it "accepts a single variable" do
      @instance.pick(:foo).data.to_a.first.should == [1,2,3]
    end

    it "accepts multiple variables" do
      @instance.pick(:bar, :foo).data.to_a.should == [[4,5,6],[1,2,3]]
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
      it "returns a copy with the vector at the passed index" do
        @all[3].should == @index_subset
      end
    end

    context "with a range argument" do
      it "returns a copy with the vectors specified by the range" do
        @all[0..1].should == @range_subset
      end
    end

    context "with multiple arguments" do
      it "returns a copy with the union of the passed arguments" do
        @all[3,0..1].should == @union_subset
      end
    end
  end

  describe "#+" do
    before(:each) do
      @all = @class.from_hash :foo => [1,2,4], :bar => [5,6,8]
      @set_1 = @class.from_hash :foo => [1,2], :bar => [5,6]
      @set_2 = @class.from_hash :foo => [4], :bar => [8]
    end

    it "returns the union of self and other" do
      (@set_1 + @set_2).should == @all
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
      @instance.merge(@other).pick(:baz).to_a.should == [1,2,3,4]
    end

    it "over-writes variables in self with variables in other" do
      @instance.merge(@other).pick(:foo).to_a.should == [10,11,12,13]
    end
  end
end
