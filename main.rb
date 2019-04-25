class A
  def hello(name)
    greet + " " + name
  end

  def greet
    "hello"
  end
end



def optimize_instance_method(klass, method_name)
  method = klass.instance_method(method_name)
  ast = RubyVM::AbstractSyntaxTree.of(method)

  traverse(ast) do |node|
    if node.type == :VCALL
      target_method = klass.instance_method(node.children[0])
      target_iseq = RubyVM::InstructionSequence.of(target_method)
      next unless short_method?(target_iseq)

      target_path = target_iseq.absolute_path
      target_ast = RubyVM::AbstractSyntaxTree.of(target_method)

      replacement = {
        from: node,
        to: ast_to_source(method_body_ast(target_ast), target_path),
      }

      replaced = replace(method, replacement)

      klass.class_eval "undef :#{method_name}; #{replaced}"

      break
    end
  end
end

def traverse(node, &block)
  block.call node
  node.children.each do |child|
    traverse(child, &block) if child.is_a?(RubyVM::AbstractSyntaxTree::Node)
  end
end

def ast_to_source(node, path)
  lines = File.read(path).split("\n")
  first_lineno = node.first_lineno - 1
  last_lineno = node.last_lineno - 1
  first_column = node.first_column
  last_column = node.last_column

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

def method_body_ast(method_ast)
  method_ast.children[2]
end

# TODO: Support multiple replacements
#
# @param original_method [Method]
# @param replacements [Array<{from: RubyVM::AbstractSyntaxTree, to: String}>]
def replace(original_method, *replacements)
  original_ast = RubyVM::AbstractSyntaxTree.of(original_method)
  original_path = RubyVM::InstructionSequence.of(original_method).absolute_path
  ret = ast_to_source(original_ast, original_path).split("\n")

  fl, fc, ll = original_ast.first_lineno, original_ast.first_column, original_ast.last_lineno

  replacements.each do |replacement|
    from = replacement[:from]
    to = replacement[:to]

    rfl, rfc, rll, rlc = from.first_lineno, from.first_column, from.last_lineno, from.last_column
    rfc -= fc if rfl == fl
    rlc -= fc if fl == ll && rfl == fl
    rfl -= fl
    rll -= fl

    if rfl == rll
      ret[rfl][rfc..rlc] = to
    else
      ret[rfl][rfc..-1] = to
      ret[rll][0..rlc] = ""
      ret[(rfl+1)..(rll-1)] = []
    end
  end

  ret.join("\n")
end

def short_method?(iseq)
  iseq.to_a[13].size < 50
end


require 'benchmark'


a = A.new

Benchmark.bm do |x|
  x.report{10000000.times{a.hello('pocke')}}
end

p(Benchmark.realtime do
  optimize_instance_method(A, :hello)
end)

a = A.new

Benchmark.bm do |x|
  x.report{10000000.times{a.hello('pocke')}}
end
