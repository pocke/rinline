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

      ast.traverse do |node|
        if node.type == :VCALL
          target_method_name = node.children[0]
          next if method_name == target_method_name
          target_method = klass.instance_method(target_method_name)
          target_iseq = target_method.to_iseq
          next unless target_iseq.short?

          target_path = target_iseq.absolute_path
          target_ast = RubyVM::AbstractSyntaxTree.of(target_method)

          replacements << {
            from: node,
            to: method_body_ast(target_ast).to_source(target_path),
          }
        end
      end

      return if replacements.empty?
      return replace(method, replacements)
    end

    attr_reader :klass, :method_name, :method
    private :klass, :method_name, :method

    private def method_body_ast(method_ast)
      method_ast.children[2]
    end

    # TODO: replacement defined in another file
    #
    # @param original_method [Method]
    # @param replacements [Array<{from: RubyVM::AbstractSyntaxTree, to: String}>]
    private def replace(original_method, replacements)
      original_ast = original_method.to_ast
      original_path = original_method.to_iseq.absolute_path
      ret = original_ast.to_source(original_path)
      offset = -original_ast.first_index(original_path)

      replacements.each do |replacement|
        from = replacement[:from]
        to = "(#{replacement[:to]})"


        ret[(from.first_index(original_path) + offset)..(from.last_index(original_path) + offset)] = to
        offset += to.size - from.to_source(original_path).size
      end

      ret.force_encoding(Encoding::UTF_8) # TODO: Support other encodings
    end
  end
end
