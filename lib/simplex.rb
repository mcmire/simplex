require 'simplex/vector_extensions'
require 'simplex/problem'
require 'simplex/maximization_problem_builder'
require 'simplex/unbounded_problem'

module Simplex
  def self.maximization_problem(
    objective_coefficients: objective_coefficients,
    constraints: constraints,
    rhs_values: rhs_values
  )
    builder = Simplex::MaximizationProblemBuilder.new(
      objective_coefficients: objective_coefficients,
      constraints: constraints,
      rhs_values: rhs_values
    )

    builder.build
  end
end
