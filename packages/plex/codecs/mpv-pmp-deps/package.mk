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

PKG_NAME="mpv-pmp-deps"
PKG_VERSION="konvergo-codecs"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="LGPLv2.1+"
PKG_SITE="https://nightlies.plex.tv"
PKG_URL="$PKG_SITE/directdl/plex-oe-sources/mpv-pmp-deps-dummy.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="service/multimedia"
PKG_SHORTDESC="Special ffmpeg sauce"
PKG_LONGDESC="Special ffmpeg sauce"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

# Edit CI repo name to exclude origin
if [ ! -z "$PMP_BRANCH" ]; then
  export GIT_REPO="`echo ${PMP_BRANCH/origin\//}`"
fi

case $PROJECT in
     Generic|Nvidia_Legacy|RPi|RPi2)
       DEPS_PMP_REPO="${GIT_REPO:-dist-ninja}"
     ;;
esac

unpack() {
  # Create build dir
  BUILD_DIR="${BUILD}/${PKG_NAME}-${PKG_VERSION}"
  if [ ! -d ${BUILD_DIR} ]; then
    mkdir -p ${BUILD_DIR} 
  fi

  # Set variables for downloads
  case $PROJECT in
      RPi|RPi2)
      BUILD_TAG="linux-openelec-armv7"
    ;;
      Generic|Nvidia_Legacy)
      BUILD_TAG="linux-openelec-x86_64"
    ;;
  esac

  PLEX_GITSHA=`git ls-remote --heads git@github.com:plexinc/${PMP_REPO:-plex-media-player}.git $DEPS_PMP_REPO |awk '{print substr($0,0,8)}'`
  DEPS_VERSION="`curl -s -u plex-konvergo:$GIT_TOKEN https://raw.githubusercontent.com/plexinc/${PMP_REPO:-plex-media-player}/$PLEX_GITSHA/CMakeModules/FetchDependencies.cmake|awk '/OPENELEC/ {getline;print $0}'|sed -n 's/.*NUMBER *\([^ ]*\))/\1/p'`"
  DEPS_HASH="`curl -s https://nightlies.plex.tv/directdl/plex-dependencies/plexmediaplayer-openelec-codecs/$DEPS_VERSION/hash.txt`"
  DEPS_FILE="konvergo-codecs-depends-$BUILD_TAG-release-$DEPS_HASH.tbz2"
  DEPS_URL="$PKG_SITE/directdl/plex-dependencies/plexmediaplayer-openelec-codecs/$DEPS_VERSION/$DEPS_FILE"

  wget -q ${DEPS_URL} -P ${BUILD_DIR}
  FILE_HASH="`curl -s ${DEPS_URL}.sha.txt`"

  # Check file hash
  if [ "`sha1sum ${BUILD_DIR}/${DEPS_FILE} |awk '{print $1}'`" = "${FILE_HASH}" ]; then
    tar xjf ${BUILD_DIR}/${DEPS_FILE} -C ./${BUILD_DIR} --wildcards --no-anchored 'lib*so*' 'lib*pc' '*h' --exclude='*lib/components/*' --strip=1
    rm -f ${BUILD_DIR}/${DEPS_FILE}
  else
    exit 1
  fi
}

configure_target() {
  : # nothin to do here
}
make_target() {
  : # nothing to do here
}

makeinstall_target() {
  cp -R lib/lib* ${SYSROOT_PREFIX}/usr/lib/
  cp -R include ${SYSROOT_PREFIX}/usr/
  cp -R lib/pkgconfig/* ${SYSROOT_PREFIX}/usr/lib/pkgconfig/

  echo $INSTALL

  mkdir -p $INSTALL/usr/lib
  cp -R lib/lib* ${INSTALL}/usr/lib/
}
