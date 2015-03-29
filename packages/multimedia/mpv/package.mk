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

PKG_NAME="mpv"
PKG_VERSION="master"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://nightlies.plex.tv"
PKG_URL="$PKG_SITE/plex-oe-sources/$PKG_NAME-dummy.tar.gz"
PKG_DEPENDS_TARGET="toolchain libmad libass ffmpeg qt"
PKG_PRIORITY="optional"
PKG_SECTION="multimedia"
PKG_SHORTDESC="MPV Movie Player
PKG_LONGDESC="

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

PKG_CONFIGURE_OPTS_TARGET="--enable-libmpv-shared --disable-cplayer --disable-apple-remote --prefix=${SYSROOT_PREFIX}/usr"

unpack() {

        mkdir $BUILD/${PKG_NAME}-${PKG_VERSION}
        case $PROJECT in
                Generic)
                git clone -b $PKG_VERSION git@github.com:mpv-player/mpv.git $BUILD/${PKG_NAME}-${PKG_VERSION}/.
                ;;
                RPi|RPi2)
                git clone -b $PKG_VERSION git@github.com:mpv-player/mpv.git $BUILD/${PKG_NAME}-${PKG_VERSION}/.
                ;;
        esac
}

configure_target() {
        cd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}
	./bootstrap.py
        ./waf configure ${PKG_CONFIGURE_OPTS_TARGET}
}

make_target() {
        cd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}
        ./waf build
}

makeinstall_target() {
        cd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}
        ./waf install

	mkdir -p $INSTALL/usr/lib
        cp ${SYSROOT_PREFIX}/usr/lib/libmpv.so ${INSTALL}/usr/lib

	cd ${INSTALL}/usr/lib/
	ln -s libmpv.so libmpv.so.1

        cd ${ROOT}
}
