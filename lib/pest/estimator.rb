module Pest::Estimator 
  attr_accessor :data

  def initialize(data=nil)
    @data = data
  end

  def variables
    @data.nil? ? {} : @data.variables
  end

  def distributions
    @distributions ||= DistributionList.new(self)
  end

  module Distribution
    attr_reader :variables

    def initialize(estimator, variables)
      @estimator = estimator
      @variables = variables
    end

    def variable_array
      variables.to_a.sort
    end

    def batch_probability(*args)
      raise NotImplementedError
    end

    def probability(*args)
      raise NotImplementedError
    end
  end

  class DistributionList < Hash
    def initialize(estimator)
      @estimator = estimator
    end

    def [](*args)
      set = args.to_set
      # raise ArgumentError unless (set - @estimator.variables).empty?

      unless has_key? set
        self[set] = @estimator.distribution_class.new(@estimator, set)
      end
      super(set)
    end
  end
end
