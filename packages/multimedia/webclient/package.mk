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

PKG_NAME="webclient"
PKG_VERSION="0.1"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://nightlies.plex.tv"
PKG_URL="$PKG_SITE/plex-oe-sources/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="multimedia"
PKG_SHORTDESC="Plex Web Client"
PKG_LONGDESC="Plex Web Client"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

configure_target() {
 echo ""
}

make_target() {
 echo ""
}

makeinstall_target() {

	mkdir -p $INSTALL/usr/share/konvergo/webclient
        cp -R ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}/* $INSTALL/usr/share/konvergo/webclient
	mkdir -p ${ROOT}/${BUILD}/konvergo-master/web-client/build/
	cp -R ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}/* ${ROOT}/${BUILD}/konvergo-master/web-client/build/
        cd ${ROOT}
}
