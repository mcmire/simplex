module Simplex
  DEFAULT_MAX_PIVOTS = 10_000

  class Problem
    def initialize(
      objective_vector: objective_vector,
      constraints_matrix: constraints_matrix,
      rhs_values_vector: rhs_values_vector,
      number_of_constraints: number_of_constraints,
      number_of_decision_variables: number_of_decision_variables
    )
      @objective_vector = objective_vector
      @constraints_matrix = constraints_matrix
      @rhs_values_vector = rhs_values_vector
      @number_of_constraints = number_of_constraints
      @number_of_decision_variables = number_of_decision_variables

      # .- decision -. slack   rhs
      # +---+---+----+---+---++----+
      # | 3 | 5 | -1 | 0 | 0 || 30 |
      # | 1 | 4 |  0 | 1 | 0 || 10 |
      # | 7 | 2 |  0 | 0 | 1 || 50 |
      # +---+---+----+---+---++----+
      #  '--- constraints ---'

      @number_of_variables = @number_of_decision_variables + @number_of_constraints
      @basic_variable_indices = (@number_of_decision_variables...@number_of_variables).to_a

      @pivot_count = 0
      @solution = Array.new(@number_of_variables, 0)

      update_solution
    end

    def solution
      solve
      current_solution
    end

    def current_solution
      @solution[0...@number_of_decision_variables]
    end

    def update_solution
      @solution = Array.new(@number_of_variables, 0)

      # TODO: A better way to do this is to keep track of what the original
      # basic variables were and then select the proper rows from rhs_values
      @basic_variable_indices.each do |basic_variable_index|
        require 'pp'
        pp basic_variable_index: basic_variable_index,
           constraints_matrix: @constraints_matrix,
           row_indices: row_indices,
           rhs_values_vector: @rhs_values_vector
        row_with_1 = row_indices.detect do |row_index|
          # todo: this is testing for 1 when it should be testing for -1
          @constraints_matrix[row_index][basic_variable_index] == 1
        end
        @solution[basic_variable_index] = @rhs_values_vector[row_with_1]
      end
    end

    def solve
      while can_improve?
        @pivot_count += 1
        raise "Too many pivots" if @pivot_count > DEFAULT_MAX_PIVOTS
        pivot
      end
    end

    def can_improve?
      !!entering_variable_index
    end

    def variable_indices
      (0...@objective_vector.size).to_a
    end

    def entering_variable_index
      variable_indices.
        select { |index| @objective_vector[index] < 0 }.
        min_by { |index| @objective_vector[index] }
    end

    def pivot
      pivot_column_index = entering_variable_index
      pivot_row_index = pivot_row_index(pivot_column_index)
      raise UnboundedProblem unless pivot_row_index
      leaving_variable_index = basic_variable_index_in_row(pivot_row_index)
      replace_basic_variable(leaving_variable_index, pivot_column_index)

      pivot_ratio =
        Rational(1, @constraints_matrix[pivot_row_index][pivot_column_index])

      # update pivot row
      @constraints_matrix[pivot_row_index] = vector_multiply(
        @constraints_matrix[pivot_row_index],
        pivot_ratio
      )
      @rhs_values_vector[pivot_row_index] =
        pivot_ratio *
        @rhs_values_vector[pivot_row_index]

      # update objective
      @objective_vector = vector_subtract(
        @objective_vector,
        vector_multiply(
          @constraints_matrix[pivot_row_index],
          @objective_vector[pivot_column_index]
        )
      )

      # update A and B
      (row_indices - [pivot_row_index]).each do |row_index|
        r = @constraints_matrix[row_index][pivot_column_index]
        @constraints_matrix[row_index] = vector_subtract(
          @constraints_matrix[row_index],
          vector_multiply(@constraints_matrix[pivot_row_index], r)
        )
        @rhs_values_vector[row_index] -= @rhs_values_vector[pivot_row_index] * r
      end

      update_solution
    end

    def replace_basic_variable(from, to)
      @basic_variable_indices.delete(from)
      @basic_variable_indices << to
      # TODO: why is it necessary to sort them?
      @basic_variable_indices.sort!
    end

    def pivot_row_index(column_index)
      eligible_values = row_indices.map { |row_index|
        constraint_value = @constraints_matrix[row_index][column_index]
        rhs_value = @rhs_values_vector[row_index]
        [
          row_index,
          constraint_value,
          rhs_value,
          Rational(rhs_value, constraint_value)
        ]
      }.reject { |_, constraint_value, _, _|
        constraint_value == 0
      }.reject { |_, constraint_value, rhs_value, _|
        (rhs_value < 0) ^ (constraint_value < 0) # negative sign check
      }

      row_index, _, _, _ =
        last_min_by(eligible_values) { |_, _, _, pivot_ratio| pivot_ratio }

      row_index
    end

    # TODO: Keep better track of this
    def basic_variable_index_in_row(pivot_row_index)
      column_indices.detect do |column_index|
        @constraints_matrix[pivot_row_index][column_index] == 1 &&
          @basic_variable_indices.include?(column_index)
      end
    end

    def row_indices
      (0...@constraints_matrix.length).to_a
    end

    def column_indices
      (0...@constraints_matrix.first.size).to_a
    end

    def formatted_tableau
      if can_improve?
        pivot_column_index = entering_variable_index
        pivot_row_index    = pivot_row_index(pivot_column_index)
      else
        pivot_row_index = nil
      end
      objective_vector = formatted_values(@objective_vector)
      rhs_values_vector = formatted_values(@rhs_values_vector)
      constraints_matrix = @constraints_matrix.map do |values|
        formatted_values(values)
      end
      if pivot_row_index
        constraints_matrix[pivot_row_index][pivot_column_index] =
          "*" + constraints_matrix[pivot_row_index][pivot_column_index]
      end
      max = (
        objective_vector + rhs_values_vector + constraints_matrix + ["1234567"]
      ).flatten.map(&:size).max
      result = []
      result << objective_vector.map {|coefficient| coefficient.rjust(max, " ") }
      constraints_matrix.zip(rhs_values_vector) do |constraint_row, rhs_value|
        result << (constraint_row + [rhs_value]).map do |constraints_matrix|
          constraints_matrix.rjust(max, " ")
        end
        result.last.insert(constraint_row.length, "|")
      end
      lines = result.map {|rhs_values_vector| rhs_values_vector.join("  ") }
      max_line_length = lines.map(&:length).max
      lines.insert(1, "-"*max_line_length)
      lines.join("\n")
    end

    def formatted_values(array)
      array.map {|value| "%2.3f" % value }
    end

    # like Enumerable#min_by except if multiple values are minimum 
    # it returns the last
    def last_min_by(array)
      best_element, best_value = nil, nil
      array.each do |element|
        value = yield element
        if !best_element || value <= best_value
          best_element, best_value = element, value
        end
      end
      best_element
    end

    def assert(boolean)
      raise unless boolean
    end

    def vector_multiply(vector, scalar)
      vector.map { |value| value * scalar }
    end

    def vector_subtract(vector1, vector2)
      vector1.zip(vector2).map do |value1, value2|
        value1 - value2
      end
    end
  end
end
