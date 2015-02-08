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
PKG_SITE="http://qt-project.org"
PKG_URL="http://download.qt-project.org/official_releases/qt/5.4/$PKG_VERSION/single/qt-everywhere-opensource-src-$PKG_VERSION.tar.gz"

case $PROJECT in
	Generic)
		PKG_DEPENDS_TARGET="bzip2 Python zlib:host zlib libpng tiff dbus glib fontconfig glibc liberation-fonts-ttf font-util font-xfree86-type1 font-misc-misc alsa"
		PKG_BUILD_DEPENDS_TARGET="bzip2 Python zlib:host zlib libpng tiff dbus glib fontconfig openssl linux-headers glibc alsa"
	;;
	RPi|RPi2)
		PKG_DEPENDS_TARGET="bcm2835-driver bzip2 Python zlib:host zlib libpng tiff dbus glib fontconfig glibc liberation-fonts-ttf font-util font-xfree86-type1 font-misc-misc  alsa"
		PKG_BUILD_DEPENDS_TARGET="bcm2835-driver bzip2 Python zlib:host zlib libpng tiff dbus glib fontconfig mysql openssl linux-headers glibc alsa"

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
							-prefix ${ROOT}/${BUILD}/image/system/usr \
							-hostprefix ${SYSROOT_PREFIX}/usr \
							-release \
							-opensource \
							-confirm-license \
							-no-pch \
							-no-rpath \
							-optimized-qmake \
							-skip qtwebkit \
							-silent \
							-make libs \
							-nomake tests"
	;;
	RPi)
		PKG_CONFIGURE_OPTS="\
							-prefix ${ROOT}/${BUILD}/image/system/usr \
							-hostprefix ${SYSROOT_PREFIX}/usr \
							-release \
							-opensource \
							-confirm-license \
							-no-pch \
							-no-rpath \
							-optimized-qmake \
							-skip qtwebkit \
							-silent \
							-device linux-rasp-pi-g++ \
							-device-option CROSS_COMPILE=${ROOT}/${TOOLCHAIN}/bin/armv6zk-openelec-linux-gnueabi- \
							-opengl \
							-I $SYSROOT_PREFIX/usr/include/interface/vmcs_host \
							-I $SYSROOT_PREFIX/usr/include/gstreamer-1.0 \
							-I $SYSROOT_PREFIX/usr/include/glib-2.0 \
							-I $SYSROOT_PREFIX/usr/lib/glib-2.0/include \
							-make libs \
							-nomake examples \
							-nomake tests"
	;;

 	RPi2)
                PKG_CONFIGURE_OPTS="\
                                                        -prefix ${SYSROOT_PREFIX}/usr \
                                                        -hostprefix ${SYSROOT_PREFIX}/usr \
                                                        -sysroot ${SYSROOT_PREFIX}
                                                        -release \
                                                        -v \
                                                        -opensource \
                                                        -confirm-license \
                                                        -no-pch \
                                                        -no-rpath \
                                                        -optimized-qmake \
                                                        -skip qtwebkit \
                                                        -device linux-rasp-pi-g++ \
                                                        -device-option CROSS_COMPILE=${ROOT}/${TOOLCHAIN}/bin/armv7a-openelec-linux-gnueabi-
                                                        -opengl es2\
                                                        -I $SYSROOT_PREFIX/usr/include/interface/vmcs_host \
                                                        -I $SYSROOT_PREFIX/usr/include/gstreamer-1.0 \
                                                        -I $SYSROOT_PREFIX/usr/include/glib-2.0 \
                                                        -I $SYSROOT_PREFIX/usr/lib/glib-2.0/include \
                                                        -make libs \
                                                        -static \
                                                        -nomake examples \
                                                        -nomake tests"
        ;;
esac

unpack() {

	tar -xzf $SOURCES/${PKG_NAME}/qt-everywhere-opensource-src-${PKG_VERSION}.tar.gz -C $BUILD/
	mv $BUILD/qt-everywhere-opensource-src-${PKG_VERSION} $BUILD/${PKG_NAME}-${PKG_VERSION}
	
}

configure_target() {

	case $PROJECT in
		Generic)
			unset CC CXX AR OBJCOPY STRIP CFLAGS CXXFLAGS CPPFLAGS LDFLAGS LD RANLIB
			export QT_FORCE_PKGCONFIG=yes
			unset QMAKESPEC

			pushd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}
			./configure ${PKG_CONFIGURE_OPTS}
			popd
		;;
		RPi|RPi2)
			unset CC CXX AR OBJCOPY STRIP CFLAGS CXXFLAGS CPPFLAGS LDFLAGS LD RANLIB
			export QT_FORCE_PKGCONFIG=yes
			unset QMAKESPEC
		
			cp $SYSROOT_PREFIX/usr/include/interface/vcos/pthreads/vcos_platform_types.h $SYSROOT_PREFIX/usr/include/interface/vcos/
			cp $SYSROOT_PREFIX/usr/include/interface/vcos/pthreads/vcos_platform.h $SYSROOT_PREFIX/usr/include/interface/vcos/
			cp $SYSROOT_PREFIX/usr/include/interface/vmcs_host/linux/vchost_config.h $SYSROOT_PREFIX/usr/include/interface/vmcs_host/
		
			pushd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}
			./configure ${PKG_CONFIGURE_OPTS}
			popd
		;;
	esac
}

make_target() {
	case $PROJECT in
		Generic)
			unset CC CXX AR OBJCOPY STRIP CFLAGS CXXFLAGS CPPFLAGS LDFLAGS LD RANLIB
			export QT_FORCE_PKGCONFIG=yes
			unset QMAKESPEC

			pushd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}
			make
			popd
		;;
		RPi|RPi2)
			unset CC CXX AR OBJCOPY STRIP CFLAGS CXXFLAGS CPPFLAGS LDFLAGS LD RANLIB
			export QT_FORCE_PKGCONFIG=yes
			unset QMAKESPEC
		
			pushd ${ROOT}/${BUILD}/${PKG_NAME}-${PKG_VERSION}
			make
			popd
		;;
	esac
}

makeinstall_target() {
	case $PROJECT in
		Generic)
			pushd ${ROOT}/${PKG_BUILD}
			make install
			popd
		;;
		RPi|RPi2)
			unset CC CXX AR OBJCOPY STRIP CFLAGS CXXFLAGS CPPFLAGS LDFLAGS LD RANLIB
			export QT_FORCE_PKGCONFIG=yes
			unset QMAKESPEC
		
			pushd ${ROOT}/${PKG_BUILD}
			make install
			popd
		;;
	esac
}

pre_install() {
	makeinstall_target
}

post_install() {
	case $PROJECT in
		Generic)
		;;
		RPi|RPi2)
			# need to remove libc.so and libpthread.so linker scripts to enable cross compilation with qmake.
			# otherwise it would try to fail when linking with the wrong libraries.
			
			rm $ROOT/$INSTALL/usr/lib/libc.so
			rm $ROOT/$INSTALL/usr/lib/libpthread.so
		;;
	esac
}
