require 'securerandom'

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

  def optimize_instance_methods(klass)
    klass.instance_methods(false).each do |method|
      optimize_instance_method(klass, method)
    end
  end

  def optimize_klass(klass)
    optimize_instance_methods(klass)
    optimize_instance_methods(klass.singleton_class)
  end

  alias optimize_module optimize_klass

  def optimize_namespace(mod)
    optimize_module(mod)
    mod.constants.each do |child|
      child = mod.const_get(child)
      optimize_namespace(child) if child.is_a?(Module)
    end
  end
end
