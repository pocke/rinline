require 'securerandom'

require_relative "./rinline/version"
require_relative './rinline/ext/iseq_ext'
require_relative './rinline/ext/ast_ext'
require_relative './rinline/ext/method_ext'
require_relative './rinline/optimizer'
require_relative './rinline/location'
require_relative './rinline/runner'

module Rinline
  extend self

  def optimize(&block)
    runner = Runner.new
    Runner.current = runner
    block.call runner
    Runner.current = nil

    $stderr.puts "[Rinline] Optimizing is finised" if runner.debug
  end
end
