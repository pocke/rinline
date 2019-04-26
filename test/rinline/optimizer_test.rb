require 'test_helper'

class OptimizerTest < Minitest::Test
  def test_optimize
    klass = Class.new do
      def foo
        bar + "cat"
      end

      def bar
        "dog"
      end
    end

    optimized = Rinline::Optimizer.optimize(klass, :foo)
    assert_equal 'def foo
        ("dog") + "cat"
      end', optimized
  end

  def test_optimize_with_recursion
    klass = Class.new do
      def foo
        foo + "cat"
      end
    end

    optimized = Rinline::Optimizer.optimize(klass, :foo)
    assert_nil optimized
  end

  def test_optimize_with_multibytes
    klass = Class.new do
      def hello
        "こんにちは、" + name
      end

      def name
        "ぽっけ"
      end
    end

    optimized = Rinline::Optimizer.optimize(klass, :hello)
    assert_equal 'def hello
        "こんにちは、" + ("ぽっけ")
      end', optimized
  end
end
