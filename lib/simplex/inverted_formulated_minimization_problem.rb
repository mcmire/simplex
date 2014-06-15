require 'simplex/formulated_problem'

module Simplex
  class InvertedFormulatedMinimizationProblem < FormulatedProblem
    def build_objective_vector
      super.map { |value| -value }
    end
  end
end
