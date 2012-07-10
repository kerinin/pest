module Pest::Function
  module Entropy
    def entropy(*variables)
      Builder.new(self, variables)
    end
    alias :h :entropy

    def mutual_information(first, second)
      h(first) + h(second) - h(first, second)
    end
    alias :i :mutual_information

    class Builder
      include Pest::Function::Builder

      attr_reader :estimator, :event, :givens

      def initialize(estimator, variables)
        @estimator      = estimator
        @event          = variables.to_set
        @givens         = Set.new
        # raise ArgumentError unless (@event - @estimator.variables).empty?
      end

      def given(*variables)
        @givens += variables.to_set
        # raise ArgumentError unless (@givens - @estimator.variables).empty?
        self
      end

      def evaluate
        if givens.empty?
          estimator.distributions[*event].entropy
        else
          joint = estimator.distributions[*(event + givens)].entropy
          conditional = estimator.distributions[*givens].entropy

          joint - conditional
        end
      end
    end
  end
end
