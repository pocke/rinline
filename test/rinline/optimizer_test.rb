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

  def test_optimize_many_times
    klass = Class.new do
      def foo
        bar + baz +
          f + g
      end

      def bar
        "x"
      end

      def baz
        "y"
      end

      def f
        "foo
        bar"
      end

      def g
        "xxx"
      end
    end

    optimized = Rinline::Optimizer.optimize(klass, :foo)
    assert_equal 'def foo
        ("x") + ("y") +
          ("foo
        bar") + ("xxx")
      end', optimized
  end

  def test_optimize_with_c_method
    klass = Class.new do
      def foo
        puts
        bar
      end

      def bar
        "foobar"
      end
    end

    optimized = Rinline::Optimizer.optimize(klass, :foo)
    assert_equal 'def foo
        puts
        ("foobar")
      end', optimized
  end

  def test_optimize_with_multi_sentences
    klass = Class.new do
      def foo
        bar + 1
      end

      def bar
        p 2
        2
      end
    end

    optimized = Rinline::Optimizer.optimize(klass, :foo)
    assert_equal 'def foo
        (p 2
        2) + 1
      end', optimized
  end
end
