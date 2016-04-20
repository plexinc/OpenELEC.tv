################################################################################
#      This file is part of OpenELEC - http://www.openelec.tv
#      Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
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

PKG_NAME="ffmpeg-codecs"
PKG_VERSION="konvergo-codecs"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="LGPLv2.1+"
PKG_SITE="https://nightlies.plex.tv"
PKG_URL="$PKG_SITE/directdl/plex-oe-sources/ffmpeg-dummy.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="service/multimedia"
PKG_SHORTDESC="Special ffmpeg sauce"
PKG_LONGDESC="Special ffmpeg sauce"

PKG_IS_ADDON="yes"
PKG_ADDON_TYPE="dummy"
PKG_ADDON_PROVIDES=""
PKG_ADDON_REPOVERSION="6.0"

PKG_AUTORECONF="no"

## PLEX
if [ "$CI_BUILD" = true ]; then
 PLEX_DUMP_SYMBOLS=yes
fi

case $PROJECT in
        RPi|RPi2)
        BUILD_TAG="linux-openelec-armv7"
        PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET bcm2835-driver"
        ;;

        Generic|Nvidia_Legacy)
        BUILD_TAG="linux-openelec-x86_64"
        ;;
esac

unpack() {

        git clone --depth 1 -b $PKG_VERSION git@github.com:${DEPS_REPO}.git $BUILD/${PKG_NAME}-${PKG_VERSION}

}
### END PLEX

make_target() {
  export TARGET_CPU TARGET_ARCH TARGET_PREFIX SYSROOT_PREFIX HOST_CC HOST_CFLAGS HOST_LDFLAGS ARCH ROOT TOOLCHAIN
  ./bootstrap.py -k ${DEPS_PROJECT} -j 6 -p $BUILD_TAG -e ${PMP_GROUP} -v build
  : # nothing to do here
}

makeinstall_target() {
  if [ ! -d $ROOT/output/Packages ]; then
    mkdir -p $ROOT/output/Packages
  else
    rm -rf $ROOT/output/Packages
    mkdir -p $ROOT/output/Packages
  fi
  if [ ! -d $INSTALL/usr/lib ]; then
    mkdir -p $INSTALL/usr/lib
  fi

  cp -R $ROOT/$BUILD/${PKG_NAME}-${PKG_VERSION}/output/Packages/* $ROOT/output/Packages/.
  cp -R $ROOT/$BUILD/${PKG_NAME}-${PKG_VERSION}/output/konvergo-codecs-depends-linux-openelec-*-release*/lib/*.so* $INSTALL/usr/lib/.
}

addon() {
  : # nothing to do here
}
