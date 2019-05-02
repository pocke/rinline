require 'securerandom'

require_relative "./rinline/version"
require_relative './rinline/ext/iseq_ext'
require_relative './rinline/ext/ast_ext'
require_relative './rinline/ext/method_ext'
require_relative './rinline/optimizer'
require_relative './rinline/location'
require_relative './rinline/runner'

module Rinline
  # FIXME
  extend self

  def self.optimize(&block)
    runner = Runner.new
    block.call runner
  end

  def debug?
    ENV['RINLINE_DEBUG']
  end

  def debug_print(*msg)
    $stderr.puts(*msg) if debug?
  end
end
