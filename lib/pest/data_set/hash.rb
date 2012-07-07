class Pest::DataSet::Hash
  include Pest::DataSet

  def self.translators
    {
      String  => :from_file,
      Symbol  => :from_file
    }
  end

  def self.from_hash(hash)
    new hash
  end

  attr_reader :hash

  def initialize(hash={})
    @hash = hash
  end

  def variables
    hash.keys.to_set
  end

  def to_hash
    hash
  end

  def to_a
    hash.values
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
        subset.hash[var] = Array(hash[var][arg])
      end
      subset
    end.inject(:+)
  end

  def ==(other)
    other.kind_of?( Hash ) and hash == other.hash
  end
  alias :eql? :==

  def +(other)
    unless other.variables == variables
      raise ArgumentError, "DataSets have different variables"
    end

    self.class.new hash.merge(other.hash) {|k,o,n| Array(o) + Array(n)}
  end

  def pick(*args)
    unless args.any?
      raise ArgumentError, "You didn't specify any variables to pick"
    end

    self.class.new(
      ::Hash[ args.map do |key|
        # raise ArgumentError, "Dataset doesn't include '#{key}'" unless hash.has_key?(key)
        [key, hash[key]]
      end ]
    )
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
    other = self.class.from_hash(other.to_hash) unless other.kind_of?(Hash)
    raise ArgumentError, "Lengths must be the same" if other.length != length

    @variables += other.variables
    hash.merge! other.hash

    self
  end
end
