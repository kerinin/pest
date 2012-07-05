require 'narray'

class Pest::Estimator::Frequency
  include Pest::Estimator
  include Pest::Function::Probability
  include Pest::Function::Entropy

  def distribution_class
    Distribution
  end

  class Distribution
    include Pest::Estimator::Distribution
    
    OFFSET = 0
    attr_reader :frequencies, :checksum

    def cache_model
      if @frequencies.nil?
        @frequencies = Hash.new(0)
        @estimator.data.pick(*variable_array).each do |vector|
          # Make sure this vector is consistently ordered
          @frequencies[Array(vector)] += 1
        end
      end
    end

    def probability(data)
      cache_model

      array = NArray[ data.pick(*variable_array).map do |vector|
        @frequencies[Array(vector)].to_f
      end ]
      (OFFSET + array.reshape!(data.length)) / (OFFSET + @estimator.data.length)
    end

    def entropy
      cache_model

      probabilities = probability(unique_event_dataset)

      (-probabilities * NMath.log2(probabilities)).sum
    end

    private

    def unique_event_dataset
      vectors = NMatrix[@frequencies.keys]
      hash = {}
      variable_array.each_index do |i|
        # Extract a single variable from the array of vectors
        hash[variable_array[i]] = vectors[i,true,true].reshape!(vectors.shape[1]).to_a
      end
      Pest::DataSet::NArray.from_hash(hash)
    end

    def find_tempfile
      if path = Dir.glob("#{Dir::Tmpname.tmpdir}/*").select {|path| path =~ /#{@checksum}\.#{@variables.hash}/}.first
        File.open(path)
      end
    end
  end
end
