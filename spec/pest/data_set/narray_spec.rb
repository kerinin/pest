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

    it "sets variable_array" do
      @class.from_hash({:foo => [1,2,3], :bar => [4,5,6]}).variable_array.should == [:foo, :bar]
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

    it "creates variable_array" do
      @instance = @class.from_csv @file.path
      @instance.variable_array.should == ["foo", "bar"]
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

    it "uses order defined in variable_array" do
      @instance.to_hash.keys.should == [:foo, :bar]
      @instance.variable_array.reverse!
      @instance.to_hash.keys.should == [:bar, :foo]
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

    it "sets variable_array" do
      @instance.pick(:bar, :foo).variable_array.should == [:bar, :foo]
    end

    it "respects argument order" do
      @instance.pick(:foo, :bar).variable_array.should == [:foo, :bar]
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

      it "sets variable_array" do
        @result.variable_array.should == @all.variable_array
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

      it "sets variable_array" do
        @result.variable_array.should == @all.variable_array
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

      it "sets variable_array" do
        @result.variable_array.should == @all.variable_array
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

    it "sets variable_array" do
      @result.variable_array.should == @all.variable_array
    end
  end

  describe "#length" do
    before(:each) do
      @data = {:foo => [1,2,3], :bar => [3,4,5]}
      @instance = Pest::DataSet::NArray.from_hash(@data)
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

    it "sets variable_array" do
      @instance.merge(@other).variable_array.should == [:foo, :bar, :baz]
      @instance.variable_array.reverse!
      @instance.merge(@other).variable_array.should == [:bar, :foo, :baz]
    end

    it "adds the passed data to self" do
      @instance.merge(@other).pick(:baz).to_a.should == [1,2,3,4]
    end

    it "over-writes variables in self with variables in other" do
      @instance.merge(@other).pick(:foo).to_a.should == [10,11,12,13]
    end
  end

  it "Needs to handle #+, #merge, etc with datasets using same variables in different orders"
end
