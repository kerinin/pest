require 'spec_helper'
require 'pest/data_set/data_set'

describe Pest::DataSet::R do
  include_examples "a data set", Pest::DataSet::R

  before(:each) do
    @class = Pest::DataSet::R
  end

  describe "::translators" do
    it "maps File => from_csv" do
      @class.translators[File].should == :from_csv
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
      @instance = @class.from_csv(@file)
    end

    # NOTE: we'll assume that if a file is passed, it's in the same
    # formate as we generate when saving to file.
    it "sets file" do
      @instance.file.should be_a Tempfile
    end

    it "sets variables" do
      @instance.variables.should == ["foo", "bar"].to_set
    end
  end
end
