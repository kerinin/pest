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
        if givens.empty?
          estimator.distributions[event].probability(data_source).to_a
        else
          joint = estimator.distributions[ event + givens ].probability(data_source)
          conditional = estimator.distributions[givens].probability(data_source)

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
        given.each_pair do |key, value|
          givens[estimator.data.to_variable(key, true)] = value
        end
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
