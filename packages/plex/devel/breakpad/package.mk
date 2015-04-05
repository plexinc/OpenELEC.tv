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

PKG_NAME="breakpad"
PKG_VERSION="master"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://nightlies.plex.tv"
PKG_URL="https://github.com/plexinc/breakpad/archive/master.zip"
PKG_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="system"
PKG_SHORTDESC="breakpad allow to get dumps when a program crashes"
PKG_LONGDESC="breakpad allow to get dumps when a program crashes"

PKG_IS_ADDON="no"
PKG_AUTORECONF="yes"

#PKG_CONFIGURE_OPTS_TARGET="--prefix=${SYSROOT_PREFIX}"

unpack() {
        if [ -d $BUILD/${PKG_NAME}-${PKG_VERSION} ]; then
          cd $BUILD/${PKG_NAME}-${PKG_VERSION}
          git pull ; git reset --hard
        else
          rm -rf $BUILD/${PKG_NAME}-${PKG_VERSION}
          git clone -b $PKG_VERSION git@github.com:plexinc/breakpad.git  $BUILD/${PKG_NAME}-${PKG_VERSION}
	  
	  cd $BUILD/${PKG_NAME}-${PKG_VERSION}
	  git submodule update --init
        fi

	cd ${ROOT}
}

post_makeinstall_target() {
	mkdir -p ${SYSROOT_PREFIX}/usr/include/breakpad/google_breakpad/common/
	cp $ROOT/$BUILD/${PKG_NAME}-${PKG_VERSION}/src/google_breakpad/common/*.h ${SYSROOT_PREFIX}/usr/include/breakpad/google_breakpad/common/
	
	mkdir -p ${SYSROOT_PREFIX}/usr/include/breakpad/client/linux/
        cp -R $ROOT/$BUILD/${PKG_NAME}-${PKG_VERSION}/src/client/linux/* ${SYSROOT_PREFIX}/usr/include/breakpad/client/linux/

	mkdir -p ${SYSROOT_PREFIX}/usr/include/breakpad/common/
        cp $ROOT/$BUILD/${PKG_NAME}-${PKG_VERSION}/src/common/*.h ${SYSROOT_PREFIX}/usr/include/breakpad/common/

 	mkdir -p ${SYSROOT_PREFIX}/usr/include/breakpad/third_party/lss
        cp $ROOT/$BUILD/${PKG_NAME}-${PKG_VERSION}/src/third_party/lss/*.h ${SYSROOT_PREFIX}/usr/include/breakpad/third_party/lss
}

