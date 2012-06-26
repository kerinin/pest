class Pest::DataSet::Hash
  include Pest::DataSet

  def self.translators
    {
      String  => :from_file,
      Symbol  => :from_file
    }
  end

  def self.from_hash(hash)
    data_set = new
    hash.each_pair do |key, value|
      variable = key.kind_of?(Pest::Variable) ? key : Pest::Variable.new(:name => key)
      data_set.variables[variable.name] = variable
      data_set.hash[variable.name] = value
    end
    data_set
  end

  attr_reader :variables, :hash

  def initialize(*args)
    super *args
    @hash = {}
  end

  def data
    hash.values
  end

  def to_hash
    hash
  end

  def length
    @hash.values.first.length
  end

  def [](*args)
    unless args.any?
      raise ArgumentError, "Indices not specified"
    end

    args.map do |arg|
      subset = self.class.new
      subset.variables = self.variables
      variables.each do |var|
        subset.hash[var.name] = hash[var.name][arg]
      end
      subset
    end.inject(:+)
 
  end

  def +(other)
    unless other.variables == variables
      raise ArgumentError, "DataSets have different variables"
    end

    union = self.class.new
    union.variables = variables
    variables.each do |var|
      union.hash[var.name] = hash[var.name] + other.hash[var.name]
    end
    union
  end

  def pick(*args)
    unless args.any?
      raise ArgumentError, "You didn't specify any variables to pick"
    end

    picked_variables = args.map do |arg|
      to_variable(arg, true)
    end

    subset = self.class.new
    picked_variables.each do |var|
      subset.variables[var.name] = var
      subset.hash[var.name] = hash[var.name]
    end
    subset
  end

  def each(&block)
    (0..length-1).to_a.each do |i|
      yield variables.keys.map {|key| hash[key][i]}
    end
  end
end
