module Simplex
  class StatedProblem
    attr_accessor :objective_coefficients
    attr_reader :type, :constraints

    def initialize(type, &block)
      @type = type
      @objective_coefficients = []
      @constraints = []
      yield self
    end

    def objective_coefficients=(coefficients)
      @objective_coefficients = rationalize(coefficients)
    end

    def add_constraint(coefficients:, operator:, rhs_value:)
      unless [:<=, :>=].include?(operator)
        raise ArgumentError, 'operator must be one of :<= or :>='
      end

      constraints << {
        coefficients: rationalize(coefficients),
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

    private

    def rationalize(values)
      values.map { |value| value.to_s.to_r }
    end
  end
end
