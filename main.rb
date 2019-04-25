class A
  def hello(name)
    greet + " " + name
  end

  def greet
    "hello"
  end
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
