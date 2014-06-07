require 'delegate'

module Simplex
  class MinimizationProblemBuilder < MaximizationProblemBuilder
    def problem_class
      MinimizationProblem
    end

    private

    def parse_arguments
      pp objective_coefficients: objective_coefficients,
         constraints: constraints

      constraint_coefficient_rows =
        map_constraint_coefficient_rows_out_of(constraints).transpose
      new_objective_coefficients =
        map_rhs_values_out_of(constraints)#.map { |value| value * -1 }
      rhs_values = objective_coefficients
      operators = constraints.map { |constraint| constraint[:operator] }

      if operators.uniq.size > 1
        raise ArgumentError, 'All operators must be the same in a minimization problem'
      end

      operator =
        if operators[0] == :>=
          :<=
        else
          :>=
        end

      constraints = constraint_coefficient_rows.zip(rhs_values).
        map do |coefficients, rhs_value|
          {
            coefficients: coefficients,
            operator: operator,
            rhs_value: rhs_value
          }
        end

      {
        objective_coefficients: new_objective_coefficients,
        constraints: constraints
      }.tap do |arguments|
        pp arguments: arguments
      end
    end
  end

  class MinimizationProblem < Simplex::Problem
    def assemble_solution
      @objective_vector.values_at(*@slack_variable_indices)
    end
  end
end
