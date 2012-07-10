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
        @event          = variables.to_set
        @givens         = [].to_set
        # raise ArgumentError unless (@event - @estimator.variables).empty?
      end

      def given(*variables)
        @givens += variables.to_set
        # raise ArgumentError unless (@givens - @estimator.variables).empty?
        self
      end

      def in(data_set)
        @data_source = data_set
        self
      end

      def evaluate
        if givens.empty?
          estimator.distributions[*event].probability(data_source).to_a
        else
          joint = estimator.distributions[*(event + givens)].probability(data_source)
          conditional = estimator.distributions[*givens].probability(data_source)

          (joint / conditional).to_a
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
        givens.merge! given
        # raise ArgumentError unless (given.keys.to_set - @estimator.variables).empty?
        self
      end

      def evaluate
        data_hash = event.merge(givens)
        data_hash.each_key {|key| data_hash[key] = Array(data_hash[key])}

        data = Pest::DataSet::Hash.from_hash(data_hash)
        BatchBuilder.new(estimator, event.keys).
          given(*givens.keys).in(data).
          evaluate.first
      end
    end
  end
end
