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
    subset.variables =  picked_variables
    subset.data = self.data[true, picked_indices]
    subset
  end
end
