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
      @matrix = NArray.to_na [[4,5,6],[1,2,3]]
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
      @instance.variable_array.map(&:name).should == ["bar", "foo"]
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
      @instance = @class.from_hash :foo => [1,2,3], :bar => [4,5,6]
    end

    it "sets keys" do
      @instance.to_hash.keys.should == @instance.variables.values
    end

    it "sets values" do
      @instance.to_hash.values.should == [[4,5,6],[1,2,3]]
    end
  end

  describe "#data_vectors" do
    before(:each) do
      @instance = @class.from_hash :foo => [1,2,3], :bar => [4,5,6]
    end

    it "returns an enumerable" do
      @instance.data_vectors.should be_a(Enumerable)
    end

    it "slices" do
      # NOTE: This is returning an array - probably could be more efficient
      @instance.data_vectors.first.should == [4,1]
    end
  end

  describe "#save" do
    before(:each) do
      @file = Tempfile.new('test')
      @instance = @class.from_hash :foo => [1,2,3], :bar => [4,5,6]
    end

    it "saves to file" do
      @instance.save(@file)
      @class.from_file(@file.path).should == @instance
    end

    it "saves to tmp dir if no filename specified" do
      Tempfile.should_receive(:new).and_return(@file)
      @instance.save
      @class.from_file(@file.path).should == @instance
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
        pending "data refactor"
        @all[3].should == @index_subset
      end
    end

    context "with a range argument" do
      it "returns a copy with the vectors specified by the range" do
        pending "data refactor"
        @all[0..1].should == @range_subset
      end
    end

    context "with multiple arguments" do
      it "returns a copy with the union of the passed arguments" do
        pending "data refactor"
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
      pending "data refactor"
      (@set_1 + @set_2).should == @all
    end
  end
end
