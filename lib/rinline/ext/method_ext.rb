module Rinline
  module Ext
    module MethodExt
      refine UnboundMethod do
        using IseqExt
        using AstExt

        def to_ast
          RubyVM::AbstractSyntaxTree.of(self)
        end

        def to_iseq
          RubyVM::InstructionSequence.of(self)
        end

        def expandable?
          ruby_method? &&
            to_iseq.short? &&
            absolute_path != "(eval)" &&
            !to_ast.has_child?(:SUPER, :ZSUPER, :RETURN) &&
            # HACK: RubyVM::AST omits `return` from tree if it is meaningless.
            # So checking AST is not enough.
            !to_ast.to_source(absolute_path).match?(/\breturn\b/)
        end

        def ruby_method?
          !!source_location
        end

        def absolute_path
          source_location[0]
        end
      end
    end
  end
end
