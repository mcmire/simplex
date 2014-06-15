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

      @number_of_variables =
        number_of_non_free_variables + number_of_free_variables
      # choose one, doesn't matter, we choose objective_vector here
      @column_indices = (0...objective_vector.size).to_a
      @row_indices = (0...constraints_matrix.length).to_a
      @variable_indices = (0...@number_of_variables).to_a
      @non_free_variable_indices = (0...number_of_non_free_variables).to_a
      @free_variable_indices =
        (number_of_non_free_variables...number_of_variables).to_a
      @variable_names =
        (1..number_of_non_free_variables).map { |n| "x#{n}" } +
        (1..number_of_free_variables).map { |n| "s#{n}" }

      @pivot_count = 0
      @categorized_constraint_columns = build_categorized_constraint_columns
      @basic_variable_indices = free_variable_indices.dup
      @next_pivot = nil
      @converted_basic_column_indices = []
      @full_solution = assemble_full_solution
      @solution = assemble_solution
      @solved = false

      @callbacks = {}
    end

    def debug!
      on :begin do
        puts 'Initial tableau'
        puts formatted_tableau(indicate_pivot_element: false)
      end

      on :before_prepare_to_pivot do
        puts
        inspect 'Full solution so far', full_solution
        inspect 'Solution so far', solution
        inspect 'Calculated total so far', calculated_objective_total

        if standard_problem?
          puts "This is a standard problem"
        else
          puts "This isn't a standard problem"
        end

        puts
        puts '--- ANALYZING TABLEAU ---'
      end

      on :determine_entering_variable_index do |column_indices|
        inspect 'Pivot column candidate indices', column_indices
      end

      on :determine_pivot_row_index do |row_indices|
        inspect 'Pivot row candidate indices', row_indices
      end

      on :after_prepare_to_pivot do
        inspect 'Winning column index', next_pivot[:column_index]
        inspect 'Winning row index', next_pivot[:row_index]
      end

      on :after_analyze_tableau do
        puts
        puts 'Tableau after analysis:'
        puts formatted_tableau
        puts
        puts '--- PERFORMING PIVOT ---'
      end

      on :pivot do
        puts
        puts 'Tableau after pivoting:'
        puts formatted_tableau(indicate_pivot_element: false)
      end

      on :add_leaving_variable_to_converted_basic_column_indices do |leaving_variable_index|
        inspect 'Adding to basic column indices', leaving_variable_index
      end

      on :clear_converted_basic_column_indices do
        puts 'Clearing basic column indices'
      end

      on :before_swap_basic_variable do
        inspect 'Entering variable index', entering_variable_index
        inspect 'Pivot row index', pivot_row_index
        inspect 'Leaving variable index', leaving_variable_index
      end
    end

    def solve
      fire :begin

      unless solved?
        while pivot
          @pivot_count += 1

          if pivot_count > DEFAULT_MAX_PIVOTS
            raise 'Too many pivots'
          end
        end

        @solved = true
      end

      solution
    end

    def pivot(*inspection_blocks)
      fire :before_prepare_to_pivot
      prepare_to_pivot
      fire :after_prepare_to_pivot

      if pivot_column_index.nil?
        return false
      end

      if pivot_row_index.nil?
        raise UnboundedProblem
      end

      fire :after_analyze_tableau

      updating_converted_basic_column_indices do
        swap_basic_variable
        divide_pivot_row_by_pivot_element(pivot_ratio)
        adjust_non_pivot_rows_so_pivot_column_is_basic(pivot_ratio)

        fire :pivot

        @full_solution = assemble_full_solution
        @solution = assemble_solution
      end

      return true
    end

    def formatted_tableau(options = {})
      objective_vector = formatted_values(@objective_vector + [calculated_objective_total]).
        map.with_index do |value, column_index|
          if basic_variable_indices.include?(column_index) && options[:indicate_pivot_element] == false
            "\e[33m" + value + "\e[0m"
          else
            value
          end
        end

      if pivot_column_index && pivot_row_index
        objective_vector = objective_vector.map.with_index do |value, column_index|
          if column_index == pivot_column_index
            "\e[32m" + value + "\e[0m"
          else
            value
          end
        end
      end

      rhs_values_vector = formatted_values(@rhs_values_vector)

      variable_names = @variable_names.map.with_index do |variable_name, variable_index|
        if basic_variable_indices.include?(variable_index) && options[:indicate_pivot_element] == false
          "\e[33m" + variable_name + "\e[0m"
        elsif variable_index == pivot_column_index && options[:indicate_pivot_element] != false
          "\e[34m" + variable_name + "\e[0m"
        elsif variable_index == leaving_variable_index && options[:indicate_pivot_element] != false
          "\e[35m" + variable_name + "\e[0m"
        else
          variable_name
        end
      end

      basic_variable_names = basic_variable_indices.map.with_index do |variable_index, row_index|
        variable_name = @variable_names[variable_index]

        if row_index == pivot_row_index && options[:indicate_pivot_element] != false
          "\e[35m" + variable_name + "\e[0m"
        else
          variable_name
        end
      end

      constraints_matrix = @constraints_matrix.map.with_index do |values, row_index|
        formatted_values(values) + [rhs_values_vector[row_index]]
      end

      constraints_matrix.each_with_index do |values, row_index|
        constraints_matrix[row_index] = values.map.with_index do |value, column_index|
          if basic_variable_indices.include?(column_index) && options[:indicate_pivot_element] == false
            "\e[33m" + value + "\e[0m"
          elsif pivot_column_index && pivot_row_index
            if row_index == pivot_row_index && column_index == pivot_column_index && options[:indicate_pivot_element] != false
              "\e[31m" + value + "\e[0m"
            elsif (row_index == pivot_row_index || column_index == pivot_column_index) && options[:indicate_pivot_element] != false
              "\e[32m" + value + "\e[0m"
            else
              value
            end
          else
            value
          end
        end
      end

      max = (objective_vector + rhs_values_vector + constraints_matrix + variable_names + ['RHS']).
        flatten.
        map { |line| line.gsub(/\e\[\d+m/, '').length }.
        max

      result = []
      result << (variable_names + ['RHS']).map do |value|
        rjust_including_color(value, max, ' ')
      end

      result.last.insert(-2, '|')
      result.last.insert(-1, '|')

      constraints_matrix.zip(basic_variable_names).
        each do |constraint_row, basic_variable_name|
          result << (constraint_row + [basic_variable_name]).
            map { |value| rjust_including_color(value, max, ' ') }
          result.last.insert(constraint_row.length-1, "|")
          result.last.insert(-2, "|")
        end

      result << objective_vector.map do |value|
        rjust_including_color(value, max, ' ')
      end

      result.last.insert(-2, "|")
      result.last.insert(-1, '|')

      lines = result.map { |line| line.join("  ") }
      max_line_length = lines.map { |line| line.gsub(/\e\[\d+m/, '').length }.max
      lines.insert(1, "-"*max_line_length)
      lines.insert(-2, "-"*max_line_length)
      lines.join("\n")
    end

    def on(callback_name, &block)
      (callbacks[callback_name] ||= []) << block
    end

    def fire(callback_name, *args)
      if callbacks.key?(callback_name)
        callbacks[callback_name].each { |block| block.call(*args) }
      end
    end

    private

    attr_reader :formulated_problem, :stated_problem, :objective_vector,
      :constraints_matrix, :rhs_values_vector, :number_of_constraints,
      :number_of_non_free_variables, :number_of_free_variables,
      :number_of_variables, :column_indices, :row_indices, :variable_indices,
      :non_free_variable_indices, :free_variable_indices, :variable_names,
      :pivot_count, :categorized_constraint_columns,
      :basic_variable_indices, :converted_basic_column_indices,
      :full_solution, :solution, :next_pivot, :callbacks

    def solved?
      @solved
    end

    def build_categorized_constraint_columns
      columns = []

      constraints_matrix.each_with_index do |values, row_index|
        values.each_with_index do |value, column_index|
          column = columns[column_index] ||= {}

          if free_variable_indices.include?(column_index) && value != 0
            column[:basic] = {
              value: value,
              kind: (value == 1) ? :slack : :surplus,
              row_index: row_index
            }
          end
        end
      end

      columns
    end

    def standard_problem?
      full_solution.values_at(*free_variable_indices).none? { |value| value < 0 }
    end

    def row_indices_with_surplus_variables
      categorized_constraint_columns.
        select { |column| column[:basic] && column[:basic][:kind] == :surplus }.
        map { |column| column[:basic][:row_index] }
    end

    def pivot_row_index
      if next_pivot
        next_pivot[:row_index]
      end
    end

    def pivot_column_index
      if next_pivot
        next_pivot[:column_index]
      end
    end
    alias :entering_variable_index :pivot_column_index

    def leaving_variable_index
      if pivot_row_index
        basic_variable_indices[pivot_row_index]
      end
    end

    def pivot_element
      constraints_matrix[pivot_row_index][pivot_column_index]
    end

    def pivot_ratio
      Rational(1, pivot_element)
    end

    def non_basic_variable_indices
      variable_indices - basic_variable_indices
    end

    def prepare_to_pivot
      @next_pivot = {}

      next_pivot[:column_index] = determine_entering_variable_index
      next_pivot[:row_index] = determine_pivot_row_index
    end

    def determine_entering_variable_index
      column_indices = determine_indices_of_pivot_column_candidates

      fire :determine_entering_variable_index, column_indices

      if standard_problem?
        column_indices.
          select { |index| objective_vector[index] < 0 }.
          min_by { |index| objective_vector[index] }
      else
        # Choose an arbitrary column
        column_indices.first
      end
    end

    def determine_indices_of_pivot_column_candidates
      non_basic_variable_indices
    end

    def determine_pivot_row_index
      if pivot_column_index
        row_indices = determine_indices_of_pivot_row_candidates
        fire :determine_pivot_row_index, row_indices
        index_of_row_with_minimum_pivot_ratio(row_indices)
      end
    end

    def determine_indices_of_pivot_row_candidates
      if standard_problem?
        row_indices
      else
        row_indices_with_surplus_variables
      end
    end

    def index_of_row_with_minimum_pivot_ratio(row_indices)
      eligible_values = row_indices.map { |row_index|
        constraint_value = constraints_matrix[row_index][pivot_column_index]
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

    def updating_converted_basic_column_indices
      _leaving_variable_index = leaving_variable_index
      was_standard_problem = standard_problem?

      yield

      unless standard_problem?
        converted_basic_column_indices << _leaving_variable_index
        fire :add_leaving_variable_to_converted_basic_column_indices, _leaving_variable_index
      end

      if !was_standard_problem && standard_problem?
        fire :clear_converted_basic_column_indices
        converted_basic_column_indices.clear
      end
    end

    def swap_basic_variable
      _entering_variable_index = entering_variable_index
      _leaving_variable_index = leaving_variable_index

      fire :before_swap_basic_variable,
        entering_variable_index,
        leaving_variable_index

      basic_variable_indices[pivot_row_index] =
        entering_variable_index

      entering_column = categorized_constraint_columns[_entering_variable_index]
      entering_column[:basic] = {
        kind: :slack,
        row_index: pivot_row_index,
        value: pivot_element
      }

      leaving_column = categorized_constraint_columns[_leaving_variable_index]
      leaving_column.delete(:basic)
    end

    def divide_pivot_row_by_pivot_element(pivot_ratio)
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

    def adjust_non_pivot_rows_so_pivot_column_is_basic(pivot_ratio)
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

    def assemble_full_solution
      full_solution = Array.new(number_of_variables, 0)

      basic_variable_indices.
        each_with_index do |variable_index, rhs_value_index|
          value = categorized_constraint_columns[variable_index][:basic][:value]
          full_solution[variable_index] = value * rhs_values_vector[rhs_value_index]
        end

      full_solution
    end

    def assemble_solution
      solution = Array.new(number_of_non_free_variables, 0)

      basic_variable_indices.
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

    def rjust_including_color(value, max_length, padding)
      length = value.gsub(/\e\[\d+m/, '').length
      if length < max_length
        padding * (max_length - length) + value
      else
        value
      end
    end

    def inspect(description, value)
      inspected_value = ''
      PP.pp(value, inspected_value)
      inspected_value.chomp!
      if inspected_value =~ /\n/
        puts "#{description}:", inspected_value
      else
        puts "#{description}: #{inspected_value}"
      end
    end
  end
end
