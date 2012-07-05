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
    data_set.variables += hash.keys
    data_set.instance_variable_set(:@hash, hash)
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

    subset = self.class.new
    subset.variables += args
    args.each do |var|
      raise ArgumentError, "Dataset doesn't include '#{var}'" unless hash.has_key?(var)
      subset.hash[var] = hash[var]
    end
    subset
  end

  def each(&block)
    (0..length-1).to_a.each do |i| yield variables.map {|var| hash[var][i]} end
  end

  def dup
    instance = self.class.new
    instance.variables = variables.dup
    instance.instance_variable_set(:@hash, hash.dup)
    instance
  end

  def merge(other)
    dup.merge!(other)
  end

  def merge!(other)
    other = self.class.from_hash(other) if other.kind_of?(::Hash)
    raise ArgumentError, "Lengths must be the same" if other.length != length

    @variables += other.variables
    hash.merge! other.hash

    self
  end
end
