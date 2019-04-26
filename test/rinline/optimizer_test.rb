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
        "dog" + "cat"
      end', optimized
  end
end
