require 'delegate'

module Simplex
  class MinimizationProblemBuilder < SimpleDelegator
    attr_reader :objective_coefficients_vector, :rhs_values_vector

    def initialize(
      objective_coefficients: objective_coefficients,
      constraints: constraints,
      rhs_values: rhs_values
    )
      builder = MaximizationProblemBuilder.new(
        objective_coefficients: objective_coefficients,
        constraints: constraints,
        rhs_values: rhs_values
      )

      super(builder)

      @objective_coefficients_vector = build_objective_coefficients_vector
      @constraints_matrix = build_constraints_matrix
      @rhs_values_vector = build_rhs_values_vector
    end

    def build
      problem = Simplex::Problem.new(
        objective_coefficients_vector: objective_coefficients_vector,
        constraints_matrix: constraints_matrix,
        rhs_values_vector: rhs_values_vector
      )

      MinimizationProblem.new(problem)
    end

    private

    def build_objective_coefficients_vector
      Vector[*__getobj__.rhs_values_vector.to_a[0..-2]]
    end

    def build_constraints_matrix
      # constraints_matrix isn't actually a matrix, and Array#transpose
      # cannot cope with Vectors

      constraints_matrix = __getobj__.constraints_matrix

      0.upto(num_constraints - 1) do |i|
        constraints_matrix[i][num_non_slack_vars + i] =
          -constraints_matrix[i][num_non_slack_vars + i]
      end

      matrix = constraints_matrix.map do |vector|
        vector.to_a
      end

      matrix.transpose.map do |row|
        Vector[*row]
      end
    end

    def build_rhs_values_vector
      Vector[*(
        __getobj__.objective_coefficients_vector.to_a +
        [__getobj__.rhs_values_vector[-1]]
      )]
    end

    class MinimizationProblem < SimpleDelegator
      def current_solution
        @solution.to_a[@num_non_slack_vars..-2]
      end
    end
  end
end
