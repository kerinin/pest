module Pest::DataSet
  def self.included(base)
    base.extend(ClassMethods)
  end

  def variables
    @variables ||= {}
  end

  def variable_array
    @variables.values.sort
  end

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
    variables.values.to_set == other.variables.values.to_set and
    data == other.data
  end
  alias :eql? :==

  def [](*args)
    raise NotImplementedError
  end

  def +(other)
    raise NotImplementedError
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

    def translators(*args)
      raise NotImplementedError
    end

    def from_file(*args)
      raise NotImplementedError
    end

    def from_hash(*args)
      raise NotImplementedError
    end
  end
end
