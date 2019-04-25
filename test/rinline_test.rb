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
end
