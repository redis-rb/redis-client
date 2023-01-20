# frozen_string_literal: true

require "mkmf"

class HiredisConnectionExtconf
  def configure
    if RUBY_ENGINE == "ruby" && !RUBY_PLATFORM.match?(/mswin/)
      configure_extension
      create_makefile("redis_client/hiredis_connection")
    else
      File.write("Makefile", dummy_makefile($srcdir).join)
    end
  end

  def configure_extension
    build_hiredis

    have_func("rb_hash_new_capa", "ruby.h")

    $CFLAGS = concat_flags($CFLAGS, "-I#{hiredis_dir}", "-std=c99", "-fvisibility=hidden")
    $CFLAGS = if ENV["EXT_PEDANTIC"]
      concat_flags($CFLAGS, "-Werror", "-g")
    else
      concat_flags($CFLAGS, "-O3")
    end

    append_cflags("-Wno-declaration-after-statement") # Older compilers
    append_cflags("-Wno-compound-token-split-by-macro") # Older rubies on macos
  end

  def build_hiredis
    env = {
      "USE_SSL" => 1,
      "CFLAGS" => concat_flags(ENV["CFLAGS"], "-fvisibility=hidden"),
    }
    env["OPTIMIZATION"] = "-g" if ENV["EXT_PEDANTIC"]

    env = configure_openssl(env)

    env_args = env.map { |k, v| "#{k}=#{v}" }
    Dir.chdir(hiredis_dir) do
      unless system(make_program, "static", *env_args)
        raise "Building hiredis failed"
      end
    end

    $LDFLAGS = concat_flags($LDFLAGS, "-lssl", "-lcrypto")
    $libs = concat_flags($libs, "#{hiredis_dir}/libhiredis.a", "#{hiredis_dir}/libhiredis_ssl.a")
  end

  def configure_openssl(original_env)
    original_env.dup.tap do |env|
      openssl_include, openssl_lib = dir_config("openssl")

      openssl_include ||= dir_config("opt").first
                            &.split(File::PATH_SEPARATOR)
                            &.detect { |dir| dir.include?("openssl") }

      openssl_lib ||= dir_config("opt").last
                        &.split(File::PATH_SEPARATOR)
                        &.detect { |dir| dir.include?("openssl") }

      if (!openssl_include || !openssl_lib) && !have_header("openssl/ssl.h")
        raise "OpenSSL library could not be found. " \
              "Use --with-openssl-dir=<dir> option to specify the prefix where OpenSSL is installed."
      end

      if openssl_lib
        env["CFLAGS"] = concat_flags(env["CFLAGS"], "-I#{openssl_include}")
        env["SSL_LDFLAGS"] = "-L#{openssl_lib}"
      end
    end
  end

  private

  def concat_flags(*args)
    args.compact.join(" ")
  end

  def hiredis_dir
    File.expand_path('vendor', __dir__)
  end

  def make_program
    with_config("make-prog", ENV["MAKE"]) ||
      case RUBY_PLATFORM
      when /(bsd|solaris)/
        'gmake'
      else
        'make'
      end
  end
end

HiredisConnectionExtconf.new.configure
