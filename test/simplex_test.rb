require 'minitest/autorun'

$:.push(File.expand_path("../../lib", __FILE__))
require 'simplex'

class SimplexTest < Minitest::Test
  def test_2x2
    result = Simplex.maximization_problem(
      objective_coefficients: [1, 1],
      constraints: [
        [ 2,  1],
        [ 1,  2],
      ],
      rhs_values: [4, 3]
    ).solution
    assert_equal [Rational(5, 3), Rational(2, 3)], result
  end

  def test_2x2_b
    result = Simplex.maximization_problem(
      objective_coefficients: [3, 4],
      constraints: [
        [ 1,  1],
        [ 2,  1],
      ],
      rhs_values: [4, 5]
    ).solution
    assert_equal [0, 4], result
  end

  def test_2x2_c
    result = Simplex.maximization_problem(
      objective_coefficients: [2, -1],
      constraints: [
        [ 1,  2],
        [ 3,  2],
      ],
      rhs_values: [6, 12]
    ).solution
    assert_equal [4, 0], result
  end

  def test_3x3_a
    result = Simplex.maximization_problem(
      objective_coefficients: [60, 90, 300],
      constraints: [
        [1, 1, 1],
        [1, 3, 0],
        [2, 0, 1]
      ],
      rhs_values: [600, 600, 900]
    ).solution
    assert_equal [0, 0, 600], result
  end

  def test_3x3_b
    result = Simplex.maximization_problem(
      objective_coefficients: [70, 210, 140],
      constraints: [
        [ 1,  1,  1],
        [ 5,  4,  4],
        [40, 20, 30]
      ],
      rhs_values: [100, 480, 3200]
    ).solution
    assert_equal [0, 100, 0], result
  end

  def test_3x3_c
    result = Simplex.maximization_problem(
      objective_coefficients: [2, -1, 2],
      constraints: [
        [ 2,  1,  0],
        [ 1,  2, -2],
        [ 0,  1,  2]
      ],
      rhs_values: [10, 20, 5]
    ).solution
    assert_equal [5, 0, Rational(5, 2)], result
  end

  def test_3x3_d
    result = Simplex.maximization_problem(
      objective_coefficients: [11, 16, 15],
      constraints: [
        [             1,              2, Rational(3, 2)],
        [Rational(2, 3), Rational(2, 3),              1],
        [Rational(1, 2), Rational(1, 3), Rational(1, 2)]
      ],
      rhs_values: [12_000, 4_600, 2_400]
    ).solution
    assert_equal [600, 5_100, 800], result
  end

  def test_3x3_e
    simplex = Simplex.maximization_problem(
      objective_coefficients: [5, 4, 3],
      constraints: [
        [2, 3, 1],
        [4, 1, 2],
        [3, 4, 2]
      ],
      rhs_values: [5, 11, 8]
    )
    assert_equal [2, 0, 1], simplex.solution
  end

  def test_3x3_f
    simplex = Simplex.maximization_problem(
      objective_coefficients: [3, 2, -4],
      constraints: [
        [1, 4, 0],
        [2, 4,-2],
        [1, 1,-2]
      ],
      rhs_values: [5, 6, 2]
    )
    assert_equal [4, 0, 1], simplex.solution
  end

  def test_3x3_g
    simplex = Simplex.maximization_problem(
      objective_coefficients: [2, -1, 8],
      constraints: [
        [2, -4, 6],
        [-1, 3, 4],
        [0, 0, 2]
      ],
      rhs_values: [3, 2, 1]
    )
    assert_equal [Rational(17, 2), Rational(7,2), 0], simplex.solution
  end

  def test_3x4
    result = Simplex.maximization_problem(
      objective_coefficients: [100_000, 40_000, 18_000],
      constraints: [
        [20, 6, 3],
        [ 0, 1, 0],
        [-1,-1, 1],
        [-9, 1, 1]
      ],
      rhs_values: [182, 10, 0, 0]
    ).solution
    assert_equal [4, 10, 14], result
  end

  def test_4x4
    result = Simplex.maximization_problem(
      objective_coefficients: [1, 2, 1, 2],
      constraints: [
        [1, 0, 1, 0],
        [0, 1, 0, 1],
        [1, 1, 0, 0],
        [0, 0, 1, 1]
      ],
      rhs_values: [1, 4, 2, 2]
    ).solution
    assert_equal [0, 2, 0, 2], result
  end

  def test_cycle
    result = Simplex.maximization_problem(
      objective_coefficients: [10, -57, -9, -24],
      constraints: [
        [0.5, -5.5, -2.5, 9],
        [0.5, -1.5, -0.5, 1],
        [  1,    0,    0, 0]
      ],
      rhs_values: [0, 0, 1]
    ).solution
    assert_equal [1, 0, 1, 0], result
  end

  def test_cycle2
    simplex = Simplex.maximization_problem(
      objective_coefficients: [2, 3, -1, -12],
      constraints: [
        [-2, -9, 1, 9],
        [Rational(1, 3), 1, Rational(-1, 3), -2],
      ],
      rhs_values: [0, 0]
    )
    assert_raises Simplex::UnboundedProblem do
      simplex.solution
    end
  end

  def test_error_mismatched_dimensions
    assert_raises ArgumentError do
      result = Simplex.maximization_problem(
        objective_coefficients: [10, -57, -9],
        constraints: [
          [0.5, -5.5, -2.5, 9],
          [0.5, -1.5, -0.5, 1],
          [  1,    0,    0, 0]
        ],
        rhs_values: [0, 0, 1]
      )
    end

    assert_raises ArgumentError do
      result = Simplex.maximization_problem(
        objective_coefficients: [10, -57, -9, 2],
        constraints: [
          [0.5, -5.5, 9, 4],
          [0.5, -1.5, 1],
          [  1,    0, 0]
        ],
        rhs_values: [0, 0, 1]
      )
    end

    assert_raises ArgumentError do
      result = Simplex.maximization_problem(
        objective_coefficients: [10, -57, -9, 2],
        constraints: [
          [0.5, -5.5, 9, 4],
          [0.5, -1.5, 1, 5],
          [  1,    0, 0, 5]
        ],
        rhs_values: [0, 1]
      )
    end
  end

  def test_manual_iteration
    simplex = Simplex.maximization_problem(
      objective_coefficients: [10, -57, -9, -24],
      constraints: [
        [0.5, -5.5, -2.5, 9],
        [0.5, -1.5, -0.5, 1],
        [  1,    0,    0, 0]
      ],
      rhs_values: [0, 0, 1]
    )
    while simplex.can_improve?
      assert simplex.formatted_tableau.is_a?(String)
      simplex.pivot
    end
    result = simplex.solution
    assert_equal [1, 0, 1, 0], result
  end

  def test_cup_factory
    result = Simplex.maximization_problem(
      objective_coefficients: [25, 20],
      constraints: [
        [20, 12],
        [1, 1]
      ],
      rhs_values: [1800, 8*15]
    )
    assert_equal [45, 75], result.solution
  end

  #def test_infeasible1
  #  simplex = Simplex.maximization_problem(
  #    [2, -1],
  #    [
  #      [1, -1],
  #      [-1, 1]
  #    ],
  #    [1, -2]
  #  )
  #  while simplex.can_improve?
  #    puts 
  #    puts simplex.formatted_tableau
  #    simplex.pivot
  #  end
  #  p :done
  #  puts 
  #  puts simplex.formatted_tableau

  #end
  
  def test_unbounded
    simplex = Simplex.maximization_problem(
      objective_coefficients: [1, 1, 1],
      constraints: [
        [3, 1, -2],
        [4, 3, 0]
      ],
      rhs_values: [5, 7]
    )
    assert_raises Simplex::UnboundedProblem do
      simplex.solution
    end
  end

  def test_minimization_problem
    puts 'minimizing'
    simplex = Simplex.minimization_problem(
      objective_coefficients: [0.12, 0.15],
      constraints: [
        [60, 60],
        [12, 6],
        [10, 30]
      ],
      rhs_values: [300, 36, 90]
    )
    result = simplex.solution
    require 'pp'
    pp result: result
    puts simplex.formatted_tableau
    #assert_equal [3, 2], result

    puts 'maximizing'
    simplex = Simplex.maximization_problem(
      objective_coefficients: [0.12, 0.15],
      constraints: [
        [60, 60],
        [12, 6],
        [10, 30]
      ],
      rhs_values: [300, 36, 90]
    )
    result = simplex.solution
    require 'pp'
    pp result: result
    puts simplex.formatted_tableau
    #assert_equal [3, 2], result
  end
end
