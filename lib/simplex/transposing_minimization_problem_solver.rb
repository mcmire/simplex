require 'delegate'
require 'simplex/problem_solver'

module Simplex
  class MinimizationProblemSolver < ProblemSolver
    def calculated_objective_total
      formulated_problem.objective_coefficients.zip(assemble_visible_solution).
        inject(0) do |total, (coefficient_value, variable_value)|
          total + (coefficient_value * variable_value)
        end
    end

    alias :assemble_visible_solution :assemble_solution

    def assemble_solution
      objective_vector.values_at(*free_variable_indices)
    end
  end
end
