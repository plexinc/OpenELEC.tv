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

PKG_NAME="fc-cache"
PKG_VERSION="$TARGET_ARCH"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="https://nightlies.plex.tv"
PKG_URL="$PKG_SITE/directdl/plex-oe-sources/$PKG_NAME-$PKG_VERSION.$PKG_REV.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="x11"
PKG_SHORTDESC="fc-cache host binary to pre-build fontconfig cache"
PKG_LONGDESC="fc-cache host binary to pre-build fontconfig cache"

PKG_IS_ADDON="no"
PKG_AUTORECONF=""

configure_target() {
 cd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}
}

make_target() {
 # Nothing to do here
 cd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}
}

makeinstall_target() {
 # Nothing to do here
 cd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}
 cp ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}/fc-cache $ROOT/$TOOLCHAIN/bin/
}
