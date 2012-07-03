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
    data_set = new
    data_set.data = NMatrix.to_na(hash.values)
    hash.keys.each do |key|
      variable = key.kind_of?(Pest::Variable) ? key : Pest::Variable.new(:name => key)
      data_set.variables[variable.name] = variable
    end
    data_set
  end

  def self.from_file(file)
    from_csv(file)
  end

  def self.from_csv(file, args={})
    args = {:col_sep => "\t", :headers => true, :converters => :all}.merge args
    csv_data = CSV.read(file, args).map(&:to_hash)

    data_set = new
    data_set.data = NMatrix.to_na(csv_data.map(&:values)).transpose
    csv_data.first.keys.each do |key|
      # variable = key.kind_of?(Pest::Variable) ? key : Pest::Variable.new(:name => key)
      variable = Pest::Variable.deserialize(key) || Pest::Variable.new(:name => key)
      data_set.variables[variable.name] = variable
    end
    data_set
  end

  def to_hash
    hash = {}
    variables.values.each_index do |i|
      hash[variables.values[i]] = data[true,i].to_a[0]
    end
    hash
  end

  def length
    data.shape[0]
  end

  # Return a subset of the data with the same variables,
  # but only the vectors specified by i
  #
  def [](*args)
    unless args.any?
      raise ArgumentError, "Indices not specified"
    end

    args.map do |arg|
      subset = self.class.new
      subset.variables = self.variables
      subset.data = self.data[arg,true]
      subset
    end.inject(:+)
  end


  # Return the union of self and other
  #
  def +(other)
    unless other.variables == variables
      raise ArgumentError, "DataSets have different variables"
    end

    union = self.class.new
    union.variables = variables
    union.data = NMatrix[*(data.transpose.to_a + other.data.transpose.to_a)].transpose
    union
  end

  # Return a subset of the data with the same vectors, but only
  # the variables specified in args
  #
  def pick(*args)
    unless args.any?
      raise ArgumentError, "You didn't specify any variables to pick"
    end

    picked_variables = args.map do |arg|
      to_variable(arg, true)
    end
    picked_indices = picked_variables.map do |variable|
      self.variables.values.index(variable)
    end

    subset = self.class.new
    subset.variables = {}
    picked_variables.each {|v| subset.variables[v.name] = v}
    subset.data = self.data[true, picked_indices]
    subset
  end

  def each(&block)
    (0..length-1).to_a.each do |i|
      yield data[i,true].transpose.to_a.first
    end
  end

  def dup
    instance = self.class.new
    instance.variables = variables.dup
    instance.data = data.dup
    instance
  end

  def merge(other)
    dup.merge!(other)
  end

  def merge!(other)
    other = self.class.from_hash(other) if other.kind_of?(::Hash)
    raise ArgumentError, "Lengths must be the same" if other.length != length

    # Merge the variables.  Existing variables should be updated,
    # new variables should be appended to the hash in the same order
    # as they appear in other
    variables.merge! other.variables

    # Create the new data array, should be the size of the merged variables
    # by the number of vectors
    new_data = ::NArray.object(length, variables.length)

    # Copy over the data from self (as if we had extended self.data to the
    # right to allow for the new data)
    new_data[true, 0..data.shape[1]-1] = data

    # Merge in other's data, using the indices of other's variables as the
    # slice keys
    new_data[true, other.variables.values.map{|v| variables.values.index(v)}] = other.data

    self.data = new_data
    self
  end
end
