# $ ruby benchmark/simple.rb
#                            user     system      total        real
# plain                  6.203292   0.000000   6.203292 (  6.206694)
# optimized              3.623372   0.000000   3.623372 (  3.625261)

require 'benchmark'

class C
  def plain
    m + n
  end

  def optimized
    m + n
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
end
