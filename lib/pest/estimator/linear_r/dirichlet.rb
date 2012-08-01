require 'narray'

module Pest::Estimator
  module LinearR
    class Dirichlet
      include Pest::RegressionEstimator
      include Pest::Function::Probability
      include Pest::Function::Entropy

      def initialize(data)
        raise ArgumentError unless data.kind_of?(Pest::DataSet::R)

        super(data)
      end

      def distribution_class
        Distribution
      end

      class Distribution
        require 'r_helpers'
        include Pest::RegressionEstimator::Distribution
        include RHelpers

        def initialize(estimator, dependent_var, independent_vars)
          super(estimator, dependent_var, independent_vars)

          script = <<-R
          library('DirichletReg', quietly=TRUE)
          DR_var <- DR_data(dataset[,'#{dependent_var}'])
          DirichletReg( DR_var ~ #{independent_vars.join("*")}, dataset)
          R
          @parameters = estimator.data.rserve.eval(script).to_ruby["dp"]
        end

        def probability(data)
          data = Pest::DataSet::R.from_hash(data.to_hash) unless data.kind_of?(Pest::DataSet::R)
          script = <<-R
          library('DirichletReg', quietly=TRUE)
          ddirichlet(dataset, params)
          R
          data.rserve.assign("params", @params)
          NArray[ data.rserve.eval(script).to_ruby ]
        end

        def entropy
          data = @estimator.data
          script = <<-R
          library('DirichletReg', quietly=TRUE)
          categories <- unique(dataset[,'#{dependent_var}'])
          ddirichlet(categories, params, log=TRUE, sum.up=TRUE)
          R
          data.rserve.assign("params", @params)
          data.rserve.eval(script).to_ruby["H"]
        end
      end
    end
  end
end
