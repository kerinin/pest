require 'spec_helper'

shared_examples_for "a data set" do |described_class|
  # These translators should be implemented for all data sets to provide a means of
  # translating between any two data set types.
  #
  describe "::translators" do
    it "maps Pest::DataSet::Hash => from_hash" do
      described_class.translators[Pest::DataSet::Hash].should == :from_hash
    end
  end

  # All data sets should implement to_hash, same reason as above
  #
  describe "#to_hash" do
    before(:each) do
      @instance = described_class.from_hash :foo => [1,2,3], :bar => [4,5,6]
    end

    it "sets keys" do
      @instance.to_hash.keys.to_set.should == @instance.variables
    end

    it "sets values" do
      @instance.to_hash.values.should == [[1,2,3],[4,5,6]]
    end
  end

  describe "#to_a" do
    before(:each) do
      @instance = described_class.from_hash :foo => [1,2,3], :bar => [4,5,6]
    end

    it "returns data in variable-major form" do
      @instance.to_a.should == [[1,2,3],[4,5,6]]
    end
  end

  describe "#dup" do
    before(:each) do
      @instance = described_class.from_hash :foo => [1,2,3], :bar => [4,5,6]
    end

    it "returns an equivalent instance" do
      @instance.dup.should == @instance
    end
  end

  # Should return an instance of the data set with only the variables passed
  #
  describe "#pick" do
    before(:each) do
      @instance = described_class.from_hash :foo => [1,2,3], :bar => [4,5,6]
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

  # Should return an instance of the dataset with only the data points specified
  # in the slice
  #
  describe "#[]" do
    before(:each) do
      @all = described_class.from_hash :foo => [1,2,3,4], :bar => [5,6,7,8]
      @range_subset = described_class.from_hash :foo => [1,2], :bar => [5,6]
      @index_subset = described_class.from_hash :foo => [4], :bar => [8]
      @union_subset = described_class.from_hash :foo => [4,1,2], :bar => [8,5,6]
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

  # Should return an instance with the data in both self and other.
  # Assumes identical variables in both data sets (this is not intended to 
  # merge different variables, only vectors)
  #
  describe "#+" do
    before(:each) do
      @all = described_class.from_hash :foo => [1,2,4], :bar => [5,6,8]
      @set_1 = described_class.from_hash :foo => [1,2], :bar => [5,6]
      @set_2 = described_class.from_hash :foo => [4], :bar => [8]
      @result = @set_1 + @set_2
    end

    it "returns the union of self and other" do
      @result.should == @all
    end

    it "sets variables" do
      @result.variables.should == @all.variables
    end
  end

  # Should return the number of data points
  #
  describe "#length" do
    before(:each) do
      @data = {:foo => [1,2,3], :bar => [3,4,5]}
      @instance = Pest::DataSet::NArray.from_hash(@data)
    end

    it "delegates to hash" do
      @instance.length.should == 3
    end
  end

  # Iterate over each data point.  Should yield an array with length #length
  #
  describe "#each" do
    before(:each) do
      @instance = described_class.from_hash :foo => [1,2,3], :bar => [4,5,6]
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
      @instance = described_class.from_hash :foo => [1,2,3], :bar => [4,5,6]
    end

    it "works" do
      @instance.map {|i| i}.should == [[1,4],[2,5],[3,6]]
    end
  end

  # Similar to #+, but in this case we're combining variables.  Requires both
  # data sets to have the same number of data points.  If variables are shared
  # between the two data sets, the values in the passed data set will over-write
  # those in self.
  #
  describe "#merge!" do
    before(:each) do
      @other    = described_class.from_hash :foo => [10,11,12,13], :baz => [1,2,3,4]
      @instance = described_class.from_hash :foo => [1,2,3,4], :bar => [5,6,7,8]
    end

    it "accepts a dataset and returns dataset" do
      @instance.merge(@other).should be_a(described_class)
    end

    it "accepts a hash and returns dataset" do
      @instance.merge(:foo => [10,11,12,13], :baz => [1,2,3,4]).should be_a(described_class)
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

  describe "#merge" do
    before(:each) do
      @other    = @class.from_hash :foo => [10,11,12,13], :baz => [1,2,3,4]
      @instance = @class.from_hash :foo => [1,2,3,4], :bar => [5,6,7,8]
    end

    it "calls dup on self" do
      @instance.should_receive(:dup).and_return(@instance)
      @instance.merge @other
    end

    it "calls merge! on duplicate" do
      dup = @instance.dup
      @instance.stub(:dup).and_return( dup )
      dup.should_receive(:merge!).with(@other)

      @instance.merge @other
    end
  end

  describe "#==" do
    before(:each) do
      @instance = @class.from_hash :foo => [1,2,3,4], :bar => [5,6,7,8]
      @equal    = Pest::DataSet::Hash.from_hash :foo => [1,2,3,4], :bar => [5,6,7,8]
      @diff_var = @class.from_hash :foo => [1,2,3,4], :baz => [5,6,7,8]
      @diff_val = @class.from_hash :foo => [5,2,3,4], :bar => [5,6,7,8]
    end

    it "returns true with self" do
      @instance.eql?( @instance ).should be_true
    end

    it "returns true with different class" do
      @instance.eql?( @equal ).should be_true
    end

    it "requires the same variables" do
      @instance.eql?( @diff_var ).should be_false
    end

    it "requires the same values" do
      @instance.eql?( @diff_val ).should be_false
    end
  end

  it "Needs to handle #+, #merge, etc with datasets using same variables in different orders"
  it "needs to handle all that shit with datasets of different type (Hash.merge Narray)"
end
