require 'matrix'

class Vector
  public :[]=
end

class Simplex
  DEFAULT_MAX_PIVOTS = 10_000

  class UnboundedProblem < StandardError
  end

  attr_accessor :max_pivots

  def initialize(coefficients, constraints, rhs_values)
    @pivot_count = 0
    @max_pivots = DEFAULT_MAX_PIVOTS

    # Problem dimensions
    @num_non_slack_vars = constraints.first.length
    @num_constraints    = rhs_values.length
    @num_vars           = @num_non_slack_vars + @num_constraints

    # Set up initial matrix A and vectors rhs_values, coefficients
    @objective_coefficients = Vector[*coefficients.map {|coefficient| -1*coefficient } + [0]*@num_constraints]
    @constraints = constraints.map {|constraint| Vector[*(constraint.clone + [0]*@num_constraints)]}
    @rhs_values = Vector[*rhs_values.clone]

    unless @constraints.all? {|constraints| constraints.size == @objective_coefficients.size } and @rhs_values.size == @constraints.length
      raise ArgumentError, "Input arrays have mismatched dimensions" 
    end

    0.upto(@num_constraints - 1) {|i| @constraints[i][@num_non_slack_vars + i] = 1 }

    # set initial solution: all non-slack variables = 0
    @solution          = Vector[*([0]*@num_vars)]
    @basic_vars = (@num_non_slack_vars...@num_vars).to_a
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
        @constraints[row_ix][basic_var] == 1
      end
      @solution[basic_var] = @rhs_values[row_with_1]
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
    (0...@objective_coefficients.size).to_a
  end

  def entering_variable
    variables.select { |var| @objective_coefficients[var] < 0 }.
              min_by { |var| @objective_coefficients[var] }
  end

  def pivot
    pivot_column = entering_variable
    pivot_row    = pivot_row(pivot_column)
    raise UnboundedProblem unless pivot_row
    leaving_var  = basic_variable_in_row(pivot_row)
    replace_basic_variable(leaving_var => pivot_column)

    pivot_ratio = Rational(1, @constraints[pivot_row][pivot_column])

    # update pivot row
    @constraints[pivot_row] *= pivot_ratio
    @rhs_values[pivot_row] = pivot_ratio * @rhs_values[pivot_row]

    # update objective
    @objective_coefficients -= @objective_coefficients[pivot_column] * @constraints[pivot_row]

    # update A and B
    (row_indices - [pivot_row]).each do |row_ix|
      r = @constraints[row_ix][pivot_column]
      @constraints[row_ix] -= r * @constraints[pivot_row]
      @rhs_values[row_ix] -= r * @rhs_values[pivot_row]
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
      [row_ix, @constraints[row_ix][column_ix], @rhs_values[row_ix]]
    }.reject { |_, constraints, rhs_values|
      constraints == 0
    }.reject { |_, constraints, rhs_values|
      (rhs_values < 0) ^ (constraints < 0) # negative sign check
    }
    row_ix, _, _ = *last_min_by(row_ix_a_and_b) { |_, constraints, rhs_values|
      Rational(rhs_values, constraints)
    }
    row_ix
  end

  def basic_variable_in_row(pivot_row)
    column_indices.detect do |column_ix|
      @constraints[pivot_row][column_ix] == 1 and @basic_vars.include?(column_ix)
    end
  end

  def row_indices
    (0...@constraints.length).to_a
  end

  def column_indices
    (0...@constraints.first.size).to_a
  end

  def formatted_tableau
    if can_improve?
      pivot_column = entering_variable
      pivot_row    = pivot_row(pivot_column)
    else
      pivot_row = nil
    end
    num_cols = @objective_coefficients.size + 1
    coefficients = formatted_values(@objective_coefficients.to_a)
    rhs_values = formatted_values(@rhs_values.to_a)
    constraints = @constraints.to_a.map {|ar| formatted_values(ar.to_a) }
    if pivot_row
      constraints[pivot_row][pivot_column] = "*" + constraints[pivot_row][pivot_column]
    end
    max = (coefficients + rhs_values + constraints + ["1234567"]).flatten.map(&:size).max
    result = []
    result << coefficients.map {|coefficients| coefficients.rjust(max, " ") }
    constraints.zip(rhs_values) do |constraint_row, rhs_value|
      result << (constraint_row + [rhs_value]).map {|constraints| constraints.rjust(max, " ") }
      result.last.insert(constraint_row.length, "|")
    end
    lines = result.map {|rhs_values| rhs_values.join("  ") }
    max_line_length = lines.map(&:length).max
    lines.insert(1, "-"*max_line_length)
    lines.join("\n")
  end

  def formatted_values(array)
    array.map {|coefficients| "%2.3f" % coefficients }
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

