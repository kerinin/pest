module Pest::RegressionEstimator 
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

    def initialize(estimator, dependent_var, independent_vars)
      @estimator        = estimator
      @dependent_var    = dependent_var
      @independent_vars = independent_vars
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

    def [](dependent_var, *args)
      set = args.to_set
      # raise ArgumentError unless (set - @estimator.variables).empty?

      unless has_key?([dependent_var,set])
        self[[dependent_var,set]] = @estimator.distribution_class.new(@estimator, dependent_var, set)
      end
      super(set)
    end
  end
end
