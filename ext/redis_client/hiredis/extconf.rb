# frozen_string_literal: true

require "mkmf"

if RUBY_ENGINE == "ruby"
  hiredis_dir = File.expand_path("../vendor/", __FILE__)

  RbConfig::CONFIG['configure_args'] =~ /with-make-prog\=(\w+)/
  make_program = $1 || ENV['make']
  make_program ||= case RUBY_PLATFORM
  when /mswin/
    'nmake'
  when /(bsd|solaris)/
    'gmake'
  else
    'make'
  end

  Dir.chdir(hiredis_dir) do
    success = system("#{make_program} static")
    raise "Building hiredis failed" if !success
  end

  $CFLAGS << " -I#{hiredis_dir}"
  $LDFLAGS << " #{hiredis_dir}/libhiredis.a"
  $CFLAGS << " -O3 "
  $CFLAGS << " -std=c99"

  create_makefile("redis_client/hiredis_connection")
else
  File.write("Makefile", dummy_makefile($srcdir).join)
end
