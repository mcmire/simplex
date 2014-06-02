require 'simplex/vector_extensions'
require 'simplex/problem'
require 'simplex/maximization_problem'
require 'simplex/unbounded_problem'

module Simplex
  def self.maximization_problem(
    objective_coefficients: objective_coefficients,
    constraints: constraints,
    rhs_values: rhs_values
  )
    Simplex::MaximizationProblem.new(
      objective_coefficients: objective_coefficients,
      constraints: constraints,
      rhs_values: rhs_values
    )
  end
end
