require 'simplex/formulated_problem'

module Simplex
  class FormulatedMinimizationProblem < FormulatedProblem
    def constraint_coefficient_rows
      super.transpose
    end

    def objective_coefficients
      stated_problem.rhs_values
    end

    def rhs_values
      stated_problem.objective_coefficients
    end

    def determine_free_variable_coefficient(operator)
      if operator == :<=
        -1
      else
        1
      end
    end
  end
end
