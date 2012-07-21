require 'spec_helper'
require 'pest/data_set/data_set'
require 'narray'

describe Pest::DataSet::NArray do
  include_examples "a data set", Pest::DataSet::NArray

  before(:each) do
    @class = Pest::DataSet::NArray
  end

  describe "::translators" do
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
    it "creates a NArray" do
      @class.from_hash({:foo => [1,2,3], :bar => [4,5,6]}).to_a.should == [[1,2,3],[4,5,6]]
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
end

