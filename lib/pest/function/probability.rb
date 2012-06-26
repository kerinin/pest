module Pest::Function
  module Probability
    def batch_probability(*variables)
      BatchBuilder.new(self, variables)
    end
    alias :batch_p :batch_probability

    def probability(event={})
      Builder.new(self, event)
    end
    alias :p :probability

    class BatchBuilder
      include Pest::Function::Builder

      attr_reader :estimator, :data_source, :event, :givens

      def initialize(estimator, variables)
        @estimator      = estimator
        @event          = parse(variables)
        @givens         = [].to_set
      end

      def given(*variables)
        givens.merge parse(variables)
        self
      end

      def in(data_set)
        @data_source = data_set
        self
      end

      def evaluate
        joint = estimator.distributions[event].probability(data_source)
        if givens.empty?
          joint
        else
          conditional = estimator.distributions[givens].probability(data_source)
          joint / conditional
        end
      end
    end

    class Builder
      include Pest::Function::Builder

      attr_accessor :estimator, :event, :givens

      def initialize(estimator, event)
        @estimator    = estimator
        @event        = event
        @givens       = Hash.new
      end

      def given(given)
        given.each_pair do |key, value|
          givens[estimator.data.to_variable(key, true)] = value
        end
        self
      end

      def evaluate
        data = Pest::DataSet::Hash.new(event.merge(givens))
        BatchBuilder.new(estimator, event.keys).given(*givens.keys).in(data)
      end
    end
  end
end
