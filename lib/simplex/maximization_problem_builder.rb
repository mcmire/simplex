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

      @number_of_constraints = calculate_number_of_constraints
      @number_of_decision_variables = calculate_number_of_decision_variables

      objective_vector = build_objective_vector
      constraints_matrix = build_constraints_matrix

      Simplex::Problem.new(
        objective_vector: objective_vector,
        constraints_matrix: constraints_matrix,
        rhs_values_vector: rhs_values,
        number_of_constraints: number_of_constraints,
        number_of_decision_variables: number_of_decision_variables
      )
    end

    private

    attr_reader :objective_coefficients, :constraints, :number_of_constraints,
      :number_of_decision_variables

    def rhs_values
      constraints.map { |constraint| constraint[:rhs_value] }
    end

    def calculate_number_of_constraints
      rhs_values.size
    end

    def calculate_number_of_decision_variables
      constraints.first[:coefficients].size
    end

    def build_objective_vector
      slack_variable_placeholders = Array.new(number_of_constraints, 0)
      objective_coefficients + slack_variable_placeholders
    end

    def build_constraints_matrix
      constraints.map.with_index do |constraint, i|
        constraint_coefficients = constraint[:coefficients].clone
        slack_variable_placeholders = Array.new(number_of_constraints, 0)
        values = constraint_coefficients + slack_variable_placeholders

        values[number_of_decision_variables + i] =
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
