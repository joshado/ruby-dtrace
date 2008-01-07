#
# Ruby-Dtrace
# (c) 2007 Chris Andrews <chris@nodnol.org>
#

require 'dtrace'
require 'test/unit'

class TestDtrace < Test::Unit::TestCase
  def test_rubyprobe
    t = Dtrace.new 
    t.setopt("bufsize", "4m")

    progtext = <<EOD
ruby*:::ruby-probe
{
  trace(copyinstr(arg0));
  trace(copyinstr(arg1));
}
EOD
    
    prog = t.compile progtext
    prog.execute
    t.go

    c = DtraceConsumer.new(t)

    # Leopard's ruby-probe is DTracer, Solaris's is Tracer.
    begin
      trace_module = DTracer
    rescue NameError
      trace_module = Tracer
    end

    (0..9).each do |i|
      trace_module.fire("foo", i.to_s)
    end

    data = []
    c.consume_once do |d|
      data << d
    end
    
    (0..9).each do |i|
      d = data.shift
      assert_equal("foo", d.data[0].value)
      assert_equal(i.to_s, d.data[1].value)
    end

  end
    
end