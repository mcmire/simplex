module Simplex
  class StatedProblem
    attr_accessor :objective_coefficients
    attr_reader :constraints

    def initialize(&block)
      @objective_coefficients = []
      @constraints = []
      yield self
    end

    def add_constraint(coefficients:, operator:, rhs_value:)
      unless [:<=, :>=].include?(operator)
        raise ArgumentError, 'operator must be one of :<= or :>='
      end

      constraints << {
        coefficients: coefficients,
        operator: operator,
        rhs_value: rhs_value
      }
    end

    def constraint_coefficient_rows
      constraints.map { |constraint| constraint[:coefficients] }
    end

    def rhs_values
      constraints.map { |constraint| constraint[:rhs_value] }
    end
  end
end
