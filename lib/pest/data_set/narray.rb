require 'narray'

class Pest::DataSet::NArray
  include Pest::DataSet

  def self.translators
    {
      Hash    => :from_hash,
      File    => :from_file,
      String  => :from_file,
      Symbol  => :from_file
    }
  end

  def self.from_hash(hash)
    new(
      ::Hash[ hash.keys.each_with_index.map {|var, i| [var, i]} ],
      NMatrix.to_na(hash.values)
    )
  end

  def self.from_file(file)
    from_csv(file)
  end

  def self.from_csv(file, args={})
    args = {:col_sep => "\t", :headers => true, :converters => :all}.merge args
    csv_data = CSV.read(file, args).map(&:to_hash)

    data_set = new(
      ::Hash[ csv_data.first.keys.each_with_index.map {|var, i| [var, i]} ],
      NMatrix.to_na(csv_data.map(&:values)).transpose
    )
  end

  attr_accessor :variable_hash

  def initialize(variable_hash={}, data=NArray[])
    @variable_hash = variable_hash
    @data = data
  end

  def to_hash
    hash = {}

    variable_hash.to_a.sort_by do |var_pair| 
      var_pair[1]
    end.each do |var, index|
      hash[var] = data[true, index].to_a[0]
    end

    hash
  end

  def ==(other)
    # NOTE: This will return false if the data isn't the same, but we may want this to
    # return true if the data is the same for the variables we care about
    other.kind_of?(NArray) and variable_hash == other.variable_hash and data == other.data
  end
  alias :eql? :==

  def variables
    variable_hash.keys.to_set
  end

  def length
    data.shape[0]
  end

  def to_a
    data.to_a
  end

  # Return a subset of the data with the same variables,
  # but only the vectors specified by i
  #
  def [](*args)
    unless args.any?
      raise ArgumentError, "Indices not specified"
    end

    args.map do |arg|
      arg = Array(arg) unless arg.kind_of?(Enumerable) or arg.kind_of?(Range)
      self.class.new(
        variable_hash,
        data[arg,true]
      )
    end.inject(:+)
  end


  # Return the union of self and other
  #
  def +(other)
    unless other.variables == variables
      raise ArgumentError, "DataSets have different variables"
    end

    self.class.new(
      variable_hash,
      NMatrix[*(data.transpose.to_a + other.data.transpose.to_a)].transpose
    )
  end

  # Return a subset of the data with the same vectors, but only
  # the variables specified in args
  #
  def pick(*args)
    unless args.any?
      raise ArgumentError, "You didn't specify any variables to pick"
    end

    picked_indices = args.map {|v| variable_hash[v]}

    self.class.new(
      ::Hash[ args.each_with_index.map {|v,i| [v,i]} ],
      data[true, picked_indices]
    )
  end

  def each(&block)
    (0..length-1).to_a.each do |i|
      yield data[i,true].transpose.to_a.first
    end
  end

  def dup
    self.class.new( variable_hash.dup, data.dup )
  end

  def merge(other)
    dup.merge!(other)
  end

  def merge!(other)
    other = self.class.from_hash(other) if other.kind_of?(::Hash)
    other = self.class.from_hash(other.to_hash) unless other.kind_of?(NArray)
    raise ArgumentError, "Lengths must be the same" if other.length != length

    # Extend the variable hash with any new variables
    (other.variables - variables).each do |var|
      variable_hash[var] = variable_hash.length
    end

    # Create the new data array, should be the size of the merged variables
    # by the number of vectors
    new_data = ::NArray.object(length, variable_hash.length)

    # Copy over the data from self (as if we had extended self.data to the
    # right to allow for the new data)
    new_data[true, 0..data.shape[1]-1] = data

    # Merge in other's data, using the indices of other's variables as the
    # slice keys
    source_indices = other.variable_hash.values
    target_indices = other.variable_hash.keys.map {|key| variable_hash[key]}
    new_data[true, target_indices] = other.data[true, source_indices]

    self.data = new_data
    self
  end
end
