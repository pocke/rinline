# $ ruby benchmark/simple.rb
#                            user     system      total        real
# plain                  5.716059   0.000000   5.716059 (  5.719808)
# optimized              3.791726   0.000000   3.791726 (  3.793648)
# hand_optimized         3.660404   0.000000   3.660404 (  3.662295)

require 'benchmark'

class C
  def plain
    m + n
  end

  def optimized
    m + n
  end

  def hand_optimized
    1 + 2
  end

  def m
    1
  end

  def n
    2
  end
end

require 'rinline'
Rinline.optimize do |r|
  r.optimize_instance_method(C, :optimized)
end

i = C.new

Benchmark.bm(20) do |x|
  x.report('plain')     { 100000000.times { i.plain } }
  x.report('optimized') { 100000000.times { i.optimized } }
  x.report('hand_optimized') { 100000000.times { i.hand_optimized } }
end
