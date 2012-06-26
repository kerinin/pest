require 'spec_helper'
require 'narray'

describe Pest::DataSet::NArray do
  before(:each) do
    @v1 = Pest::Variable.new(:name => :foo)
    @v2 = Pest::Variable.new(:name => :bar)
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
      @class.from_hash({@v1 => [1,2,3], @v2 => [4,5,6]}).data.should == @matrix
    end

    it "sets variables" do
      @class.from_hash({@v1 => [1,2,3], @v2 => [4,5,6]}).variables.values.should == [@v1, @v2]
    end

    it "generates Pest::Variables if not passed" do
      @class.from_hash({:foo => [1,2,3]}).variables[:foo].should be_a(Pest::Variable)
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
      @instance.variables.values.map(&:name).should == ["foo", "bar"]
    end

    it "creates data from the rest" do
      @instance = @class.from_csv @file.path
      @instance.to_hash.should == {@instance.variables["foo"] => [1,1,1], @instance.variables["bar"] => [1,2,3]}
    end

    it "accepts a filename" do
      @instance = @class.from_csv @file.path
      @instance.to_hash.should == {@instance.variables["foo"] => [1,1,1], @instance.variables["bar"] => [1,2,3]}
    end

    it "accepts an IO" do
      @instance = @class.from_csv @file
      @instance.to_hash.should == {@instance.variables["foo"] => [1,1,1], @instance.variables["bar"] => [1,2,3]}
    end

    it "deserializes variables if found" do
      @file = Tempfile.new('test_csv')
      CSV.open(@file.path, 'w', :col_sep => "\t") do |csv|
        csv << [@v1,@v2].map(&:serialize)
        csv << [1,1]
        csv << [1,2]
        csv << [1,3]
      end

      @class.from_csv(@file).variables.should == {'foo' => @v1, 'bar' => @v2}
    end
  end

  describe "#to_hash" do
    before(:each) do
      @instance = @class.from_hash @v1 => [1,2,3], @v2 => [4,5,6]
    end

    it "sets keys" do
      @instance.to_hash.keys.should == @instance.variables.values
    end

    it "sets values" do
      @instance.to_hash.values.should == [[1,2,3],[4,5,6]]
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

  describe "#[]" do
    before(:each) do
      @all = @class.from_hash @v1 => [1,2,3,4], @v2 => [5,6,7,8]
      @range_subset = @class.from_hash @v1 => [1,2], @v2 => [5,6]
      @index_subset = @class.from_hash @v1 => [4], @v2 => [8]
      @union_subset = @class.from_hash @v1 => [4,1,2], @v2 => [8,5,6]
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
      @all = @class.from_hash @v1 => [1,2,4], @v2 => [5,6,8]
      @set_1 = @class.from_hash @v1 => [1,2], @v2 => [5,6]
      @set_2 = @class.from_hash @v1 => [4], @v2 => [8]
    end

    it "returns the union of self and other" do
      (@set_1 + @set_2).should == @all
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
end
