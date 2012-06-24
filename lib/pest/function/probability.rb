module Pest::Function
  module Probability
    def batch_probability(*variables)
      BatchBuilder.new(self, variables)
    end
    alias :batch_p :batch_probability

    class BatchBuilder
      include Pest::Function::Builder

      attr_reader :estimator, :data_source, :event, :givens

      def initialize(estimator, variables)
        @estimator      = estimator
        @data_source    = data_source
        @event          = parse(variables)
        @givens         = [].to_set
      end

      def given(*variables)
        @givens.merge parse(variables)
        self
      end

      def in(data_set)
        @data_source = data_set
        self
      end

      def evaluate
        joint = estimator.distributions[event].batch_probability(data_source)
        if givens.empty?
          joint
        else
          conditional = estimator.distributions[givens].batch_probability(data_source)
          joint / conditional
        end
      end
    end
  end
end
