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

PKG_NAME="konvergo"

case $PROJECT in
     Generic)
     PKG_VERSION="0.1"
     ;;
     RPi|RPi2)
     PKG_VERSION="0.1-rpi2"
     ;;
esac

PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://nightlies.plex.tv"
PKG_URL="$PKG_SITE/plex-oe-sources/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain systemd fontconfig qt libiconv libcec mpv SDL2"
PKG_DEPENDS_HOST="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="mediacenter"
PKG_SHORTDESC="Plex Konvergo Mediacenter"
PKG_LONGDESC="Plex Konvergo is the king or PC clients for Plex :P"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

case $PROJECT in
  Generic)
  ;;

  RPi|RPi2)
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET omxplayer"
  ;;
esac

configure_target() {
        cd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}

	case $PROJECT in
        	Generic)
		cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_LIBRARY_PATH="${SYSROOT_PREFIX}/usr/lib" -DCMAKE_PREFIX_PATH="${SYSROOT_PREFIX}" -DCMAKE_INCLUDE_PATH="${SYSROOT_PREFIX}/usr/include" -DQTROOT=${SYSROOT_PREFIX}/usr/local/qt5 -DUSE_QTQUICK=on -DENABLE_MPV=on
        	;;

        	RPi|RPi2)
		cmake \
			-DCMAKE_BUILD_TYPE=Debug \
			-DCMAKE_LIBRARY_PATH="${SYSROOT_PREFIX}/usr/lib" \
			-DCMAKE_PREFIX_PATH="${SYSROOT_PREFIX};${SYSROOT_PREFIX}/usr/local/qt5" \
			-DCMAKE_INCLUDE_PATH="${SYSROOT_PREFIX}/usr/include" \
			-DQTROOT=${SYSROOT_PREFIX}/usr/local/qt5 \
			-DCMAKE_FIND_ROOT_PATH="${SYSROOT_PREFIX}/usr/local/qt5" \
			-DUSE_QTQUICK=on \
			-DENABLE_MPV=on \
			-DENABLE_OMX=on
        	;;
	esac
}
