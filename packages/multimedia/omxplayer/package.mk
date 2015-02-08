################################################################################
#      This file is part of OpenELEC - http://www.openelec.tv
#      Copyright (C) 2009-2014 Stephan Raue (stephan@openelec.tv)
#
#  OpenELEC is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 2 of the License, or
#  (at your option) any later version.
#
#  OpenELEC is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with OpenELEC.  If not, see <http://www.gnu.org/licenses/>.
################################################################################

PKG_NAME="omxplayer"
PKG_VERSION="1.0.0"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://nightlies.plex.tv"
PKG_URL="$PKG_SITE/plex-oe-sources/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain bcm2835-driver boost freetype pcre dbus"
PKG_PRIORITY="optional"
PKG_SECTION="multimedia"
PKG_SHORTDESC="OMX Player"
PKG_LONGDESC=""

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

PKG_CONFIGURE_OPTS_TARGET=""

get_graphicdrivers

make_target() {
        pushd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}
	BUILDROOT=0 SYSROOT=$SYSROOT_PREFIX make omxplayer.bin
        popd
}

makeinstall_target() {
    mkdir -p $INSTALL/usr/bin
    cp -PRv omxplayer.bin $INSTALL/usr/bin
}
