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

PKG_NAME="eglibc"
PKG_VERSION="2.17-22321"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://www.eglibc.org/"
PKG_URL="$DISTRO_SRC/$PKG_NAME-$PKG_VERSION.tar.xz"
PKG_DEPENDS="timezone-data"
PKG_BUILD_DEPENDS_TARGET="ccache autotools autoconf-2.68 linux-headers gcc:host"
PKG_PRIORITY="optional"
PKG_SECTION="toolchain/devel"
PKG_SHORTDESC="eglibc: The Embedded GNU C library"
PKG_LONGDESC="The Embedded GLIBC (EGLIBC) is a variant of the GNU C Library (GLIBC) that is designed to work well on embedded systems. EGLIBC strives to be source and binary compatible with GLIBC. EGLIBC's goals include reduced footprint, configurable components, better support for cross-compilation and cross-testing. In contrast to what Ulrich Drepper makes out of GLIBC, in EGLIBC all patches assigned to the FSF will be considered regardless of individual or company affiliation and cooperation is encouraged, as well as communication, civility, and respect among developers."

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

if [ "$OPENMAX" = "bcm2835-driver" ]; then
  PKG_DEPENDS="$PKG_DEPENDS libcofi"
fi

# package specific configure options
PKG_CONFIGURE_OPTS_TARGET="ac_cv_header_cpuid_h=yes
                           libc_cv_forced_unwind=yes
                           libc_cv_c_cleanup=yes
                           libc_cv_gnu89_inline=yes
                           libc_cv_ssp=no
                           libc_cv_ctors_header=yes
                           --libexecdir=/usr/lib/eglibc \
                           --cache-file=config.cache \
                           --disable-profile \
                           --disable-sanity-checks \
                           --enable-add-ons \
                           --enable-bind-now \
                           --with-elf \
                           --with-tls \
                           --enable-kernel=2.6.39 \
                           --with-__thread \
                           --with-binutils=$BUILD/toolchain/bin \
                           --with-headers=$SYSROOT_PREFIX/usr/include \
                           --without-cvs \
                           --without-gd \
                          --enable-obsolete-rpc \
                           --disable-build-nscd \
                           --disable-nscd"


if [ "$DEBUG" = yes ]; then
  PKG_CONFIGURE_OPTS_TARGET="$PKG_CONFIGURE_OPTS_TARGET --enable-debug"
else
  PKG_CONFIGURE_OPTS_TARGET="$PKG_CONFIGURE_OPTS_TARGET --disable-debug"
  DEBUG_OPTIONS="  OPTION_EGLIBC_MEMUSAGE = n"
fi

pre_configure_target() {
  ( cd ..; aclocal --force --verbose; autoconf-2.68 --force --verbose )

  # Fails to compile with GCC's link time optimization.
    strip_lto

  # Filter out some problematic *FLAGS
    CFLAGS=`echo $CFLAGS | sed -e "s|-ffast-math||g"`
    CFLAGS=`echo $CFLAGS | sed -e "s|-Ofast|-O2|g"`
    CFLAGS=`echo $CFLAGS | sed -e "s|-O.|-O2|g"`
    LDFLAGS=`echo $LDFLAGS | sed -e "s|-ffast-math||g"`
    LDFLAGS=`echo $LDFLAGS | sed -e "s|-Ofast|-O2|g"`
    LDFLAGS=`echo $LDFLAGS | sed -e "s|-O.|-O2|g"`
    LDFLAGS=`echo $LDFLAGS | sed -e "s|-Wl,--as-needed||"`

    unset LD_LIBRARY_PATH

  # set some CFLAGS we need
    CFLAGS="$CFLAGS -g -fno-stack-protector -fgnu89-inline"

  export BUILD_CC=$HOST_CC
  export OBJDUMP_FOR_HOST=objdump

cat >option-groups.config <<EOF

  OPTION_EGLIBC_ADVANCED_INET6 = n

# needed for connman:
  OPTION_EGLIBC_BACKTRACE = y

  OPTION_EGLIBC_BIG_MACROS = n
  OPTION_EGLIBC_BSD = n

# needed for xf86-video-fglrx:
  OPTION_EGLIBC_CATGETS = y

# libiconv replacement:
  OPTION_EGLIBC_CHARSETS = y

  OPTION_EGLIBC_DB_ALIASES = n
  OPTION_EGLIBC_LOCALES = n

# needed for example with glib and Python:
  OPTION_EGLIBC_LOCALE_CODE = y

  OPTION_EGLIBC_NIS = y
  OPTION_EGLIBC_NSSWITCH = y
  OPTION_EGLIBC_RCMD = n

# needed by eglibc byself (todo):
  OPTION_EGLIBC_RTLD_DEBUG = y

# needed for speed (optionally/todo)
  OPTION_POSIX_REGEXP_GLIBC = y

# needed for PAM and Mysql:
  OPTION_EGLIBC_GETLOGIN = y

# needed for systemd and dropbear:
  OPTION_EGLIBC_UTMP = y
  OPTION_EGLIBC_UTMPX = y
EOF

if [ ! "$DEBUG" = yes ]; then
cat >>option-groups.config <<EOF
# debugging options:
  DEBUG_OPTIONS="  OPTION_EGLIBC_MEMUSAGE = n"
EOF
fi

cat >configparms <<EOF
slibdir=/lib
libdir=/usr/lib
EOF

}

