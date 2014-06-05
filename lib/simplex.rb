require 'simplex/vector_extensions'
require 'simplex/problem'
require 'simplex/maximization_problem_builder'
require 'simplex/minimization_problem_builder'
require 'simplex/unbounded_problem'
require 'pp'

module Simplex
  class << self
    def maximization_problem(&block)
      builder = Simplex::MaximizationProblemBuilder.new(&block)
      builder.build
    end

    def minimization_problem(&block)
      builder = Simplex::MinimizationProblemBuilder.new(&block)
      builder.build
    end
  end
end
