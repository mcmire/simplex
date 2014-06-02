module Simplex
  class MaximizationProblemBuilder
    attr_reader :objective_coefficients_vector, :constraints_matrix,
      :rhs_values_vector

    def initialize(
      objective_coefficients: objective_coefficients,
      constraints: constraints,
      rhs_values: rhs_values
    )
      @objective_coefficients = objective_coefficients
      @constraints = constraints
      @rhs_values = rhs_values

      unless all_dimensions_match?
        raise ArgumentError, "Input arrays have mismatched dimensions"
      end

      @objective_coefficients_vector = build_objective_coefficients_vector
      @constraints_matrix = build_constraints_matrix
      @rhs_values_vector = build_rhs_values_vector
    end

    def build
      Simplex::Problem.new(
        objective_coefficients_vector: objective_coefficients_vector,
        constraints_matrix: constraints_matrix,
        rhs_values_vector: rhs_values_vector,
        num_constraints: num_constraints,
        num_non_slack_vars: num_non_slack_vars
      )
    end

    private

    attr_reader :objective_coefficients, :constraints, :rhs_values

    def num_constraints
      rhs_values.length
    end

    def num_non_slack_vars
      constraints.first.length
    end

    def build_objective_coefficients_vector
      Vector[*(
        objective_coefficients.map {|coefficient| -1 * coefficient } +
        [0] * num_constraints
      )]
    end

    def build_constraints_matrix
      constraints_matrix = constraints.map do |constraint|
        Vector[*(constraint.clone + [0] * num_constraints)]
      end

      0.upto(num_constraints - 1) do |i|
        constraints_matrix[i][num_non_slack_vars + i] = 1
      end

      constraints_matrix
    end

    def build_rhs_values_vector
      Vector[*rhs_values.clone]
    end

    def constraints_width_is_coefficients_length?
      constraints.all? do |constraint|
        constraint.size == objective_coefficients.size
      end
    end

    def rhs_values_length_is_constraints_height?
      rhs_values.size == constraints.size
    end

    def all_dimensions_match?
      constraints_width_is_coefficients_length? &&
        rhs_values_length_is_constraints_height?
    end
  end
end
