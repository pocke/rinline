require_relative "./rinline/version"
require_relative './rinline/ext/method_ext'
require_relative './rinline/ext/ast_ext'
require_relative './rinline/ext/iseq_ext'
require_relative './rinline/optimizer'
require_relative './rinline/location'

module Rinline
  # FIXME
  extend self

  def optimize_instance_method(klass, method_name)
    optimized = Optimizer.optimize(klass, method_name)
    klass.class_eval "undef :#{method_name}; #{optimized}" if optimized
  end
end
