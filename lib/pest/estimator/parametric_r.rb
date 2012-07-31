require 'narray'

module Pest::Estimator
  class ParametricR
    def self.skew_normal(data)
      new(data, :model => :skew_normal)
    end

    def self.skew_t(data)
      new(data, :model => :skew_t)
    end

    include Pest::Estimator
    include Pest::Function::Probability
    include Pest::Function::Entropy

    attr_reader :model

    def initialize(data, attrs={})
      model = attrs[:model] || :skew_normal
      raise ArgumentError unless data.kind_of?(Pest::DataSet::R)
      raise ArgumentError unless [:skew_normal, :skew_t].include? model

      super(data)
      @model = model
    end

    def distribution_class
      Distribution
    end

    class Distribution
      require 'r_helpers'
      include Pest::Estimator::Distribution
      include RHelpers

      def initialize(estimator, variables)
        super(estimator, variables)

        script = <<-R
          library('sn', quietly=TRUE)
          m#{model}.mle(y=dataset[,#{r_variables(variables)}])
        R
        @parameters = estimator.data.rserve.eval(script).to_ruby["dp"]
      end

      def probability(data)
        data = Pest::DataSet::R.from_hash(data.to_hash) unless data.kind_of?(Pest::DataSet::R)
        script = <<-R
          library('sn', quietly=TRUE)
          dm#{model}(dataset[,#{r_variables(variables)}], xi=as.vector(params.xi), Omega=params.omega, alpha=as.vector(params.alpha))
        R
        data.rserve.assign('params.xi', xi)
        data.rserve.assign('params.omega', omega)
        data.rserve.assign('params.alpha', alpha)
        NArray[ data.rserve.eval(script).to_ruby ]
      end

      def entropy
        data = @estimator.data
        script = <<-R
          library('skewtools', quietly=TRUE)
          entropy.skew(dataset[,#{r_variables(variables)}], family="#{model.upcase}")
        R
        data.rserve.eval(script).to_ruby["H"]
      end

      private

      def xi
        @parameters['beta']
      end

      def omega
        @parameters['Omega']
      end

      def alpha
        @parameters['alpha']
      end

      def model
        case @estimator.model
        when :skew_normal then :sn
        when :skew_t then :st
      end
    end
  end
end
end
