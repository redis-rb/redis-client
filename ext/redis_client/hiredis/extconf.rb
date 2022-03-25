# frozen_string_literal: true

require "mkmf"

if RUBY_ENGINE == "ruby"
  hiredis_dir = File.expand_path('vendor', __dir__)

  RbConfig::CONFIG['configure_args'] =~ /with-make-prog=(\w+)/
  make_program = case RUBY_PLATFORM
  when /mswin/
    'nmake'
  when /(bsd|solaris)/
    'gmake'
  else
    'make'
  end

  Dir.chdir(hiredis_dir) do
    success = system("#{make_program} static USE_SSL=1")
    raise "Building hiredis failed" unless success
  end

  $CFLAGS << " -I#{hiredis_dir} "
  $LDFLAGS << " #{hiredis_dir}/libhiredis.a #{hiredis_dir}/libhiredis_ssl.a -lssl -lcrypto "
  $CFLAGS << " -O3 "
  $CFLAGS << " -std=c99"

  create_makefile("redis_client/hiredis_connection")
else
  File.write("Makefile", dummy_makefile($srcdir).join)
end
