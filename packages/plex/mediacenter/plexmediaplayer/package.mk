#!/bin/bash
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

PKG_NAME="${MEDIACENTER,,}"

# Edit CI repo name to exclude origin
if [[ "$PMP_BRANCH" =~ .*/.* ]]; then
  export GIT_REPO="`echo $PMP_BRANCH | sed 's/.*\///g'`"
fi

case $PROJECT in
     Generic|Nvidia_Legacy)
     PKG_VERSION="${GIT_REPO:-dist-ninja}"
     ;;
     RPi|RPi2)
     PKG_VERSION="${GIT_REPO:-dist-ninja}"
     ;;
esac

PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://nightlies.plex.tv"
PKG_URL="$PKG_SITE/directdl/plex-oe-sources/$PKG_NAME-dummy.tar.gz"
PKG_DEPENDS_TARGET="toolchain systemd fontconfig qt libX11 xrandr libcec mpv SDL2 libXdmcp breakpad breakpad:host libconnman-qt strace ${MEDIACENTER,,}-fonts-ttf fc-cache"
PKG_DEPENDS_HOST="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="mediacenter"
PKG_SHORTDESC="Plex Media Player"
PKG_LONGDESC="Plex is the king or PC clients for Plex :P"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

if [ "$CI_BUILD" = true ]; then
 PLEX_DUMP_SYMBOLS=yes
fi

if [ "$KODI_SAMBA_SUPPORT" = yes ]; then
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET samba"
fi


#add gdb tools if we are in debug
if [ "$PLEX_DEBUG" = yes ]; then
	PKG_DEPENDS_TARGET="${PKG_DEPENDS_TARGET} gdb"
fi

if [ ! -z "$CI_CRASHDUMP_SECRET" ]; then
  CRASHDUMP_SECRET="-DCRASHDUMP_SECRET=${CI_CRASHDUMP_SECRET}"
fi

unpack() {
if false ; then
        if [ -d $BUILD/${PKG_NAME}-${PKG_VERSION} ]; then
          cd $BUILD/${PKG_NAME}-${PKG_VERSION} ; rm -rf build
          git pull ; git reset --hard
        else
          rm -rf $BUILD/${PKG_NAME}-${PKG_VERSION}
          git clone --depth 20 -b $PKG_VERSION git@github.com:plexinc/$PMP_REPO.git $BUILD/${PKG_NAME}-${PKG_VERSION}
          if [ ! -z "$PMP_RELEASE_SHA" ]; then
            if [ "`git --git-dir=$BUILD/${PKG_NAME}-${PKG_VERSION}/.git --work-tree=$BUILD/${PKG_NAME}-${PKG_VERSION} log --pretty=%H|grep -c $PMP_RELEASE_SHA`" = "1" ]; then
              git --git-dir=$BUILD/plexmediaplayer-${PKG_VERSION}/.git --work-tree=$BUILD/plexmediaplayer-${PKG_VERSION} checkout $PMP_RELEASE_SHA
              echo "Checked out $PMP_RELEASE_SHA release from github."
            else
              echo "There are more than 20 commits in the REPO since the release build was initiated. Erroring out!"
              exit 1
            fi
          fi
        fi
fi

           git clone /mnt/ssd/money/konvergo $BUILD/${PKG_NAME}-${PKG_VERSION}
          cd $ROOT

	if [ "$PLEX_DEBUG" = yes ]; then
		cd $BUILD/${PKG_NAME}-${PKG_VERSION}

		#This is used when using QtCreator from the build tree to deploy to /storage root
		cp $PKG_DIR/QtCreatorDeployment.txt $ROOT/$BUILD/${PKG_NAME}-${PKG_VERSION}/

		#This allows cross compiler to find the libs that are used by other libs for QT5 
		cp $PKG_DIR/ld.so.conf $SYSROOT_PREFIX/etc/

		cd $ROOT
	fi

	# Grab a prebuilt archive for web stuff using WEB_CLIENT_VERSION from knovergo cmake file
#        WEB_CLIENT_VERSION=`cat $BUILD/${PKG_NAME}-${PKG_VERSION}/CMakeModules/WebClientVariables.cmake|awk '/WEB_CLIENT_VERSION/ {gsub(")$","") ; print $2}'`
#        mkdir -p cd $BUILD/${PKG_NAME}-${PKG_VERSION}/build/src
#	cd $BUILD/${PKG_NAME}-${PKG_VERSION}/build/src
#        wget https://nightlies.plex.tv/directdl/plex-web-client-${MEDIACENTER,,}/master/plex-web-client-${MEDIACENTER,,}-${WEB_CLIENT_VERSION}.cpp.bz2 -O web-client-${WEB_CLIENT_VERSION}.cpp.bz2
	cd ${ROOT}	
}

