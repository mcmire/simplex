require 'delegate'

module Simplex
  class MinimizationProblemBuilder < SimpleDelegator
    attr_reader :objective_vector

    def initialize(&block)
      builder = MaximizationProblemBuilder.new(&block)
      super(builder)
    end

    private

    def build_objective_vector
      values = __getobj__.objective_vector
      values.map { |coefficient| -1 * coefficient }
    end
  end
end
