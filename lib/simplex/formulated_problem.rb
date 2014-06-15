require 'delegate'

module Simplex
  class FormulatedProblem < SimpleDelegator
    attr_reader :stated_problem

    def initialize(stated_problem)
      super(stated_problem)
      @stated_problem = stated_problem
    end

    def objective_vector
      @objective_vector ||= build_objective_vector
    end

    def constraints_matrix
      @constraints_matrix ||= build_constraints_matrix
    end

    def rhs_values_vector
      @rhs_values_vector ||= rhs_values.dup
    end

    def number_of_constraints
      @number_of_constraints ||= constraint_coefficient_rows.size
    end

    def number_of_non_free_variables
      @number_of_non_free_variables ||= constraint_coefficient_rows.first.size
    end

    def number_of_free_variables
      @number_of_free_variables ||= number_of_constraints
    end

    private

    def build_objective_vector
      coefficients_on_opposite_side_of_equation =
        objective_coefficients.map { |coefficient| -1 * coefficient }

      free_variable_placeholders = Array.new(number_of_free_variables, 0)

      coefficients_on_opposite_side_of_equation + free_variable_placeholders
    end

    def build_constraints_matrix
      constraints.map.with_index do |constraint, i|
        free_variable_placeholders = Array.new(number_of_free_variables, 0)
        values = constraint[:coefficients] + free_variable_placeholders

        values[number_of_non_free_variables + i] =
          determine_free_variable_coefficient(constraint[:operator])

        values
      end
    end

    def num_of_values_per_constraint_is_num_of_objective_coefficients?
      constraints.all? do |constraint|
        constraint[:coefficients].size == objective_coefficients.size
      end
    end

    def determine_free_variable_coefficient(operator)
      if operator == :>=
        -1
      else
        1
      end
    end
  end
end