configure_target() {
        cd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}

        # Create seperate config build dir to not work in the github tree
        [ ! -d build ] && mkdir build
        cd build

 	if [ "$PLEX_DEBUG" = yes ]; then
          BUILD_TYPE="debug"
        else
          BUILD_TYPE="RelWithDebInfo"
        fi

        # Configure the build
	case $PROJECT in
        	Generic|Nvidia_Legacy)
		cmake \
			-DCMAKE_INSTALL_PREFIX=/usr \
                        -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
                        -DCMAKE_LIBRARY_PATH="${SYSROOT_PREFIX}/usr/lib" \
                        -DCMAKE_PREFIX_PATH="${SYSROOT_PREFIX};${SYSROOT_PREFIX}/usr/local/qt5" \
                        -DCMAKE_INCLUDE_PATH="${SYSROOT_PREFIX}/usr/include" \
                        -DQTROOT=${SYSROOT_PREFIX}/usr/local/qt5 \
                        -DCMAKE_FIND_ROOT_PATH="${SYSROOT_PREFIX}/usr/local/qt5" \
                        -DUSE_QTQUICK=on \
                        -DENABLE_MPV=on \
                        -DCMAKE_VERBOSE_MAKEFILE=on \
                        -DOPENELEC=on \
                        -DENABLE_DUMP_SYMBOLS=on \
			$CRASHDUMP_SECRET \
                        $ROOT/$BUILD/$PKG_NAME-$PKG_VERSION/.
        	;;

        	RPi|RPi2)
		cmake \
                        -DCMAKE_INSTALL_PREFIX=/usr \
                        -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
                        -DCMAKE_LIBRARY_PATH="${SYSROOT_PREFIX}/usr/lib" \
                        -DCMAKE_PREFIX_PATH="${SYSROOT_PREFIX};${SYSROOT_PREFIX}/usr/local/qt5" \
                        -DCMAKE_INCLUDE_PATH="${SYSROOT_PREFIX}/usr/include" \
                        -DQTROOT=${SYSROOT_PREFIX}/usr/local/qt5 \
                        -DCMAKE_FIND_ROOT_PATH="${SYSROOT_PREFIX}/usr/local/qt5" \
                        -DUSE_QTQUICK=on \
                        -DENABLE_MPV=on \
                        -DBUILD_TARGET="RPI" \
                        -DCMAKE_VERBOSE_MAKEFILE=on \
                        -DOPENELEC=on \
                        -DENABLE_DUMP_SYMBOLS=on \
			$CRASHDUMP_SECRET \
                        $ROOT/$BUILD/$PKG_NAME-$PKG_VERSION/.

		#make the Qt JPEG hardware decoding plugin
		cd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}/src/plugins/RPI_jpeg
		${ROOT}/${BUILD}/bin/qmake CONFIG+=${BUILD_TYPE}
		make
		cd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}/build		
        	;;
	esac
}

makeinstall_target() {
  	mkdir -p $INSTALL/usr/bin
        cp  $ROOT/$BUILD/$PKG_NAME-$PKG_VERSION/build/src/${MEDIACENTER,,} ${INSTALL}/usr/bin/
	cp  $ROOT/$BUILD/$PKG_NAME-$PKG_VERSION/build/src/pmphelper ${INSTALL}/usr/bin/

	mkdir -p $INSTALL/usr/share/${MEDIACENTER,,} $INSTALL/usr/share/${MEDIACENTER,,}/scripts
	cp -R $ROOT/$BUILD/$PKG_NAME-$PKG_VERSION/resources/* ${INSTALL}/usr/share/${MEDIACENTER,,}
        cp $PKG_DIR/scripts/plex_update.sh ${INSTALL}/usr/share/${MEDIACENTER,,}/scripts/


	if [ "$PLEX_DEBUG" = yes ]; then
		#This allows cross compiler to find the libs that are used by other libs for QT5
                mkdir -p ${INSTALL}/etc
		cp $PKG_DIR/ld.so.conf $INSTALL/etc/		
	fi

	case $PROJECT in
	  RPi|RPi2)
	    #install RPI HW image decoding plugin and remove default qt plugin
	    cd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}/src/plugins/RPI_jpeg
	    mkdir -p $INSTALL/usr/local/qt5/plugins/imageformats
	    cp libRPI_jpeg.so $INSTALL/usr/local/qt5/plugins/imageformats
	    cd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}
	  ;;
	esac	 	
}

post_install() {
# link default.target to plex.target
  ln -sf plex.target $INSTALL/usr/lib/systemd/system/default.target

# enable default services
  enable_service plex-autostart.service
  enable_service plex.service
  enable_service plex.target
  enable_service plex-waitonnetwork.service

# install plex splash screen
  cp $PKG_DIR/oemsplash.png $INSTALL/flash
}

post_install() {
# link default.target to plex.target
  ln -sf plex.target $INSTALL/usr/lib/systemd/system/default.target

# enable default services
  enable_service plex-autostart.service
  enable_service plex.service
  enable_service plex.target
  enable_service plex-waitonnetwork.service

  echo "Generating pre-fontcache"
  export FONTCONFIG_FILE=$ROOT/$BUILD/image/system/etc/fonts/fonts.conf
  $ROOT/$TOOLCHAIN/bin/fc-cache -fv  -y ${ROOT}/${BUILD}/image/system /usr/share/fonts
}
