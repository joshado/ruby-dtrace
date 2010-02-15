require 'mkmf'
require 'rbconfig'

def symlink(old, new)
  begin
    File.symlink(old, new)
  rescue Errno::EEXIST
    File.unlink(new)
    retry
  end
end

$CFLAGS += " -D_LONGLONG_TYPE -g"
have_library("dtrace", "dtrace_open")

# Update machine-dependent symlinks in the source, based on $Config::CONFIG and `uname -p`
os  = Config::CONFIG['target_os']
os.gsub!  /[0-9.]+$/, ''

# On OSX, this is "powerpc", even on Intel...
if os == 'darwin'
  cpu = Config::CONFIG['ARCH_FLAG']
  cpu.gsub!(/-arch /, '')
else
  cpu = Config::CONFIG['CC'] =~ /64/ ? 'x86_64' : 'i386'
end

dir = "#{cpu}-#{os}"
symlink "#{dir}/dtrace_probe.c", "dtrace_probe.c"

# Create makefile in the usual way
create_makefile("dtrace_api")

