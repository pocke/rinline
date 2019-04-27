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

  def test_optimize_with_empty_method
    klass = Class.new do
      def foo
        bar
      end

      def bar
      end
    end

    optimized = Rinline::Optimizer.optimize(klass, :foo)
    assert_equal 'def foo
        ()
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

  def test_optimize_fcall
    stub(SecureRandom).hex { "hexhex" }

    klass = Class.new do
      def foo
        x = 2
        bar(10, 4) + x
      end

      def bar(x, y)
        x * y
      end
    end

    optimized = Rinline::Optimizer.optimize(klass, :foo)
    assert_equal 'def foo
        x = 2
        (x__hexhex = 10;y__hexhex = 4;(x__hexhex) * (y__hexhex)) + x
      end', optimized
  end

  def test_optimize_fcall_with_nest
    stub(SecureRandom).hex { "hexhex" }

    klass = Class.new do
      def foo
        bar(baz)
      end

      def bar(x)
        p x
      end

      def baz(y)
        p y
      end
    end

    optimized = Rinline::Optimizer.optimize(klass, :foo)
    assert_equal 'def foo
        (x__hexhex = baz;p (x__hexhex))
      end', optimized
  end

  def test_optimize_fcall_with_splat
    stub(SecureRandom).hex { "hexhex" }

    klass = Class.new do
      def foo
        x = []
        bar(10, *x)
      end

      def bar(x, *y)
        p x, y
      end
    end

    optimized = Rinline::Optimizer.optimize(klass, :foo)
    assert_nil optimized
  end

  def test_optimize_opcall
    stub(SecureRandom).hex { "hexhex" }

    klass = Class.new do
      def foo
        x = 2
        bar(x)
      end

      def bar(x)
        x += 1
        x %= 2
        x
      end
    end

    optimized = Rinline::Optimizer.optimize(klass, :foo)
    assert_equal 'def foo
        x = 2
        (x__hexhex = x;x__hexhex += 1
        x__hexhex %= 2
        (x__hexhex))
      end', optimized
  end

  def test_optimize_with_modifiers
    stub(SecureRandom).hex { "hexhex" }

    klass = Class.new do
      def foo
        x = 2
        bar(x, 3)
        baz(3, x)
      end

      def bar(x, y)
        x if y
        x unless y
      end

      def baz(x, y)
        x while y
        x until y
      end
    end

    optimized = Rinline::Optimizer.optimize(klass, :foo)
    assert_equal 'def foo
        x = 2
        (x__hexhex = x;y__hexhex = 3;(x__hexhex) if (y__hexhex)
        (x__hexhex) unless (y__hexhex))
        (x__hexhex = 3;y__hexhex = x;(x__hexhex) while (y__hexhex)
        (x__hexhex) until (y__hexhex))
      end', optimized
  end

  def test_optimize_with_modifier_2
    stub(SecureRandom).hex { "hexhex" }

    klass = Class.new do
      def foo
        bar(1)
      end

      def bar(x)
        baz(x) if @something <= x
      end
    end

    optimized = Rinline::Optimizer.optimize(klass, :foo)
    assert_equal 'def foo
        (x__hexhex = 1;baz((x__hexhex)) if @something <= (x__hexhex))
      end', optimized
  end

  def test_optimize_with_not_defined_method
    klass = Class.new do
      def foo
        bar
      end
    end

    optimized = Rinline::Optimizer.optimize(klass, :foo)
    assert_nil optimized
  end

  def test_optimize_with_return
    klass = Class.new do
      def foo
        bar
      end

      def bar
        if foo
          return 1
        end
      end
    end

    optimized = Rinline::Optimizer.optimize(klass, :foo)
    assert_nil optimized
  end
end
