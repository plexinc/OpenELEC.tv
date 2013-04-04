################################################################################
#      This file is part of OpenELEC - http://www.openelec.tv
#      Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
#
#  This Program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2, or (at your option)
#  any later version.
#
#  This Program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with OpenELEC.tv; see the file COPYING.  If not, write to
#  the Free Software Foundation, 51 Franklin Street, Suite 500, Boston, MA 02110, USA.
#  http://www.gnu.org/copyleft/gpl.html
################################################################################

PKG_NAME="binutils"
PKG_VERSION="2.23.1"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://www.gnu.org/software/binutils/binutils.html"
PKG_URL="http://ftp.gnu.org/gnu/binutils/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS=""
PKG_BUILD_DEPENDS_HOST="ccache:host bison:host flex linux-headers gmp-host mpfr cloog ppl"
PKG_PRIORITY="optional"
PKG_SECTION="toolchain/devel"
PKG_SHORTDESC="binutils: A GNU collection of binary utilities"
PKG_LONGDESC="The GNU binutils are utilities of use when dealing with object files. the packages includes ld - the GNU linker, as - the GNU assembler, addr2line - converts addresses into filenames and line numbers, ar - a utility for creating, modifying and extracting from archives, c++filt - filter to demangle encoded C++ symbols, gprof - displays profiling information, nlmconv - converts object code into an NLM, nm - lists symbols from object files, objcopy - Copys and translates object files, objdump - displays information from object files, ranlib - generates an index to the contents of an archive, readelf - displays information from any ELF format object file, size - lists the section sizes of an object or archive file, strings - lists printable strings from files, strip - discards symbols as well as windres - a compiler for Windows resource files."

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

# package specific configure options
HOST_CONFIGURE_OPTS="--host=$HOST_NAME \
                     --build=$HOST_NAME \
                     --target=$TARGET_NAME \
                     --prefix=$ROOT/$TOOLCHAIN \
                     --with-sysroot=$SYSROOT_PREFIX \
                     --with-lib-path=$SYSROOT_PREFIX/lib:$SYSROOT_PREFIX/usr/lib \
                     --with-gmp=$ROOT/$TOOLCHAIN \
                     --with-mpfr=$ROOT/$TOOLCHAIN \
                     --with-ppl=$ROOT/$TOOLCHAIN \
                     --with-cloog=$ROOT/$TOOLCHAIN \
                     --disable-werror \
                     --disable-multilib \
                     --disable-libada \
                     --disable-libssp \
                     --enable-cloog-backend=isl \
                     --enable-version-specific-runtime-libs \
                     --enable-plugins \
                     --disable-gold \
                     --enable-ld \
                     --enable-lto \
                     --disable-nls"

# Disable PPL version check as the PPL major version number has been bumped so the check fails.
  HOST_CONFIGURE_OPTS="$HOST_CONFIGURE_OPTS --disable-ppl-version-check"

  if [ "$TARGET_ARCH" = "x86_64" ]; then
    HOST_CONFIGURE_OPTS="$HOST_CONFIGURE_OPTS --enable-64-bit-bfd"
  fi

pre_configure_host() {
  CPPFLAGS=""
  CFLAGS=""
  CXXFLAGS=""
  LDFLAGS=""
}

make_host() {
  make configure-host
  make
}

post_makeinstall_host() {
  mkdir -p $SYSROOT_PREFIX/usr/include
  cp -v ../include/libiberty.h $SYSROOT_PREFIX/usr/include
}
