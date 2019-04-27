module Rinline
  class Optimizer
    using Ext::MethodExt
    using Ext::AstExt
    using Ext::IseqExt

    # @param klass [Class]
    # @param method_name [Symbol] an instance method name
    # @return [String,nil] optimized code if optimized
    def self.optimize(klass, method_name)
      self.new(klass, method_name).optimize
    end

    def initialize(klass, method_name)
      @klass = klass
      @method_name = method_name
      @method = klass.instance_method(method_name)
    end

    def optimize
      ast = method.to_ast
      replacements = []
      lvar_replacements = []
      path = method.absolute_path

      ast.traverse do |node|
        case node.type
        when :VCALL
          target_method_name = node.children[0]
          next if method_name == target_method_name
          target_method = klass.instance_method(target_method_name)
          next unless target_method.ruby_method?
          target_iseq = target_method.to_iseq
          next unless target_iseq.short?

          to_ast = target_method.to_ast
          to_path = target_method.absolute_path
          to_code = "(#{method_body_ast(to_ast).to_source(to_path)})"
          replacements << {
            from: node.location(path),
            to: to_code,
          }
        when :LASGN
          # TODO
        end
      end

      return if replacements.empty?
      return replace(method, replacements + lvar_replacements)
    end

    attr_reader :klass, :method_name, :method
    private :klass, :method_name, :method

    private def method_body_ast(method_ast)
      method_ast.children[2]
    end

    # @param original_method [Method]
    # @param replacements [Array<{from: Rinline::Location, to: String}>]
    private def replace(original_method, replacements)
      original_ast = original_method.to_ast
      original_path = original_method.absolute_path
      ret = original_ast.to_source(original_path)
      offset = -original_ast.location(original_path).first_index

      replacements.each do |replacement|
        from = replacement[:from]
        to_code = replacement[:to]

        ret[(from.first_index + offset)..(from.last_index + offset)] = to_code
        offset += to_code.size - from.size
      end

      ret.force_encoding(Encoding::UTF_8) # TODO: Support other encodings
    end
  end
end
