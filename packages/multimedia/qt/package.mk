################################################################################
#
##  This Program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  #  the Free Software Foundation; either version 2, or (at your option)
#  any later version.
#  #
#  This Program is distributed in the hope that it will be useful,
#  #  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  #  GNU General Public License for more details.
#
##  You should have received a copy of the GNU General Public License
#  along with OpenELEC.tv; see the file COPYING.  If not, write to
#  #  the Free Software Foundation, 51 Franklin Street, Suite 500, Boston, MA 02110, USA.
#  http://www.gnu.org/copyleft/gpl.html
#  ################################################################################

PKG_NAME="qt"
PKG_VERSION="5.4.0"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="https://nightlies.plex.tv"
PKG_URL="$PKG_SITE/plex-oe-sources/$PKG_NAME-everywhere-opensource-src-$PKG_VERSION.tar.gz"

case $PROJECT in
	Generic)
		PKG_DEPENDS_TARGET="bzip2 Python zlib:host zlib libpng tiff dbus glib fontconfig glibc liberation-fonts-ttf font-util font-xfree86-type1 font-misc-misc alsa flex bison ruby icu sqlite"
		PKG_BUILD_DEPENDS_TARGET="bzip2 Python zlib:host zlib libpng tiff dbus glib fontconfig openssl linux-headers glibc alsa"
	;;
	RPi|RPi2)
		PKG_DEPENDS_TARGET="bcm2835-driver bzip2 Python zlib:host zlib libpng tiff dbus glib fontconfig glibc liberation-fonts-ttf font-util font-xfree86-type1 font-misc-misc alsa flex bison ruby icu sqlite"
		PKG_BUILD_DEPENDS_TARGET="bcm2835-driver bzip2 Python zlib:host zlib libpng tiff dbus glib fontconfig openssl linux-headers glibc alsa"

	;;
esac

PKG_PRIORITY="optional"
PKG_SECTION="lib"
PKG_SHORTDESC="Qt GUI toolkit"
PKG_LONGDESC="Qt GUI toolkit"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

case $PROJECT in
	Generic)
                PKG_CONFIGURE_OPTS="\
                                                        -sysroot ${SYSROOT_PREFIX} \
                                                        -extprefix ${SYSROOT_PREFIX}/usr/local/qt5 \
                                                        -release \
                                                        -v \
                                                        -opensource \
                                                        -confirm-license \
                                                        -optimized-qmake \
                                                        -shared \
							-opengl es2 \
                                                        -make libs \
							-qt-xcb \
                                                        -nomake examples \
                                                        -no-pch \
                                                        -nomake tests"
	;;
 	RPi|RPi2)
                PKG_CONFIGURE_OPTS="\
                                                        -sysroot ${SYSROOT_PREFIX} \
                                                        -extprefix ${SYSROOT_PREFIX}/usr/local/qt5 \
                                                        -release \
                                                        -v \
                                                        -opensource \
                                                        -confirm-license \
                                                        -optimized-qmake \
							-shared \
                                                        -device linux-rasp-pi-g++ \
                                                        -device-option CROSS_COMPILE=${ROOT}/${TOOLCHAIN}/bin/armv7a-openelec-linux-gnueabi-
                                                        -opengl es2\
                                                        -make libs \
                                                        -nomake examples \
                                                        -no-pch \
                                                        -nomake tests"
        ;;
esac

unpack() {

	tar -xzf $SOURCES/${PKG_NAME}/qt-everywhere-opensource-src-${PKG_VERSION}.tar.gz -C $BUILD/
	mv $BUILD/qt-everywhere-opensource-src-${PKG_VERSION} $BUILD/${PKG_NAME}-${PKG_VERSION}
	
}

pre_configure_target() {
   cd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}
   sed -i "s,##SYSROOT_PREFIX##,${SYSROOT_PREFIX}/usr/include,g" qtbase/src/gui/gui.pro 
}

configure_target() {

	case $PROJECT in
		Generic)
			unset CC CXX AR OBJCOPY STRIP CFLAGS CXXFLAGS CPPFLAGS LDFLAGS LD RANLIB
			export QT_FORCE_PKGCONFIG=yes
			unset QMAKESPEC

			cd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}
			./configure ${PKG_CONFIGURE_OPTS}
		;;
		RPi|RPi2)
			unset CC CXX AR OBJCOPY STRIP CFLAGS CXXFLAGS CPPFLAGS LDFLAGS LD RANLIB
			export QT_FORCE_PKGCONFIG=yes
			unset QMAKESPEC
		
			cp $SYSROOT_PREFIX/usr/include/interface/vcos/pthreads/vcos_platform_types.h $SYSROOT_PREFIX/usr/include/interface/vcos/
			cp $SYSROOT_PREFIX/usr/include/interface/vcos/pthreads/vcos_platform.h $SYSROOT_PREFIX/usr/include/interface/vcos/
			cp $SYSROOT_PREFIX/usr/include/interface/vmcs_host/linux/vchost_config.h $SYSROOT_PREFIX/usr/include/interface/vmcs_host/
		
			cd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}
			./configure ${PKG_CONFIGURE_OPTS}
		;;
	esac
}

makeinstall_target() {

	cd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}
	make install

	mkdir -p $INSTALL/usr/
	cp -R ${SYSROOT_PREFIX}/usr/local/qt5/* ${INSTALL}/usr/
}
