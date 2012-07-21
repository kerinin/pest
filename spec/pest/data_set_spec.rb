require 'spec_helper'

class DataSetTestClass
  include Pest::DataSet
end

describe Pest::DataSet do
  before(:each) do
    @class = DataSetTestClass
    @instance = DataSetTestClass.new
  end

  describe Pest::DataSet::ClassMethods do
    describe "::from" do
      before(:each) do
        @class.stub(:translators).and_return(Hash => :from_hash)
        @class.stub(:from_hash).and_return(Hash.new)
        @class.stub(:send).with(:from_hash, kind_of(Hash)).and_return(true)

        @hash_source = {:foo => :bar}
        @unknown_source = double("Unknown Instance")
        @unknown_source.stub(:to_hash).and_return(@hash_source)
      end

      it "checks for translator with passed class" do
        @class.translators.should_receive(:[]).with(Hash).and_return(:from_hash)
        @class.from({:foo => :bar})
      end

      it "passes to translator if found" do
        @class.should_receive(:send).with(:from_hash, @hash_source)
        @class.from(@hash_source)
      end

      it "calls to_hash if unrecognized class" do
        @unknown_source.should_receive(:to_hash)
        @class.from(@unknown_source)
      end

      it "passes to translator after converting to hash" do
        @class.should_receive(:send).with(:from_hash, @hash_source)
        @class.from(@unknown_source)
      end
    end

    describe "::translators" do
      # Required
      it "raises an error if called from module" do
        lambda { @class.translators }.should raise_error(NotImplementedError)
      end
    end
    
    describe "::from_file" do
      # Required
      it "raises an error if called from module" do
        lambda { @class.from_file }.should raise_error(NotImplementedError)
      end
    end
    
    describe "::from_hash" do
      # Required
      it "raises an error if called from module" do
        lambda { @class.from_hash }.should raise_error(NotImplementedError)
      end
    end
  end

  describe "#variables" do
    it "defaults to an empty set" do
      @instance.variables.should == Set.new
    end
  end

  describe "#to_hash" do
    # Required
    it "raises an error if called from module" do
      lambda { @instance.to_hash }.should raise_error(NotImplementedError)
    end
  end

  describe "#save" do
    # Required
    it "raises an error if called from module" do
      lambda { @instance.save }.should raise_error(NotImplementedError)
    end
  end

  describe "#length" do
    # Required
    it "raises an error if called from module" do
      lambda { @instance.length }.should raise_error(NotImplementedError)
    end
  end

  describe "#[]" do
    context "with a single argument" do
      it "returns NotImplementedError" do
        expect { @instance[1] }.to raise_error(NotImplementedError)
      end
    end

    context "with multiple arguments" do
      it "returns NotImplementedError" do
        expect { @instance[1,5] }.to raise_error(NotImplementedError)
      end
    end
  end

  describe "#+" do
    it "returns NotImplementedError" do
      expect { @instance + @instance }.to raise_error(NotImplementedError)
    end
  end

  it "inherits from Enumerable" do
    @instance.should be_a(Enumerable)
  end

  describe "#each" do
    it "yields vectors" do
      expect { @instance.each {} }.to raise_error(NotImplementedError)
    end
  end

  describe "#merge!" do
    it "returns NotImplementedError" do
      expect { @instance.merge(@instance) }.to raise_error(NotImplementedError)
    end
  end
end
