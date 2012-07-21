module Pest::DataSet
  def self.included(base)
    base.extend(ClassMethods)
  end

  include Enumerable

  attr_accessor :variables
  def variables
    @variables || Set.new
  end
  alias :v :variables

  def to_hash(*args)
    raise NotImplementedError
  end

  def save(*args)
    raise NotImplementedError
  end

  def destroy
    raise NotImplementedError
  end

  def length
    raise NotImplementedError
  end

  def ==(other)
    variables == other.variables and to_a == other.to_a
  end
  alias :eql? :==

  def [](*args)
    raise NotImplementedError
  end

  def except(start, finish)
    left = start > 0 ? self[0..start] : nil
    right = finish < length - 1 ? self[finish..-1] : nil
    case [left.nil?, right.nil?]
    when [true, false]
      right
    when [false, true]
      left
    when [false, false]
      right + left
    end
  end

  def +(other)
    raise NotImplementedError
  end

  def pick(*args)
    raise NotImplementedError
  end

  def each(&block)
    raise NotImplementedError
  end

  def merge!(other)
    raise NotImplementedError
  end

  def merge(other)
    dup.merge!(other)
  end

  module ClassMethods
    def from(data_source)
      # Try to translate the data source directly
      if translator_method = translators[data_source.class]
        send(translator_method, data_source)

      # Try to translate via hash
      else
        begin
          hash_data = data_source.to_hash
        rescue NoMethodError
          raise "Unrecognized data source type"
        end
        
        if hash_data and translators.has_key?(hash_data.class)
          from(data_source.to_hash)
        end
      end
    end

    def translators
      {
        Hash => :from_hash
      }
    end

    def from_file(*args)
      raise NotImplementedError
    end

    def from_hash(*args)
      raise NotImplementedError
    end
  end
end
