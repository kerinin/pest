require 'rserve'

class Pest::DataSet::R
  include Pest::DataSet

  def self.translators
    super.merge({
      File => :from_csv
    })
  end

  def self.from_hash(hash)
    hash_dataset = 
    converted = outfile do |csv|
      Pest::DataSet::Hash.new(hash).each do |row|
        csv << row
      end
    end

    new(
      ::Hash[ hash.keys.each_with_index.map {|var, i| [var, i]} ],
      converted
    )
  end

  def self.from_csv(file, args={})
    args = {:col_sep => "\t", :headers => true, :converters => :all}.merge args

    line = CSV.open(file, args).readline
    converted = outfile do |csv|
      CSV.foreach(file, args) do |row|
        csv << row
        csv.flush
      end
    end

    data_set = new(
      ::Hash[ line.to_hash.keys.each_with_index.map {|var, i| [var, i]} ],
      converted
    )
  end

  def self.outfile(&block)
    file = Tempfile.new('r_data')
    CSV.open(file, 'w', :col_sep => "\t") do |csv|
      yield csv
    end
    file
  end

  attr_accessor :variable_hash, :file

  def initialize(variable_hash={}, file=nil)
    @variable_hash = variable_hash
    @file = file
  end

  def to_hash
    hash = {}

    variable_hash.to_a.sort_by do |var_pair|
      var_pair[1]
    end.each do |var, index|
      hash[var] = rserve.eval("as.matrix(dataset)[,#{index+1}]").to_ruby
    end

    hash
  end

  def variables
    variable_hash.keys.to_set
  end

  def length
    rserve.eval("nrow(dataset)").as_integer
  end

  def to_a
    rserve.eval("dataset").to_ruby.to_a
  end

  def [](*args)
    unless args.any?
      raise ArgumentError, "Indices not specified"
    end

    new_file = Tempfile.new('r_data')
    script = <<R
args <- c(#{r_slice(args)})
subset.data <- dataset[args,]
write.table(subset.data, '#{new_file.path}', sep = '\t', row.names=F, col.names=F)
R
    rserve.void_eval(script)

    self.class.new(
      variable_hash,
      new_file
    )
  end

  def +(other)
    unless other.variables == variables
      raise ArgumentError, "DataSets have different variables"
    end

    file_to_r(other.file, :assign_to => "other.dataset", :column_names => other.variable_hash.keys)
    new_file = Tempfile.new('r_data')
    script = <<R
union.data <- rbind(dataset, other.dataset)
write.table(union.data, '#{new_file.path}', sep = '\t', row.names=F, col.names=F)
R
    rserve.void_eval(script)

    self.class.new(
      variable_hash,
      new_file
    )
  end

  def pick(*args)
    unless args.any?
      raise ArgumentError, "You didn't specify any variables to pick"
    end

    new_file = Tempfile.new('r_data')
    script = <<R
picked.data <- dataset[,#{r_variables(args)}]
write.table(picked.data, '#{new_file.path}', sep = '\t', row.names=F, col.names=F)
R
    rserve.void_eval(script)

    self.class.new(
      ::Hash[ args.each_with_index.map {|v,i| [v,i]} ],
      new_file
    )
  end

  def each(&block)
    (1..length).to_a.each do |i|
      yield rserve.eval("dataset[#{i},]").to_ruby.to_a
    end
  end

  def dup
    self.class.new( variable_hash.dup, file )
  end

  def merge!(other)
    other = self.class.from_hash(other) if other.kind_of?(::Hash)
    other = self.class.from_hash(other.to_hash) unless other.kind_of?(NArray)
    raise ArgumentError, "Lengths must be the same" if other.length != length

    file_to_r(other.file, :assign_to => "other.dataset", :column_names => other.variable_hash.keys)

    (other.variables - variables).each do |var|
      variable_hash[var] = variable_hash.length
    end

    script = <<R
merged.data <- merge(dataset, other.dataset, all.y=T)
old_names <- setdiff(names(dataset),names(other.dataset))
merged.data[,old_names] <- dataset[,old_names]
write.table(merged.data, '#{file.path}', sep = '\t', row.names=F, col.names=F)
R
    rserve.void_eval(script)
    file_to_r(file, :column_names => variable_hash.keys)

    self
  end

  private

  def rserve
    unless @connection
      @connection = Rserve::Connection.new
      file_to_r(file, :column_names => variable_hash.keys)
    end

    @connection
  end

  def file_to_r(file, attrs={})
    attrs = {:assign_to => "dataset"}.merge attrs
    script = 
<<R
#{attrs[:assign_to]} <- read.table(
  "#{file.path}",
  header=FALSE,
  col.name=#{r_variables(attrs[:column_names])},
  sep="\t"
)
R
    rserve.eval script
  end

  def r_slice(slice)
    if slice.kind_of? Integer
      (slice+1).to_s
    elsif slice.kind_of? Enumerable
      "c(#{slice.map {|i| r_slice(i) }.join(',')})"
    elsif slice.kind_of? Range
      "#{slice.begin+1}:#{slice.end+1}"
    end
  end

  def r_variables(variables=variables)
    if !variables.kind_of?(Enumerable)
      "'#{variables}'"
    elsif variables.length == 1
      "'#{variables.first}'"
    else
      "c(#{variables.map {|v| "'#{v}'"}.join(',')})"
    end
  end
end
