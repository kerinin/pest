module Pest::Function

  module Builder
    # Delegate methods to the result of 'evaluate'
    #
    methods = [
      :sprintf, :+, :-, :*, :/, :**, :<=>, :==, :coerce, :floor, :ceil,
      :truncate, :round, :to_i, :to_f, :to_r, :rationalize, :hash, :to_s,
      :i, :+@, :-@, :eql?, :div, :divmod, :%, :modulo, :remainder, :abs,
      :magnitude, :to_int, :real?, :integer?, :zero?, :nonzero?,
      :>, :>=, :<, :<=, :between?, :pretty_print_instance_variables,
      :pretty_print_inspect, :nil?, :===, :=~, :!~, :!, :!=
    ]

    methods.each do |f|
      define_method(f) do |*args|
        evaluate.send(f, *args)
      end
    end
  end
end
