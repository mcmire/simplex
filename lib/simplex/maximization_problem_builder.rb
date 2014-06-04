require 'delegate'

module Simplex
  class MaximizationProblemBuilder
    attr_writer :objective_coefficients

    attr_reader :objective_vector, :constraints_matrix,
      :rhs_values_vector

    def initialize(&block)
      @objective_coefficients = []
      @constraints = []
      yield self
    end

    def add_constraint(coefficients:, operator:, rhs_value:)
      unless [:<=, :>=].include?(operator)
        raise ArgumentError, 'operator must be one of :<= or :>='
      end

      constraints << {
        coefficients: coefficients,
        operator: operator,
        rhs_value: rhs_value
      }
    end

    def build
      unless num_of_values_per_constraint_is_num_of_objective_coefficients?
        raise ArgumentError, 'Number of values per constraint should be the same as the number of objective coefficients'
      end

      @num_constraints = calculate_num_constraints
      @num_non_slack_vars = calculate_num_non_slack_vars

      objective_vector = build_objective_vector
      constraints_matrix = build_constraints_matrix

      Simplex::Problem.new(
        objective_vector: objective_vector,
        constraints_matrix: constraints_matrix,
        rhs_values_vector: rhs_values,
        num_constraints: num_constraints,
        num_non_slack_vars: num_non_slack_vars
      )
    end

    private

    attr_reader :objective_coefficients, :constraints, :num_constraints,
      :num_non_slack_vars

    def rhs_values
      constraints.map { |constraint| constraint[:rhs_value] }
    end

    def calculate_num_constraints
      rhs_values.size
    end

    def calculate_num_non_slack_vars
      constraints.first[:coefficients].size
    end

    def build_objective_vector
      coefficients_on_opposite_side_of_equation =
        objective_coefficients.map { |coefficient| -1 * coefficient }

      slack_var_placeholders = Array.new(num_constraints, 0)

      coefficients_on_opposite_side_of_equation + slack_var_placeholders
    end

    def build_constraints_matrix
      constraints.map.with_index do |constraint, i|
        constraint_coefficients = constraint[:coefficients].clone
        slack_var_placeholders = Array.new(num_constraints, 0)
        values = constraint_coefficients + slack_var_placeholders

        values[num_non_slack_vars + i] =
          determine_slack_value(constraint[:operator])

        values
      end
    end

    def num_of_values_per_constraint_is_num_of_objective_coefficients?
      constraints.all? do |constraint|
        constraint[:coefficients].size == objective_coefficients.size
      end
    end

    def determine_slack_value(operator)
      if operator == :>=
        1
      else
        -1
      end
    end
  end
end
