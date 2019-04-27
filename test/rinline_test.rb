require 'test_helper'

class TestRinline < Minitest::Test
  def test_optimize_instance_method
    klass = Class.new do
      def foo
        bar + "cat"
      end

      def bar
        "dog"
      end
    end

    assert_equal "dogcat", klass.new.foo

    Rinline.optimize_instance_method(klass, :foo)

    assert_equal "dogcat", klass.new.foo
  end

  def test_optimize_instance_method_with_lvar
    klass = Class.new do
      def foo
        x = "cat"
        bar + x
      end

      def bar
        x = "dog"
        x
      end
    end

    assert_equal "dogcat", klass.new.foo

    Rinline.optimize_instance_method(klass, :foo)

    assert_equal "dogcat", klass.new.foo
  end

  def test_optimize_instance_method_with_fcall
    klass = Class.new do
      def foo
        x = 2
        bar(10, 4) + x
      end

      def bar(x, y)
        x * y
      end
    end

    assert_equal 42, klass.new.foo

    Rinline.optimize_instance_method(klass, :foo)

    assert_equal 42, klass.new.foo
  end
end
