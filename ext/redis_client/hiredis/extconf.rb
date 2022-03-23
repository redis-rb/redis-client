# frozen_string_literal: true

require "mkmf"

if RUBY_ENGINE == "ruby"
  $CFLAGS << " -O3 "
  $CFLAGS << " -std=c99"

  create_makefile("redis_client/hiredis_connection")
else
  File.write("Makefile", dummy_makefile($srcdir).join)
end
