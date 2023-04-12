require "mkmf"
require "rbconfig"

have_func("rb_sym2str", "ruby.h")

if enable_config("system-libraries")
  # TODO: I'm reasonably sure this ought to work, but fails on our Windows CI action.
  # We don't use windows, so haven't investigated properly.
  pkg_config("libmaxminddb") or fail "couldn't find libmaxminddb"
else
  maxminddb_dir = File.expand_path(File.join(__dir__, "libmaxminddb"))
  gem_root = File.expand_path('..', __dir__)

  if !File.directory?(maxminddb_dir) ||
    # '.', '..', and possibly '.git' from a failed checkout:
    Dir.entries(maxminddb_dir).size <= 3
    Dir.chdir(gem_root) { system('git submodule update --init') } or fail 'Could not fetch maxminddb'
  end

  Dir.chdir(maxminddb_dir) do
    system("./bootstrap") or fail "Couldn't run maxminddb `bootstrap`"
    system({ "CFLAGS" => "-fPIC" }, "./configure", "--disable-shared", "--disable-tests") or fail "Couldn't run maxminddb `configure`"
    system("make", "clean") or fail "Couldn't run maxminddb `make clean`"
    system("make") or fail "Couldn't run maxminddb `make`"
  end

  header_dirs = ["#{maxminddb_dir}/include"]
  lib_dirs = ["#{maxminddb_dir}/src/.libs"]

  dir_config("maxminddb", header_dirs, lib_dirs)

  $CFLAGS << " -I#{maxminddb_dir}/src/.libs"
  $LDFLAGS << " -L#{maxminddb_dir}/src/.libs"
end

$LDFLAGS << " -lmaxminddb"
$CFLAGS << " -std=c99 -fPIC -fms-extensions"
# $CFLAGS << " -g -O0"

create_makefile("geoip2/geoip2")
