module Rinline
  module Ext
    module IseqExt
      refine RubyVM::InstructionSequence do
        def short?
          self.to_a[13].size < Runner.current.iseq_threshold
        end
      end
    end
  end
end
