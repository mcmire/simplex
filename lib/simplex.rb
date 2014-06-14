require 'simplex/formulated_minimization_problem'
require 'simplex/formulated_problem'
require 'simplex/minimization_problem_solver'
require 'simplex/problem'
require 'simplex/problem_solver'
require 'simplex/unbounded_problem'
require 'pp'

module Simplex
  class << self
    def maximization_problem(&block)
      problem = Problem.new(&block)
      formulated_problem = FormulatedProblem.new(problem)
      ProblemSolver.new(formulated_problem)
    end

    def minimization_problem(&block)
      problem = Problem.new(&block)
      min_problem = FormulatedMinimizationProblem.new(problem)
      MinimizationProblemSolver.new(min_problem)
    end
  end
end
