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

      problem_class.new(determine_problem_arguments)
    end

    private

    attr_reader :objective_coefficients, :constraints, :number_of_constraints,
      :number_of_non_slack_variables

    def problem_class
      Simplex::Problem
    end

    def parse_arguments
      {
        objective_coefficients: objective_coefficients,
        constraints: constraints
      }
    end

    def map_constraint_coefficient_rows_out_of(constraints)
      constraints.map { |constraint| constraint[:coefficients] }
    end

    def map_rhs_values_out_of(constraints)
      constraints.map { |constraint| constraint[:rhs_value] }
    end

    def determine_problem_arguments
      arguments = parse_arguments
      rhs_values = map_rhs_values_out_of(arguments[:constraints])

      @number_of_constraints = arguments[:constraints].size
      @number_of_non_slack_variables = arguments[:constraints].first.size

      objective_vector = build_objective_vector(
        arguments[:objective_coefficients],
        @number_of_constraints
      )
      constraints_matrix = build_constraints_matrix(
        arguments[:constraints],
        @number_of_non_slack_variables
      )
      rhs_values_vector = build_rhs_values_vector(rhs_values)

      {
        number_of_constraints: number_of_constraints,
        number_of_non_slack_variables: number_of_non_slack_variables,
        objective_vector: objective_vector,
        constraints_matrix: constraints_matrix,
        rhs_values_vector: rhs_values_vector
      }.tap do |problem_arguments|
        pp problem_arguments: problem_arguments
      end
    end

    def build_objective_vector(objective_coefficients, number_of_constraints)
      coefficients_on_opposite_side_of_equation =
        objective_coefficients.map { |coefficient| -1 * coefficient }

      slack_variable_placeholders = Array.new(number_of_constraints, 0)

      coefficients_on_opposite_side_of_equation + slack_variable_placeholders
    end

    def build_constraints_matrix(constraints, number_of_constraints)
      constraints.map.with_index do |constraint, i|
        slack_variable_placeholders = Array.new(number_of_constraints, 0)
        values = constraint[:coefficients] + slack_variable_placeholders

        values[number_of_non_slack_variables + i] =
          determine_slack_value(constraint[:operator])

        values
      end
    end

    def build_rhs_values_vector(rhs_values)
      rhs_values
    end

    def num_of_values_per_constraint_is_num_of_objective_coefficients?
      constraints.all? do |constraint|
        constraint[:coefficients].size == objective_coefficients.size
      end
    end

    def determine_slack_value(operator)
      if operator == :>=
        -1
      else
        1
      end
    end
  end
end
