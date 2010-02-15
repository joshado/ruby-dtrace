require 'mkmf'
require 'rbconfig'
require 'getoptlong'

def symlink(old, new)
  begin
    File.symlink(old, new)
  rescue Errno::EEXIST
    File.unlink(new)
    retry
  end
end

opts = GetoptLong.new([ '--arch', '-a', GetoptLong::REQUIRED_ARGUMENT ])

arch = nil
opts.each do |opt, arg|
  case opt
  when '--arch'
    arch = arg
  end
end

$CFLAGS += " -D_LONGLONG_TYPE -g"
have_library("dtrace", "dtrace_open")

unless arch

  # Attempt to figure out the build arch automatically...
  # We want an cpu-os combination.
  
  # TODO - catch pre 10.5 OSX and pre 10 Solaris.
  os  = Config::CONFIG['target_os']
  os.gsub!  /[0-9.]+$/, ''

  if os == 'darwin'
    if Config::CONFIG['ARCH_FLAG'] != ''
      # Single-arch build (macports, 10.5)
      cpu = Config::CONFIG['ARCH_FLAG']
      cpu.gsub!(/-arch /, '')
    else
      # Multi-arch build (Apple, 10.6)
      # TODO - real multi-arch
      cpu = 'x86_64'
    end
  else
    # Solaris 64 bit Ruby builds seem to be done by: CC="gcc -m64"
    # TODO - sunstudio builds?
    cpu = Config::CONFIG['CC'] =~ /64/ ? 'x86_64' : 'i386'
  end

  dir = "#{cpu}-#{os}"

  puts "Selected architecture: #{dir}"
  puts "(override with --arch=...)"
else
  dir = arch
  puts "Using overridden architecture: #{dir}"
end

symlink "#{dir}/dtrace_probe.c", "dtrace_probe.c"

# Create makefile in the usual way
create_makefile("dtrace_api")

