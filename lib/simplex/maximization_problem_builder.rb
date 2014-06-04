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
      if ![:<=, :>=].include?(operator)
        raise ArgumentError, 'operator must be one of :<= or :>='
      end

      constraints << {
        coefficients: coefficients,
        operator: operator,
        rhs_value: rhs_value
      }
    end

    def build
      unless all_dimensions_match?
        raise ArgumentError, "Input arrays have mismatched dimensions"
      end

      @num_constraints = calculate_num_constraints
      @num_non_slack_vars = calculate_num_non_slack_vars

      objective_vector = build_objective_vector
      constraints_matrix = build_constraints_matrix
      rhs_values_vector = build_rhs_values_vector

      Simplex::Problem.new(
        objective_vector: objective_vector,
        constraints_matrix: constraints_matrix,
        rhs_values_vector: rhs_values_vector,
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
        objective_coefficients.map {|coefficient| -1 * coefficient }

      slack_var_placeholders = [0] * num_constraints

      values =
        coefficients_on_opposite_side_of_equation +
        slack_var_placeholders

      Vector[*values]
    end

    def build_constraints_matrix
      constraints.map.with_index do |constraint, i|
        constraint_coefficients = constraint[:coefficients].clone
        slack_var_placeholders = [0] * num_constraints
        values = constraint_coefficients + slack_var_placeholders

        values[num_non_slack_vars + i] =
          determine_slack_value(constraint[:operator])

        Vector[*values]
      end
    end

    def build_rhs_values_vector
      Vector[*rhs_values]
    end

    def constraints_width_is_coefficients_length?
      constraints.all? do |constraint|
        constraint[:coefficients].size == objective_coefficients.size
      end
    end

    def rhs_values_length_is_constraints_height?
      rhs_values.size == objective_coefficients.size
    end

    def all_dimensions_match?
      constraints_width_is_coefficients_length? &&
        rhs_values_length_is_constraints_height?
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
