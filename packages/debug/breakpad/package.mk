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

PKG_NAME="breakpad"
PKG_VERSION="master"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://code.google.com/p/google-breakpad"
PKG_URL="https://github.com/RasPlex/breakpad/archive/master.tar.gz"
PKG_DEPENDS="toolchain "
PKG_BUILD_DEPENDS="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="devel"
PKG_SHORTDESC="Generate minidupms"
PKG_LONGDESC="Generate minidump files for easier debugging and stack tracing"
PKG_IS_ADDON="no"
PKG_AUTORECONF="no"


PKG_IS_ADDON="no"
PKG_AUTORECONF="no"




unpack() {
	cd $ROOT/$BUILD
	#tar -xpf $ROOT/sources/$PKG_NAME/$PKG_NAME-$PKG_VERSION.tar.gz -C $ROOT/$BUILD/ 
	#mv $ROOT/$BUILD/$PKG_NAME-$PKG_NAME-$PKG_VERSION/ $ROOT/$BUILD/$PKG_NAME-$PKG_VERSION
	tar -xpf $ROOT/sources/$PKG_NAME/$PKG_VERSION.tar.gz -C $ROOT/$BUILD/ 

}

PKG_CONFIGURE_OPTS_TARGET="--host=$TARGET_NAME \
                           --prefix=$INSTALL/usr \
                           --disable-tools \
                           --disable-processor"





post_makeinstall_target() {


	cd $ROOT/$BUILD/$PKG_NAME-$PKG_VERSION

	mkdir -p $SYSROOT_PREFIX/usr/include/client/linux/handler/

	#find src -type f | grep -v ".h$" | xargs -I{} rm {}
	cp -r src/* $SYSROOT_PREFIX/usr/include/
	cp -r third_party $SYSROOT_PREFIX/usr/include/
}
