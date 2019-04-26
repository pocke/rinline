require_relative "./rinline/version"
require_relative './rinline/ext/method_ext'
require_relative './rinline/ext/ast_ext'
require_relative './rinline/ext/iseq_ext'
require_relative './rinline/optimizer'

module Rinline
  # FIXME
  extend self

  def optimize_instance_method(klass, method_name)
    Optimizer.optimize(klass, method_name)
  end
end
