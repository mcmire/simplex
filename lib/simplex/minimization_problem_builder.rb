require 'delegate'

module Simplex
  class MinimizationProblemBuilder < MaximizationProblemBuilder
    def build
      unless num_of_values_per_constraint_is_num_of_objective_coefficients?
        raise ArgumentError, 'Number of values per constraint should be the same as the number of objective coefficients'
      end

      @number_of_constraints = calculate_number_of_constraints
      @number_of_non_slack_variables = calculate_number_of_non_slack_variables

      objective_vector = build_objective_vector
      constraints_matrix = build_constraints_matrix

      MinimizationProblem.new(
        objective_vector: objective_vector,
        constraints_matrix: constraints_matrix,
        rhs_values_vector: rhs_values,
        number_of_constraints: number_of_constraints,
        number_of_non_slack_variables: number_of_non_slack_variables
      )
    end

    private

    def build_objective_vector
      super.map { |coefficient| -1 * coefficient }
    end
  end

  class MinimizationProblem < Simplex::Problem
    def determine_entering_variable_index
      @column_indices.
        select { |index| @objective_vector[index] > 0 }.
        min_by { |index| @objective_vector[index] }
    end
  end
end
