require 'simplex/inverted_formulated_minimization_problem'
require 'simplex/transposed_formulated_minimization_problem'
require 'simplex/formulated_problem'
require 'simplex/transposing_minimization_problem_solver'
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
    formulated_problem = InvertedFormulatedMinimizationProblem.new(stated_problem)
    MinimizationProblemSolver.new(formulated_problem)
  end
end
