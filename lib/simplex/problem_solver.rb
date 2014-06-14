module Simplex
  DEFAULT_MAX_PIVOTS = 10_000

  class ProblemSolver
    def initialize(formulated_problem)
      @formulated_problem = formulated_problem
      @stated_problem = formulated_problem.stated_problem

      @objective_vector = formulated_problem.objective_vector
      @constraints_matrix = formulated_problem.constraints_matrix
      @rhs_values_vector = formulated_problem.rhs_values_vector
      @number_of_non_free_variables = formulated_problem.number_of_non_free_variables
      @number_of_free_variables = formulated_problem.number_of_free_variables

      # .- decision -. free   rhs
      # +---+---+----+---+---++----+
      # | 3 | 5 | -1 | 0 | 0 || 30 |
      # | 1 | 4 |  0 | 1 | 0 || 10 |
      # | 7 | 2 |  0 | 0 | 1 || 50 |
      # +---+---+----+---+---++----+
      #  '--- constraints ---'

      @number_of_variables =
        number_of_non_free_variables + number_of_free_variables
      # choose one, doesn't matter, we choose objective_vector here
      @column_indices = (0...objective_vector.size).to_a
      @row_indices = (0...constraints_matrix.length).to_a
      @non_free_variable_indices = (0...number_of_non_free_variables).to_a
      @free_variable_indices =
        (number_of_non_free_variables...number_of_variables).to_a

      @pivot_count = 0
      @basic_variable_indices_by_rhs_value_index = free_variable_indices.dup
      @solution = assemble_solution
      @solved = false
    end

    def solve
      unless solved?
        while can_improve?
          @pivot_count += 1
          raise "Too many pivots" if pivot_count > DEFAULT_MAX_PIVOTS
          pivot
        end
        @solved = true
      end

      @solution
    end

    def can_improve?
      @pivot_column_index = determine_entering_variable_index
      !!pivot_column_index
    end

    def pivot
      pivot_row_index = determine_pivot_row_index(pivot_column_index)
      raise UnboundedProblem unless pivot_row_index
      replace_basic_variable(pivot_row_index, pivot_column_index)
      pivot_ratio =
        Rational(1, constraints_matrix[pivot_row_index][pivot_column_index])
      divide_pivot_row_by_pivot_element(pivot_row_index, pivot_ratio)
      adjust_non_pivot_rows_so_pivot_row_is_basic(pivot_row_index, pivot_ratio)

      @solution = assemble_solution
    end

    def formatted_tableau
      if can_improve?
        pivot_row_index = determine_pivot_row_index(pivot_column_index)
      else
        pivot_row_index = nil
      end
      objective_vector = formatted_values(@objective_vector + [calculated_objective_total])
      rhs_values_vector = formatted_values(@rhs_values_vector)
      constraints_matrix = @constraints_matrix.map do |values|
        formatted_values(values)
      end
      if pivot_row_index
        constraints_matrix[pivot_row_index][pivot_column_index] =
          "*" + constraints_matrix[pivot_row_index][pivot_column_index]
      end
      max = (
        objective_vector + rhs_values_vector + constraints_matrix
      ).flatten.map(&:size).max
      result = []
      constraints_matrix.zip(rhs_values_vector) do |constraint_row, rhs_value|
        result << (constraint_row + [rhs_value]).map do |constraints_matrix|
          constraints_matrix.rjust(max, " ")
        end
        result.last.insert(constraint_row.length, "|")
      end
      result << objective_vector.map do |coefficient|
        coefficient.rjust(max, " ")
      end
      result.last.insert(-2, "|")
      lines = result.map {|rhs_values_vector| rhs_values_vector.join("  ") }
      max_line_length = lines.map(&:length).max
      lines.insert(-2, "-"*max_line_length)
      lines.join("\n")
    end

    private

    attr_reader :formulated_problem, :stated_problem, :objective_vector,
      :constraints_matrix, :rhs_values_vector, :number_of_constraints,
      :number_of_non_free_variables, :number_of_free_variables,
      :number_of_variables, :column_indices, :row_indices,
      :non_free_variable_indices, :free_variable_indices, :pivot_count,
      :basic_variable_indices_by_rhs_value_index, :solution,
      :pivot_column_index

    def solved?
      @solved
    end

    def determine_entering_variable_index
      column_indices.
        select { |index| objective_vector[index] < 0 }.
        min_by { |index| objective_vector[index] }
    end

    def determine_pivot_row_index(column_index)
      eligible_values = row_indices.map { |row_index|
        constraint_value = constraints_matrix[row_index][column_index]
        rhs_value = rhs_values_vector[row_index]
        [
          row_index,
          constraint_value,
          rhs_value
        ]
      }.reject { |_, constraint_value, _|
        constraint_value == 0
      }.reject { |_, constraint_value, rhs_value|
        (rhs_value < 0) ^ (constraint_value < 0) # negative sign check
      }

      row_index, _, _ =
        last_min_by(eligible_values) { |_, constraint_value, rhs_value|
          Rational(rhs_value, constraint_value)
        }

      row_index
    end

    def replace_basic_variable(rhs_value_index, entering_variable_index)
      basic_variable_indices_by_rhs_value_index[rhs_value_index] = entering_variable_index
    end

    def divide_pivot_row_by_pivot_element(pivot_row_index, pivot_ratio)
      # We want to make the pivot element 1 if it's not, so divide all values
      # in the pivot row by this value.
      constraints_matrix[pivot_row_index] = vector_multiply(
        constraints_matrix[pivot_row_index],
        pivot_ratio
      )

      # Include the RHS value in this too.
      rhs_values_vector[pivot_row_index] =
        rhs_values_vector[pivot_row_index] *
        pivot_ratio
    end

    def adjust_non_pivot_rows_so_pivot_row_is_basic(pivot_row_index, pivot_ratio)
      # Now for all of the other rows we want to subtract an appropriate
      # multiple of the pivot row. This multiple is the intersection of the
      # pivot column and row in question. This causes all of the other elements
      # in the pivot column to become 0.
      (row_indices - [pivot_row_index]).each do |row_index|
        multiple = constraints_matrix[row_index][pivot_column_index]
        constraints_matrix[row_index] = vector_subtract(
          constraints_matrix[row_index],
          vector_multiply(constraints_matrix[pivot_row_index], multiple)
        )
        rhs_values_vector[row_index] -=
          rhs_values_vector[pivot_row_index] * multiple
      end

      # Include the objective in this too.
      objective_vector.replace(vector_subtract(
        objective_vector,
        vector_multiply(
          constraints_matrix[pivot_row_index],
          objective_vector[pivot_column_index]
        )
      ))
    end

    def assemble_solution
      solution = Array.new(number_of_non_free_variables, 0)

      basic_variable_indices_by_rhs_value_index.
        each_with_index do |variable_index, rhs_value_index|
          if non_free_variable_indices.include?(variable_index)
            solution[variable_index] = rhs_values_vector[rhs_value_index]
          end
        end

      solution
    end

    def calculated_objective_total
      formulated_problem.objective_coefficients.zip(solution).
        inject(0) do |total, (coefficient_value, variable_value)|
          total + (coefficient_value * variable_value)
        end
    end

    def formatted_values(array)
      array.map do |value|
        if value.denominator == 1
          value.numerator.to_s
        else
          value.to_s
        end
      end
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
