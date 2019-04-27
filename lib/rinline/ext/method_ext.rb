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
