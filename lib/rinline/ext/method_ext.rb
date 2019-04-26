module Rinline
  module Ext
    module MethodExt
      refine UnboundMethod do
        def to_ast
          RubyVM::AbstractSyntaxTree.of(self)
        end

        def to_iseq
          RubyVM::InstructionSequence.of(self)
        end
      end
    end
  end
end
