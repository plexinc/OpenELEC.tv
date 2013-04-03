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

PKG_NAME="tinyxml"
PKG_VERSION="2.6.2"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="http://www.grinninglizard.com/tinyxml/"
PKG_URL="$SOURCEFORGE_SRC/$PKG_NAME/$PKG_VERSION/${PKG_NAME}_`echo $PKG_VERSION | sed 's,\.,_,g'`.tar.gz"
PKG_DEPENDS=""
PKG_BUILD_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="textproc"
PKG_SHORTDESC="tinyxml: XML parser library"
PKG_LONGDESC="TinyXML is a simple, small, C++ XML parser that can be easily integrating into other programs."

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

PKG_BUILD="$BUILD/$PKG_NAME-$PKG_VERSION"

pre_build_target() {
  mv $ROOT/$BUILD/$PKG_NAME $ROOT/$BUILD/$PKG_NAME-$PKG_VERSION
}

make_target() {
  for i in tinyxml.cpp tinystr.cpp tinyxmlerror.cpp tinyxmlparser.cpp; do
    echo CXX $i
    $CXX $CXXFLAGS -fPIC -o $i.o -c $i
  done
  echo LD lib${PKG_NAME}.so.${PKG_VERSION}
  $CXX $LDFLAGS -shared -o lib${PKG_NAME}.so.${PKG_VERSION} -Wl,-soname,lib${PKG_NAME}.so.0 *.cpp.o

  ln -sf lib${PKG_NAME}.so.${PKG_VERSION} lib${PKG_NAME}.so.0
  ln -sf lib${PKG_NAME}.so.0 lib${PKG_NAME}.so
}

makeinstall_target() {
  cp -P lib${PKG_NAME}.so* $SYSROOT_PREFIX/usr/lib
  cp -P ${PKG_NAME}.h $SYSROOT_PREFIX/usr/include

  mkdir -p .install_pkg/usr/lib
  cp -PR lib${PKG_NAME}.so* .install_pkg/usr/lib
}
