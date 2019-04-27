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
      path = method.absolute_path
      replacements = []

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
          to_code = "(#{replace_lvar(to_ast.method_body, to_path)})"
          replacements << {
            from: node.location(path),
            to: to_code,
          }
        end
      end

      return if replacements.empty?
      return replace(ast, path, replacements).force_encoding(Encoding::UTF_8) # TODO: Support other encodings
    end

    attr_reader :klass, :method_name, :method
    private :klass, :method_name, :method

    # @param original_method [Method]
    # @param replacements [Array<{from: Rinline::Location, to: String}>]
    private def replace(original_ast, original_path, replacements)
      ret = original_ast.to_source(original_path)
      offset = -original_ast.location(original_path).first_index

      replacements.each do |replacement|
        from = replacement[:from]
        to_code = replacement[:to]

        ret[(from.first_index + offset)..(from.last_index + offset)] = to_code
        offset += to_code.size - from.size
      end

      ret
    end

    private def replace_lvar(ast, path)
      replacements = []
      lvar_suffix = "__#{SecureRandom.hex(5)}"

      ast.traverse do |node|
        case node.type
        when :LASGN
          replacements << {
            from: node.location_variable_name_of_lasgn(path),
            to: "#{node.children[0]}#{lvar_suffix}",
          }
        when :LVAR
          replacements << {
            from: node.location(path),
            to: "(#{node.children[0]}#{lvar_suffix})"
          }
        end
      end

      replace(ast, path, replacements)
    end
  end
end
