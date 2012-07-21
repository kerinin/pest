require 'spec_helper'
require 'pest/data_set/data_set'

# NOTE: make sure you're clear on the relationship between variables,
# their names, and the keys used in @hash.  I think they're getting
# conflated

describe Pest::DataSet::Hash do
  include_examples "a data set", Pest::DataSet::Hash

  before(:each) do
    @class = Pest::DataSet::Hash
    @data = {:foo => [1,2,3], :bar => [3,4,5]}
    @instance = Pest::DataSet::Hash.from_hash(@data)
  end

  describe "::translators" do
    it "maps String => from_file" do
      @class.translators[String].should == :from_file
    end

    it "maps Symbol => from_file" do
      @class.translators[Symbol].should == :from_file
    end
  end
end
