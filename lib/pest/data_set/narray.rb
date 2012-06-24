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
    data_set.data = NMatrix.to_na(hash.keys.sort.map {|key| hash[key]}) # Ensure the matrix is sorted the same as the variables
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

  attr_accessor :variables, :data

  def initialize(variables = {}, data = nil)
    @variables = variables
    @data = data
  end

  def to_hash
    hash = {}
    variables.values.each_index do |i|
      hash[variables.values[i]] = data[true,i].to_a[0]
    end
    hash
  end

  # variables: an array of variables for which each vector should contain values
  # Order is retained in the returned value
  def data_vectors(variables=nil)
    VectorEnumerable.new(self, variables)
  end

  def length
    data.shape[0]
  end

  def save(file=nil)
    if file.kind_of?(File) or file.kind_of?(Tempfile)
     file_path = file.path
    elsif file.kind_of?(String)
     file_path = file
    else
     file_path = Tempfile.new(['pest_hash_dataset', '.tsv']).path
    end

    CSV.open(file_path, 'w', :col_sep => "\t") do |csv|
      csv << variables.values.map(&:serialize)
      data.transpose.to_a.each {|row| csv << row}
    end
  end

  def [](*args)
    args.map do |arg|
      if arg.kind_of?(Integer) or arg.kind_of?(Range)
        subset = self.clone
        subset.data = self.data_vectors[arg].transpose
        subset
      else
        raise ArgumentError
      end
    end.inject(:+)
  end

  def +(other)
    unless other.variables == variables
      raise ArgumentError, "DataSets have different variables"
    end

    union = self.class.new
    union.variables = variables
    union.data = NMatrix[*(data.transpose.to_a + other.data.transpose.to_a)].transpose
    union
  end

  class VectorEnumerable
    include Enumerable

    def initialize(data_set, variables = true)
      @data_set = data_set
      @variables = variables
      if @variables.kind_of?(Enumerable)
        @variables = variables.map {|v| @data_set.variable_array.index(v)}
      end
    end

    def [](i)
      @data_set.data[i,@variables].transpose
    end

    def each
      (0..@data_set.data.shape[0]-1).each do |i|
        yield Array(self[i]).first
      end
    end
  end
end
