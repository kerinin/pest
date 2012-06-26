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

  def to_variable(arg)
    variable = case arg.class.name
    when 'Pest::Variable'
      arg
    when 'String', 'Symbol'
      variables[arg] || Pest::Variable.new(:name => arg)
    end
    raise ArgumentError unless variables.values.include?(variable)
    variable
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
        if args.any? {|arg| arg.kind_of?(::Set)}
          args.inject(::Set.new) {|set, el| set + el.to_set}
        else
          args.flatten.to_set
        end
      elsif args.kind_of? ::Set
        args
      else
        Array(args).to_set
      end
      set.map! {|arg| @estimator.to_variable(arg) }
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
