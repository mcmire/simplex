require 'simplex/formulated_minimization_problem'
require 'simplex/formulated_problem'
require 'simplex/minimization_problem_solver'
require 'simplex/problem_solver'
require 'simplex/stated_problem'
require 'simplex/unbounded_problem'
require 'pp'

module Simplex
  def self.maximization_problem(&block)
    stated_problem = StatedProblem.new(&block)
    formulated_problem = FormulatedProblem.new(stated_problem)
    ProblemSolver.new(formulated_problem)
  end

  def self.minimization_problem(&block)
    stated_problem = StatedProblem.new(&block)
    formulated_problem = FormulatedMinimizationProblem.new(stated_problem)
    MinimizationProblemSolver.new(formulated_problem)
  end
end
