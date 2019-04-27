module Rinline
  module Ext
    # TODO: Reduce File.binread call
    module AstExt
      refine RubyVM::AbstractSyntaxTree::Node do
        def traverse(&block)
          opt = {}
          block.call self, opt

          # workaround for modifiers
          # TODO: Remove this workaround by refining offset
          if ((type == :IF || type == :UNLESS) && children[2] == nil && children[1].before_than(children[0])) ||
             ((type == :WHILE || type == :UNTIL) && children[1].before_than(children[0]))
            block.call(children[1], opt)
            block.call(children[0], opt)
          else
            self.children.each.with_index do |child, index|
              next if opt[:ignore_index] == index
              child.traverse(&block) if child.is_a?(RubyVM::AbstractSyntaxTree::Node)
            end
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

          Location.new(first_index, first_index + self.children[0].size - 1)
        end

        def method_body
          type! :SCOPE
          self.children[2]
        end

        def method_args
          type! :SCOPE
          self.children[1]
        end

        # Extensions for ARGS
        def args_pre_num
          type! :ARGS
          self.children[0]
        end

        def args_pre_init
          type! :ARGS
          self.children[1]
        end

        def args_opt
          type! :ARGS
          self.children[2]
        end

        def args_first_post
          type! :ARGS
          self.children[3]
        end

        def args_post_num
          type! :ARGS
          self.children[4]
        end

        def args_post_init
          type! :ARGS
          self.children[5]
        end

        def args_rest
          type! :ARGS
          self.children[6]
        end

        def args_kw
          type! :ARGS
          self.children[7]
        end

        def args_kwrest
          type! :ARGS
          self.children[8]
        end

        def args_block
          type! :ARGS
          self.children[9]
        end

        def expandable_method?(parameter_size)
          a = self.method_args
          a.args_pre_num == parameter_size &&
            a.args_pre_init == nil &&
            a.args_opt == nil &&
            a.args_first_post == nil &&
            a.args_post_num == 0 &&
            a.args_post_init == nil &&
            a.args_rest == nil &&
            a.args_kw == nil &&
            a.args_kwrest == nil &&
            a.args_block == nil
        end

        def array_size
          type! :ARRAY
          self.children.size - 1
        end

        def array_content
          type! :ARRAY
          self.children[0..-2]
        end

        def fcall_args
          type! :FCALL
          self.children[1]
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

        def before_than(right)
          if self.first_lineno == right.first_lineno
            self.first_column < right.first_column
          else
            self.first_lineno < right.first_lineno
          end
        end
      end
    end
  end
end
