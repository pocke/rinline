module Rinline
  module Ext
    # TODO: Reduce File.binread call
    module AstExt
      refine RubyVM::AbstractSyntaxTree::Node do
        def traverse(&block)
          block.call self
          self.children.each do |child|
            child.traverse(&block) if child.is_a?(RubyVM::AbstractSyntaxTree::Node)
          end
        end

        def to_source(path)
          File.binread(path)[first_index(path)..last_index(path)]
        end

        def location(path)
          Location.new(first_index(path), last_index(path))
        end

        private def first_index(path)
          return first_column if first_lineno == 1

          lines = File.binread(path).split("\n")
          lines[0..(first_lineno - 2)].sum(&:size) +
            first_lineno - 1 + # For \n
            first_column
        end

        private def last_index(path)
          last_column = self.last_column - 1
          return last_column if last_lineno == 1

          lines = File.binread(path).split("\n")
          lines[0..(last_lineno - 2)].sum(&:size) +
            last_lineno - 1 + # For \n
            last_column
        end
      end
    end
  end
end
