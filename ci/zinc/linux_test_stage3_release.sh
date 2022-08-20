#!/bin/sh

. ./ci/zinc/linux_base.sh

OLD_ZIG="$DEPS_LOCAL/bin/zig"
TARGET="${ARCH}-linux-musl"
MCPU="baseline"

echo "building stage3-release with zig version $($OLD_ZIG version)"

export CC="$OLD_ZIG cc -target $TARGET -mcpu=$MCPU"
export CXX="$OLD_ZIG c++ -target $TARGET -mcpu=$MCPU"

mkdir build-release
cd build-release
cmake .. \
  -DCMAKE_INSTALL_PREFIX="$RELEASE_STAGING" \
  -DCMAKE_PREFIX_PATH="$DEPS_LOCAL" \
  -DCMAKE_BUILD_TYPE=Release \
  -DZIG_TARGET_TRIPLE="$TARGET" \
  -DZIG_TARGET_MCPU="$MCPU" \
  -DZIG_STATIC=ON \
  -GNinja

# Now cmake will use zig as the C/C++ compiler. We reset the environment variables
# so that installation and testing do not get affected by them.
unset CC
unset CXX

ninja install

"$RELEASE_STAGING/bin/zig" build test docs \
  -fqemu \
  -fwasmtime \
  -Dstatic-llvm \
  -Dtarget=native-native-musl \
  --search-prefix "$DEPS_LOCAL"

# Produce the experimental std lib documentation.
mkdir -p "$RELEASE_STAGING/docs/std"
"$RELEASE_STAGING/bin/zig" test ../lib/std/std.zig \
  --zig-lib-dir lib \
  -femit-docs=$RELEASE_STAGING/docs/std \
  -fno-emit-bin

cp ../LICENSE $RELEASE_STAGING/
cp ../zig-cache/langref.html $RELEASE_STAGING/docs/

# Look for HTML errors.
tidy --drop-empty-elements no -qe $RELEASE_STAGING/docs/langref.html

# Explicit exit helps show last command duration.
exit