pre_make_target() {
  # dont build parallel
    MAKEFLAGS=-j1
}

post_make_target() {
  make install_root=$SYSROOT_PREFIX install
}

post_makeinstall_target() {
  if [ "$TARGET_ARCH" = "arm" -a "$TARGET_FLOAT" = "hard" ]; then
    ln -sf ld.so $INSTALL/lib/ld-linux.so.3
  fi

  rm -rf $INSTALL/lib/libBrokenLocale*.so*
  rm -rf $INSTALL/lib/libSegFault*.so*
  rm -rf $INSTALL/lib/libanl*.so*
  rm -rf $INSTALL/lib/libcidn*.so*
  rm -rf $INSTALL/lib/libmemusage*.so*
  rm -rf $INSTALL/lib/libnss_db*.so*
  rm -rf $INSTALL/lib/libnss_hesiod*.so*
  rm -rf $INSTALL/lib/libnss_nis*.so*
  rm -rf $INSTALL/lib/libpcprofile*.so*

  if [ ! "$DEVTOOLS" = yes ]; then
    # for GDB
    rm -rf $INSTALL/lib/libthread_db*.so*
  fi

  rm -rf $INSTALL/usr/bin/catchsegv
  rm -rf $INSTALL/usr/bin/gencat
  rm -rf $INSTALL/usr/bin/getconf
  rm -rf $INSTALL/usr/bin/getent
  rm -rf $INSTALL/usr/bin/iconv
  rm -rf $INSTALL/usr/bin/localedef
  rm -rf $INSTALL/usr/bin/makedb
  rm -rf $INSTALL/usr/bin/mtrace
  rm -rf $INSTALL/usr/bin/pcprofiledump
  rm -rf $INSTALL/usr/bin/pldd
  rm -rf $INSTALL/usr/bin/rpcgen
  rm -rf $INSTALL/usr/bin/sotruss
  rm -rf $INSTALL/usr/bin/sprof
  rm -rf $INSTALL/usr/bin/tzselect
  rm -rf $INSTALL/usr/bin/xtrace

  rm -rf $INSTALL/usr/lib/*.a
  rm -rf $INSTALL/usr/lib/*.o
  rm -rf $INSTALL/usr/lib/*.map
  rm -rf $INSTALL/usr/lib/*.so

  rm -rf $INSTALL/usr/lib/audit
  rm -rf $INSTALL/usr/lib/eglibc
  rm -rf $INSTALL/usr/lib/libc_pic
  rm -rf $INSTALL/usr/share
  rm -rf $INSTALL/sbin
  rm -rf $INSTALL/var

  sed -i 's%/usr/bin/bash%/bin/sh%g' $INSTALL/usr/bin/ldd

  mkdir -p $INSTALL/etc
    cp $PKG_DIR/config/nsswitch.conf $INSTALL/etc
    cp $PKG_DIR/config/gai.conf $INSTALL/etc
}
