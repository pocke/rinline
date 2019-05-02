module Rinline
  class Runner
    def optimize_instance_method(klass, method_name)
      Rinline.debug_print "optimizing: #{klass}##{method_name}"
      optimized = Optimizer.optimize(klass, method_name)
      unless optimized
        Rinline.debug_print "skipped: #{klass}##{method_name}"
        return
      end

      klass.class_eval "undef :#{method_name}; #{optimized}"
      Rinline.debug_print "optimized: #{klass}##{method_name}"
    end

    def optimize_instance_methods(klass)
      klass.instance_methods(false).each do |method|
        optimize_instance_method(klass, method)
      end
    end

    def optimize_class(klass)
      Rinline.debug_print "class: #{klass}"
      optimize_instance_methods(klass)
      optimize_instance_methods(klass.singleton_class)
    end

    alias optimize_module optimize_class

    def optimize_namespace(mod)
      Rinline.debug_print "namespace: #{mod}"
      optimize_module(mod)
      constants = mod.constants
      constants -= Struct.constants if mod < Struct
      constants.each do |child|
        child = mod.const_get(child)
        optimize_namespace(child) if child.is_a?(Module)
      end
    end
  end
end
