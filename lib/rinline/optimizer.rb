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
      return unless ast
      return if ast.has_child?(:CONST)
      path = method.absolute_path
      replacements = []

      ast.traverse do |node, opt|
        case node.type
        when :VCALL
          target_method_name = node.children[0]
          next if method_name == target_method_name
          target_method =
            begin
              klass.instance_method(target_method_name)
            rescue NameError
              next
            end
          next unless target_method.expandable?

          to_ast = target_method.to_ast
          next unless to_ast.expandable_method?(0)

          to_path = target_method.absolute_path
          body = to_ast.method_body
          to_code =
            if body
              "(#{replace_lvar(body, to_path)})"
            else
              "()"
            end
          replacements << {
            from: node.location(path),
            to: to_code,
          }
        when :FCALL
          target_method_name = node.children[0]
          next if method_name == target_method_name
          target_method =
            begin
              klass.instance_method(target_method_name)
            rescue NameError
              next
            end
          next unless target_method.expandable?

          to_ast = target_method.to_ast
          args = node.fcall_args
          next unless args&.type == :ARRAY
          next unless to_ast.expandable_method?(args.array_size)

          to_path = target_method.absolute_path
          lvar_suffix = gen_lvar_suffix

          args = assign_args(to_ast, node, path, lvar_suffix)
          body =
            if to_ast.method_body
              replace_lvar(to_ast.method_body, to_path, lvar_suffix: lvar_suffix)
            else
              "()"
            end
          to_code = "(#{args}#{body})"
          replacements << {
            from: node.location(path),
            to: to_code
          }
          opt[:ignore_index] = 1 # Ignore arguments
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

    private def replace_lvar(ast, path, lvar_suffix: gen_lvar_suffix)
      replacements = []

      ast.traverse do |node, opt|
        case node.type
        when :LASGN
          replacements << {
            from: node.location_variable_name_of_lasgn(path),
            to: "#{node.children[0]}#{lvar_suffix}",
          }
          # for op asgn. e.g. x += 1
          opt[:ignore_index] = 1
        when :LVAR
          replacements << {
            from: node.location(path),
            to: "(#{node.children[0]}#{lvar_suffix})"
          }
        end
      end

      replace(ast, path, replacements)
    end

    private def assign_args(method_node, fcall_node, fcall_path, lvar_suffix)
      params = method_node.children[0]
      args = fcall_node.fcall_args.array_content
      args.map.with_index do |arg, index|
        "#{params[index]}#{lvar_suffix} = #{arg.to_source(fcall_path)}"
      end.join(';') + ';'
    end

    private def gen_lvar_suffix
      "__#{SecureRandom.hex(5)}"
    end
  end
end
