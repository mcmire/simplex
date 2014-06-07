require 'minitest/autorun'

$:.push(File.expand_path("../../lib", __FILE__))
require 'simplex'

class SimplexTest < Minitest::Test
  def test_2x2
    problem = Simplex.maximization_problem do |p|
      p.objective_coefficients = [1, 1]
      p.add_constraint(
        coefficients: [2, 1],
        operator: :<=,
        rhs_value: 4
      )
      p.add_constraint(
        coefficients: [1, 2],
        operator: :<=,
        rhs_value: 3
      )
    end

    solution = problem.solve
    assert_equal [Rational(5, 3), Rational(2, 3)], solution
  end

  def test_2x2_b
    problem = Simplex.maximization_problem do |p|
      p.objective_coefficients = [3, 4]
      p.add_constraint(
        coefficients: [1, 1],
        operator: :<=,
        rhs_value: 4
      )
      p.add_constraint(
        coefficients: [2, 1],
        operator: :<=,
        rhs_value: 5
      )
    end

    solution = problem.solve
    assert_equal [0, 4], solution
  end

  def test_2x2_c
    problem = Simplex.maximization_problem do |p|
      p.objective_coefficients = [2, -1]
      p.add_constraint(
        coefficients: [1, 2],
        operator: :<=,
        rhs_value: 6
      )
      p.add_constraint(
        coefficients: [3, 2],
        operator: :<=,
        rhs_value: 12
      )
    end

    solution = problem.solve
    assert_equal [4, 0], solution
  end

  def test_3x3_a
    problem = Simplex.maximization_problem do |p|
      p.objective_coefficients = [60, 90, 300]
      p.add_constraint(
        coefficients: [1, 1, 1],
        operator: :<=,
        rhs_value: 600
      )
      p.add_constraint(
        coefficients: [1, 3, 0],
        operator: :<=,
        rhs_value: 600
      )
      p.add_constraint(
        coefficients: [2, 0, 1],
        operator: :<=,
        rhs_value: 600
      )
    end
    solution = problem.solve
    assert_equal [0, 0, 600], solution
  end

  def test_3x3_b
    problem = Simplex.maximization_problem do |p|
      p.objective_coefficients = [70, 210, 140]
      p.add_constraint(
        coefficients: [1, 1, 1],
        operator: :<=,
        rhs_value: 100
      )
      p.add_constraint(
        coefficients: [5, 4, 4],
        operator: :<=,
        rhs_value: 480
      )
      p.add_constraint(
        coefficients: [40, 20, 30],
        operator: :<=,
        rhs_value: 3200
      )
    end
    solution = problem.solve
    assert_equal [0, 100, 0], solution
  end

  def test_3x3_c
    problem = Simplex.maximization_problem do |p|
      p.objective_coefficients = [2, -1, 2]
      p.add_constraint(
        coefficients: [2, 1, 0],
        operator: :<=,
        rhs_value: 10
      )
      p.add_constraint(
        coefficients: [1, 2, -2],
        operator: :<=,
        rhs_value: 20
      )
      p.add_constraint(
        coefficients: [0, 1, 2],
        operator: :<=,
        rhs_value: 5
      )
    end
    solution = problem.solve
    assert_equal [5, 0, Rational(5, 2)], solution
  end

  def test_3x3_d
    problem = Simplex.maximization_problem do |p|
      p.objective_coefficients = [11, 16, 15]
      p.add_constraint(
        coefficients: [1, 2, Rational(3, 2)],
        operator: :<=,
        rhs_value: 12_000
      )
      p.add_constraint(
        coefficients: [Rational(2, 3), Rational(2, 3), 1],
        operator: :<=,
        rhs_value: 4_600
      )
      p.add_constraint(
        coefficients: [Rational(1, 2), Rational(1, 3), Rational(1, 2)],
        operator: :<=,
        rhs_value: 2_400
      )
    end
    solution = problem.solve
    assert_equal [600, 5_100, 800], solution
  end

  def test_3x3_e
    problem = Simplex.maximization_problem do |p|
      p.objective_coefficients = [5, 4, 3]
      p.add_constraint(
        coefficients: [2, 3, 1],
        operator: :<=,
        rhs_value: 5
      )
      p.add_constraint(
        coefficients: [4, 1, 2],
        operator: :<=,
        rhs_value: 11
      )
      p.add_constraint(
        coefficients: [3, 4, 2],
        operator: :<=,
        rhs_value: 8
      )
    end
    solution = problem.solve
    assert_equal [2, 0, 1], solution
  end

  def test_3x3_f
    problem = Simplex.maximization_problem do |p|
      p.objective_coefficients = [3, 2, -4]
      p.add_constraint(
        coefficients: [1, 4, 0],
        operator: :<=,
        rhs_value: 5
      )
      p.add_constraint(
        coefficients: [2, 4, -2],
        operator: :<=,
        rhs_value: 6
      )
      p.add_constraint(
        coefficients: [1, 1, -2],
        operator: :<=,
        rhs_value: 2
      )
    end
    solution = problem.solve
    assert_equal [4, 0, 1], solution
  end

  def test_3x3_g
    problem = Simplex.maximization_problem do |p|
      p.objective_coefficients = [2, -1, 8]
      p.add_constraint(
        coefficients: [2, -4, 6],
        operator: :<=,
        rhs_value: 3
      )
      p.add_constraint(
        coefficients: [-1, 3, 4],
        operator: :<=,
        rhs_value: 2
      )
      p.add_constraint(
        coefficients: [0, 0, 2],
        operator: :<=,
        rhs_value: 1
      )
    end
    solution = problem.solve
    assert_equal [Rational(17, 2), Rational(7,2), 0], solution
  end

  def test_3x4
    problem = Simplex.maximization_problem do |p|
      p.objective_coefficients = [100_000, 40_000, 18_000]
      p.add_constraint(
        coefficients: [20, 6, 3],
        operator: :<=,
        rhs_value: 182
      )
      p.add_constraint(
        coefficients: [0, 1, 0],
        operator: :<=,
        rhs_value: 10
      )
      p.add_constraint(
        coefficients: [-1, -1, 1],
        operator: :<=,
        rhs_value: 0
      )
      p.add_constraint(
        coefficients: [-9, 1, 1],
        operator: :<=,
        rhs_value: 0
      )
    end

    solution = problem.solve
    assert_equal [4, 10, 14], solution
  end

  def test_4x4
    problem = Simplex.maximization_problem do |p|
      p.objective_coefficients = [1, 2, 1, 2]
      p.add_constraint(
        coefficients: [1, 0, 1, 0],
        operator: :<=,
        rhs_value: 1
      )
      p.add_constraint(
        coefficients: [0, 1, 0, 1],
        operator: :<=,
        rhs_value: 4
      )
      p.add_constraint(
        coefficients: [1, 1, 0, 0],
        operator: :<=,
        rhs_value: 2
      )
      p.add_constraint(
        coefficients: [0, 0, 1, 1],
        operator: :<=,
        rhs_value: 2
      )
    end
    solution = problem.solve
    assert_equal [0, 2, 0, 2], solution
  end

  def test_cycle
    problem = Simplex.maximization_problem do |p|
      p.objective_coefficients = [10, -57, -9, -24]
      p.add_constraint(
        coefficients: [0.5, -5.5, -2.5, 9],
        operator: :<=,
        rhs_value: 0
      )
      p.add_constraint(
        coefficients: [0.5, -1.5, -0.5, 1],
        operator: :<=,
        rhs_value: 0
      )
      p.add_constraint(
        coefficients: [1, 0, 0, 0],
        operator: :<=,
        rhs_value: 1
      )
    end

    solution = problem.solve
    assert_equal [1, 0, 1, 0], solution
  end

  def test_cycle2
    problem = Simplex.maximization_problem do |p|
      p.objective_coefficients = [2, 3, -1, -12]
      p.add_constraint(
        coefficients: [-2, -9, 1, 9],
        operator: :<=,
        rhs_value: 0
      )
      p.add_constraint(
        coefficients: [Rational(1, 3), 1, Rational(-1, 3), -2],
        operator: :<=,
        rhs_value: 0
      )
    end
    assert_raises Simplex::UnboundedProblem do
      problem.solve
    end
  end

  def test_error_mismatched_dimensions
    assert_raises ArgumentError do
      Simplex.maximization_problem do |p|
        p.objective_coefficients = [10, -57, -9]
        p.add_constraint(
          coefficients: [0.5, -5.5, -2.5, 9],
          operator: :<=,
          rhs_value: 0
        )
        p.add_constraint(
          coefficients: [0.5, -1.5, -0.5, 1],
          operator: :<=,
          rhs_value: 0
        )
        p.add_constraint(
          coefficients: [1, 0, 0, 0],
          operator: :<=,
          rhs_value: 1
        )
      end
    end

    assert_raises ArgumentError do
      Simplex.maximization_problem do |p|
        p.objective_coefficients = [10, -57, -9, 2]
        p.add_constraint(
          coefficients: [0.5, -5.5, 9, 4],
          operator: :<=,
          rhs_value: 0
        )
        p.add_constraint(
          coefficients: [0.5, -1.5, 1],
          operator: :<=,
          rhs_value: 0
        )
        p.add_constraint(
          coefficients: [1, 0, 0],
          operator: :<=,
          rhs_value: 1
        )
      end
    end
  end

  def test_manual_iteration
    problem = Simplex.maximization_problem do |p|
      p.objective_coefficients = [10, -57, -9, -24]
      p.add_constraint(
        coefficients: [0.5, -5.5, -2.5, 9],
        operator: :<=,
        rhs_value: 0
      )
      p.add_constraint(
        coefficients: [0.5, -1.5, -0.5, 1],
        operator: :<=,
        rhs_value: 0
      )
      p.add_constraint(
        coefficients: [1, 0, 0, 0],
        operator: :<=,
        rhs_value: 1
      )
    end

    while problem.can_improve?
      assert problem.formatted_tableau.is_a?(String)
      problem.pivot
    end

    solution = problem.solve
    assert_equal [1, 0, 1, 0], solution
  end

  def test_cup_factory
    problem = Simplex.maximization_problem do |p|
      p.objective_coefficients = [25, 20]
      p.add_constraint(
        coefficients: [20, 12],
        operator: :<=,
        rhs_value: 1800
      )
      p.add_constraint(
        coefficients: [1, 1],
        operator: :<=,
        rhs_value: 8 * 15
      )
    end
    solution = problem.solve
    assert_equal [45, 75], solution
  end

  def test_unbounded
    problem = Simplex.maximization_problem do |p|
      p.objective_coefficients = [1, 1, 1]
      p.add_constraint(
        coefficients: [3, 1, -2],
        operator: :<=,
        rhs_value: 5
      )
      p.add_constraint(
        coefficients: [4, 3, 0],
        operator: :<=,
        rhs_value: 7
      )
    end
    assert_raises Simplex::UnboundedProblem do
      problem.solve
    end
  end

  def test_minimization_problem
    problem = Simplex.minimization_problem do |p|
      p.objective_coefficients = [Rational(3, 25), Rational(3, 20)]
      p.add_constraint(
        coefficients: [60, 60],
        operator: :>=,
        rhs_value: 300
      )
      p.add_constraint(
        coefficients: [12, 6],
        operator: :>=,
        rhs_value: 36
      )
      p.add_constraint(
        coefficients: [10, 30],
        operator: :>=,
        rhs_value: 90
      )
    end

    solution = problem.solve
    assert_equal [3, 2], solution
  end
end
