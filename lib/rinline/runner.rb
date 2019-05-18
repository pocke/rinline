module Rinline
  class Runner
    class << self
      attr_accessor :current
    end

    attr_accessor :debug, :iseq_threshold
    attr_reader :file_cache

    def initialize
      @debug = false
      @iseq_threshold = 50
      @file_cache = {}
    end

    def optimize_instance_method(klass, method_name)
      debug_print "optimizing: #{klass}##{method_name}"
      optimized = Optimizer.optimize(klass, method_name)
      unless optimized
        debug_print "skipped: #{klass}##{method_name}"
        return
      end

      klass.class_eval "undef :#{method_name}; #{optimized}"
      debug_print "optimized: #{klass}##{method_name}"
    end

    def optimize_instance_methods(klass)
      klass.instance_methods(false).each do |method|
        optimize_instance_method(klass, method)
      end
    end

    def optimize_class(klass)
      debug_print "class: #{klass}"
      optimize_instance_methods(klass)
      optimize_instance_methods(klass.singleton_class)
    end

    alias optimize_module optimize_class

    def optimize_namespace(mod)
      debug_print "namespace: #{mod}"
      optimize_module(mod)
      constants = mod.constants
      constants -= Struct.constants if mod < Struct
      constants.each do |child|
        child = mod.const_get(child)
        optimize_namespace(child) if child.is_a?(Module)
      end
    end

    def debug_print(*msg)
      $stderr.puts(*msg) if debug
    end
  end
end
