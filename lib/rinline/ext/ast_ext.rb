module Rinline
  module Ext
    module AstExt
      refine RubyVM::AbstractSyntaxTree::Node do
        def traverse(&block)
          block.call self
          self.children.each do |child|
            child.traverse(&block) if child.is_a?(RubyVM::AbstractSyntaxTree::Node)
          end
        end

        def to_source(path)
          lines = File.read(path).split("\n")
          first_lineno = self.first_lineno - 1
          last_lineno = self.last_lineno - 1
          first_column = self.first_column
          last_column = self.last_column

          if first_lineno == last_lineno
            lines[first_lineno][first_column..last_column]
          else
            ret = [lines[first_lineno][first_column..-1]]
            lines[(first_lineno+1)..(last_lineno-1)].each do |line|
              ret << line
            end
            ret << lines[last_lineno][0..last_column]
            ret.join("\n")
          end
        end
      end
    end
  end
end
