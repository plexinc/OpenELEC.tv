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

PKG_NAME="glib"
PKG_VERSION="2.34.3"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="LGPL"
PKG_SITE="http://www.gtk.org/"
PKG_URL="http://ftp.gnome.org/pub/gnome/sources/glib/2.34/$PKG_NAME-$PKG_VERSION.tar.xz"
PKG_DEPENDS="zlib $ICONV libffi pcre"
PKG_BUILD_DEPENDS="toolchain zlib $ICONV libffi libffi-host pcre Python-host"
PKG_PRIORITY="optional"
PKG_SECTION="devel"
PKG_SHORTDESC="glib: C support library"
PKG_LONGDESC="GLib is a library which includes support routines for C such as lists, trees, hashes, memory allocation, and many other things."

PKG_IS_ADDON="no"
PKG_AUTORECONF="yes"

# package specific configure options
PKG_CONFIGURE_OPTS_HOST="--disable-silent-rules \
                         --disable-debug \
                         --disable-selinux \
                         --disable-fam \
                         --disable-xattr \
                         --disable-gtk-doc \
                         --disable-man \
                         --disable-dtrace \
                         --disable-systemtap \
                         --disable-gcov \
                         --with-gnu-ld \
                         --with-libiconv=no \
                         --disable-rebuilds"

PKG_CONFIGURE_OPTS_TARGET="ac_cv_func_mmap_fixed_mapped='yes' \
                           ac_cv_func_posix_getpwuid_r='yes' \
                           ac_cv_func_posix_getgrgid_r='yes' \
                           ac_cv_func_printf_unix98='yes' \
                           ac_cv_func_snprintf_c99='yes' \
                           ac_cv_func_vsnprintf_c99='yes' \
                           glib_cv_stack_grows='no' \
                           glib_cv_uscore='no' \
                           glib_cv_va_val_copy='no' \
                           --disable-silent-rules \
                           --disable-debug \
                           --disable-selinux \
                           --disable-fam \
                           --enable-xattr \
                           --disable-gtk-doc \
                           --disable-man \
                           --disable-dtrace \
                           --disable-systemtap \
                           --disable-gcov \
                           --enable-Bsymbolic \
                           --with-gnu-ld \
                           --with-threads=posix \
                           --with-pcre=system"

if [ "$ICONV" = "libiconv" ]; then
  PKG_CONFIGURE_OPTS_TARGET="$PKG_CONFIGURE_OPTS_TARGET --with-libiconv"
fi

pre_build_target() {
  # glib needs to be build for HOST first
    $SCRIPTS/build glib:host
}

pre_configure_host() {
  ZLIB_CFLAGS=""
  ZLIB_LIBS="" 
  LIBFFI_CFLAGS="-I$ROOT/$TOOLCHAIN/include/libffi" 
  LIBFFI_LIBS="-L$ROOT/$TOOLCHAIN/lib -lffi"
}

pre_configure_target() {
  # glib segfaults with LTO optimization
    strip_lto
}

post_makeinstall_target() {
  mkdir -p $SYSROOT_PREFIX/usr/lib/pkgconfig
    cp *.pc $SYSROOT_PREFIX/usr/lib/pkgconfig

  mkdir -p $SYSROOT_PREFIX/usr/share/aclocal
    cp ../m4macros/glib-gettext.m4 $SYSROOT_PREFIX/usr/share/aclocal

  rm -rf $INSTALL/usr/bin
  rm -rf $INSTALL/usr/lib/gdbus-*
  rm -rf $INSTALL/usr/lib/gio
  rm -rf $INSTALL/usr/lib/glib-*
  rm -rf $INSTALL/usr/share
}

pre_makeinstall_host() {
  cp -f gobject/.libs/glib-genmarshal $ROOT/$TOOLCHAIN/bin
  cp -f gobject/glib-mkenums $ROOT/$TOOLCHAIN/bin
}
