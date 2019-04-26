module Rinline
  module Ext
    module IseqExt
      refine RubyVM::InstructionSequence do
        def short?
          self.to_a[13].size < 50
        end
      end
    end
  end
end
