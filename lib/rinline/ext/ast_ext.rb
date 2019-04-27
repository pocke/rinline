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

        # var = 1
        # ^^^
        def location_variable_name_of_lasgn(path)
          type! :LASGN
          first_index = first_index(path)

          Location.new(first_index, first_index + self.children[0].size)
        end

        def method_body
          type! :SCOPE
          self.children[2]
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

        private def type!(type)
          raise "Unexpected type: #{self.type}" unless self.type == type
        end
      end
    end
  end
end
