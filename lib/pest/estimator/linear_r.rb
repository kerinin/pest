module Pest::Estimator
  module LinearR
    def dirichlet(data)
      Dirichlet.new(data)
    end

    def beta(data)
      # Beta.new(data)
    end

    def logit(data)
      # Logit.new(data)
    end

    def probit(data)
      # Probit.new(data)
    end
  end
end
