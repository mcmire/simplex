require 'simplex/inverted_formulated_minimization_problem'
require 'simplex/transposed_formulated_minimization_problem'
require 'simplex/formulated_problem'
require 'simplex/problem_solver'
require 'simplex/stated_problem'
require 'simplex/unbounded_problem'
require 'pp'
require 'pry'

module Simplex
  class << self
    def maximization_problem(&block)
      stated_problem = StatedProblem.new(:maximization, &block)
      formulated_problem = FormulatedProblem.new(stated_problem)
      ProblemSolver.new(formulated_problem)
    end

    def minimization_problem(&block)
      stated_problem = StatedProblem.new(:minimization, &block)
      formulated_problem = InvertedFormulatedMinimizationProblem.new(stated_problem)
      ProblemSolver.new(formulated_problem)
    end
  end
end
