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

    def parse_args(args)
      set = if args.kind_of? Array
        args.flatten.to_set
      elsif args.kind_of? ::Set
        args
      else
        Array(args).to_set
      end
      unless( set - @estimator.variables ).empty?
        raise ArgumentError, "Variables not part of estimator"
      end
      set
    end

    def [](*args)
      set = parse_args(args)
      unless has_key? set
        self[set] = @estimator.distribution_class.new(@estimator, set)
      end
      super(set)
    end
  end
end
