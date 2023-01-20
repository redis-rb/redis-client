# frozen_string_literal: true

require "mkmf"

def concat_flags(*args)
  args.compact.join(" ")
end

if RUBY_ENGINE == "ruby" && !RUBY_PLATFORM.match?(/mswin/)
  have_func("rb_hash_new_capa", "ruby.h")

  hiredis_dir = File.expand_path('vendor', __dir__)

  make_program = with_config("make-prog", ENV["MAKE"])
  make_program ||= case RUBY_PLATFORM
  when /(bsd|solaris)/
    'gmake'
  else
    'make'
  end

  openssl_include, openssl_lib = dir_config("openssl")

  openssl_include ||= dir_config("opt").first
    &.split(File::PATH_SEPARATOR)
    &.detect { |dir| dir.include?("openssl") }

  openssl_lib ||= dir_config("opt").last
    &.split(File::PATH_SEPARATOR)
    &.detect { |dir| dir.include?("openssl") }

  if (!openssl_include || !openssl_lib) && !have_header("openssl/ssl.h")
    raise "OpenSSL library could not be found. You might want to use --with-openssl-dir=<dir> option to specify the " \
      "prefix where OpenSSL is installed."
  end

  Dir.chdir(hiredis_dir) do
    env = {
      "USE_SSL" => 1,
      "CFLAGS" => ENV["CFLAGS"],
    }
    if openssl_lib
      env["CFLAGS"] = concat_flags(env["CFLAGS"], "-I#{openssl_include}")
      env["SSL_LDFLAGS"] = "-L#{openssl_lib}"
    end
    env["OPTIMIZATION"] = "-g" if ENV["EXT_PEDANTIC"]

    env_args = env.map { |k, v| "#{k}=#{v}" }
    unless system(make_program, "static", *env_args)
      raise "Building hiredis failed"
    end
  end

  $CFLAGS = concat_flags($CFLAGS, "-I#{hiredis_dir}", "-std=c99")
  $LDFLAGS = concat_flags($LDFLAGS, "-lssl", "-lcrypto")
  $libs = concat_flags($libs, "#{hiredis_dir}/libhiredis.a", "#{hiredis_dir}/libhiredis_ssl.a")
  $CFLAGS = if ENV["EXT_PEDANTIC"]
    concat_flags($CFLAGS, "-Werror", "-g")
  else
    concat_flags($CFLAGS, "-O3")
  end

  cc_version = `#{RbConfig.expand("$(CC) --version".dup)}`
  if cc_version.match?(/clang/i) && RUBY_PLATFORM =~ /darwin/
    $LDFLAGS << ' -Wl,-exported_symbols_list,"' << File.join(__dir__, 'export.clang') << '"'
    if RUBY_VERSION >= "3.2" && RUBY_PATCHLEVEL < 0
      $LDFLAGS << " -Wl,-exported_symbol,_ruby_abi_version"
    end
  elsif cc_version.match?(/gcc/i)
    $LDFLAGS << ' -Wl,--version-script="' << File.join(__dir__, 'export.gcc') << '"'
  end

  append_cflags("-Wno-declaration-after-statement") # Older compilers
  append_cflags("-Wno-compound-token-split-by-macro") # Older rubies on macos

  create_makefile("redis_client/hiredis_connection")
else
  File.write("Makefile", dummy_makefile($srcdir).join)
end
