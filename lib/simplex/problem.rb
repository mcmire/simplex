require 'matrix'

module Simplex
  DEFAULT_MAX_PIVOTS = 10_000

  class Problem
    attr_accessor :max_pivots

    def initialize(
      objective_coefficients_vector: objective_coefficients_vector,
      constraints_matrix: constraints_matrix,
      rhs_values_vector: rhs_values_vector,
      num_constraints: num_constraints,
      num_non_slack_vars: num_non_slack_vars
    )
      @objective_coefficients_vector = objective_coefficients_vector
      @constraints_matrix = constraints_matrix
      @rhs_values_vector = rhs_values_vector
      @num_non_slack_vars = num_non_slack_vars
      @num_constraints    = num_constraints

      @num_vars = @num_non_slack_vars + @num_constraints
      @basic_vars = (@num_non_slack_vars...@num_vars).to_a

      @pivot_count = 0
      @max_pivots = DEFAULT_MAX_PIVOTS
      @solution = Vector[*([0]*@num_vars)]

      update_solution
    end

    def solution
      solve
      current_solution
    end

    def current_solution
      @solution.to_a[0...@num_non_slack_vars]
    end

    def update_solution
      0.upto(@num_vars - 1) {|i| @solution[i] = 0 }

      @basic_vars.each do |basic_var|
        row_with_1 = row_indices.detect do |row_ix|
          @constraints_matrix[row_ix][basic_var] == 1
        end
        @solution[basic_var] = @rhs_values_vector[row_with_1]
      end
    end

    def solve
      while can_improve?
        @pivot_count += 1
        raise "Too many pivots" if @pivot_count > max_pivots 
        pivot
      end
    end

    def can_improve?
      !!entering_variable
    end

    def variables
      (0...@objective_coefficients_vector.size).to_a
    end

    def entering_variable
      variables.select { |var| @objective_coefficients_vector[var] < 0 }.
                min_by { |var| @objective_coefficients_vector[var] }
    end

    def pivot
      pivot_column = entering_variable
      pivot_row    = pivot_row(pivot_column)
      raise UnboundedProblem unless pivot_row
      leaving_var  = basic_variable_in_row(pivot_row)
      replace_basic_variable(leaving_var => pivot_column)

      pivot_ratio = Rational(1, @constraints_matrix[pivot_row][pivot_column])

      # update pivot row
      @constraints_matrix[pivot_row] *= pivot_ratio
      @rhs_values_vector[pivot_row] = pivot_ratio * @rhs_values_vector[pivot_row]

      # update objective
      @objective_coefficients_vector -= @objective_coefficients_vector[pivot_column] * @constraints_matrix[pivot_row]

      # update A and B
      (row_indices - [pivot_row]).each do |row_ix|
        r = @constraints_matrix[row_ix][pivot_column]
        @constraints_matrix[row_ix] -= r * @constraints_matrix[pivot_row]
        @rhs_values_vector[row_ix] -= r * @rhs_values_vector[pivot_row]
      end

      update_solution
    end

    def replace_basic_variable(hash)
      from, to = hash.keys.first, hash.values.first
      @basic_vars.delete(from)
      @basic_vars << to
      @basic_vars.sort!
    end

    def pivot_row(column_ix)
      row_ix_a_and_b = row_indices.map { |row_ix|
        [row_ix, @constraints_matrix[row_ix][column_ix], @rhs_values_vector[row_ix]]
      }.reject { |_, constraints_matrix, rhs_values_vector|
        constraints_matrix == 0
      }.reject { |_, constraints_matrix, rhs_values_vector|
        (rhs_values_vector < 0) ^ (constraints_matrix < 0) # negative sign check
      }
      row_ix, _, _ = *last_min_by(row_ix_a_and_b) { |_, constraints_matrix, rhs_values_vector|
        Rational(rhs_values_vector, constraints_matrix)
      }
      row_ix
    end

    def basic_variable_in_row(pivot_row)
      column_indices.detect do |column_ix|
        @constraints_matrix[pivot_row][column_ix] == 1 and @basic_vars.include?(column_ix)
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
        pivot_column = entering_variable
        pivot_row    = pivot_row(pivot_column)
      else
        pivot_row = nil
      end
      num_cols = @objective_coefficients_vector.size + 1
      objective_coefficients_vector = formatted_values(@objective_coefficients_vector.to_a)
      rhs_values_vector = formatted_values(@rhs_values_vector.to_a)
      constraints_matrix = @constraints_matrix.to_a.map {|ar| formatted_values(ar.to_a) }
      if pivot_row
        constraints_matrix[pivot_row][pivot_column] = "*" + constraints_matrix[pivot_row][pivot_column]
      end
      max = (objective_coefficients_vector + rhs_values_vector + constraints_matrix + ["1234567"]).flatten.map(&:size).max
      result = []
      result << objective_coefficients_vector.map {|coefficient| coefficient.rjust(max, " ") }
      constraints_matrix.zip(rhs_values_vector) do |constraint_row, rhs_value|
        result << (constraint_row + [rhs_value]).map {|constraints_matrix| constraints_matrix.rjust(max, " ") }
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
  end
end