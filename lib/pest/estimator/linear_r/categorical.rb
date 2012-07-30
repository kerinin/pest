module Pest::Estimator
  module LinearR
    class Categorical
      include Pest::Estimator
      include Pest::Function::Probability
      include Pest::Function::Entropy

      attr_reader :model

      def initialize(data, attrs={})
        model = attrs[:model] || 'mlogit'
        raise ArgumentError unless data.kind_of?(Pest::DataSet::R)
        raise ArgumentError unless ['logit', 'probit', 'blogit', 'bprobit', 'mlogit'].include? model

        super(data)
        @model = model

        data.rserve.void_eval "library(Zelig)"
      end

      def distribution_class
        Distribution
      end

      class Distribution
        include Pest::Estimator::Distribution

        def initialize(estimator, variables)
          super(estimator, variables)
          script = <<-R
            z.out <- zelig( #{p} ~ #{variables.to_a.join('+')}, model = "#{model}", data = dataset
          R
          # estimator.data.rserve.eval script
        end

        def probability(data)
          new_file = Tempfile.new('r_data')
          script = <<-R
            x.out <- setx( z.out, data = given.dataset, cond = TRUE )
            s.out <- sim( z.out, x = x.out )
            summary(s.out)$qi.stats$pr[,'#{p}']
          R
          # data.rserve.eval script
        end

        def entropy
        end

        private

        def model
          @estimator.model
        end
      end
    end
  end
end
