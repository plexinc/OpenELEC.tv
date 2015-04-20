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

PKG_NAME="plexht"
if [ $PROJECT = RPi ]; then
#PKG_VERSION="${RASPLEX_VERSION}"
  PKG_VERSION="wip"
  PKG_REV="1"
  PKG_SITE="http://www.rasplex.com"
  PKG_URL="https://github.com/RasPlex/RasPlex/archive/master.zip"
  PKG_SHORTDESC="Plex Home Theater with Rasplex patches"
  PKG_LONGDESC="PlexHT is based on XBMC, and is developed by Plex Inc as a desxtop client for plex media servers. This is an unofficial port of that code."
else
#  if [ "$PHT_HEAD" = "HEAD" ]; then
#    PKG_VERSION=HEAD
#  else
#    PKG_VERSION=PUBLIC
#  fi
  PKG_VERSION="v1.3.6.441-309e72d1"
  PKG_REV=$PKG_VERSION
  PKG_SITE="http://plex.tv"
  PKG_URL="http://plexrpms.markwalker.dk/OpenELEC/packages/plex-dummy.tar.gz"
  PKG_SHORTDESC="plexht: Plex Home Theater"
  PKG_LONGDESC="Plex Home Theater, is blah blah blah blah"
fi
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_DEPENDS_TARGET="libplist libshairplay libshairport lame libcec libva-intel-driver faad2 libusb boost pcre Python zlib bzip2 systemd libass curl libssh rtmpdump fontconfig tinyxml freetype libmad libogg libmodplug flac libmpeg2 taglib yajl sqlite OpenELEC-settings libmicrohttpd ffmpeg libjpeg-turbo libsamplerate tiff libcdio libvorbis gnutls swig:host debug SDL_mixer SDL_image lzo"
PKG_PRIORITY="optional"
PKG_SECTION="mediacenter"
PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

# for dbus support
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET dbus"

# needed for hosttools (Texturepacker)
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET lzo:host SDL:host SDL_image:host"

if [ "$DISPLAYSERVER" = "x11" ]; then
# for libX11 support
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET libX11 libXext"
# for libXrandr support
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET libXrandr"
fi

if [ "$OPENGL" = "mesa" ]; then
# for OpenGL (GLX) support
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET mesa glu glew"
fi

if [ "$OPENGLES_SUPPORT" = yes ]; then
# for OpenGL-ES support
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET $OPENGLES"
fi

if [ "$SDL_SUPPORT" = yes ]; then
# for SDL support
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET SDL SDL_image"
fi

if [ "$ALSA_SUPPORT" = yes ]; then
# for ALSA support
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET alsa-lib"
fi

if [ "$PULSEAUDIO_SUPPORT" = yes ]; then
# for PulseAudio support
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET pulseaudio"
fi

if [ "$ESPEAK_SUPPORT" = yes ]; then
# for espeak support
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET espeak"
fi

if [ "$CEC_SUPPORT" = yes ]; then
# for CEC support
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET libcec"
fi

if [ "$XBMC_SCR_RSXS" = yes ]; then
# for RSXS Screensaver support
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET libXt libXmu"
# fix build of RSXS Screensaver support if not using libiconv
  export jm_cv_func_gettimeofday_clobber=no
fi


if [ "$FAAC_SUPPORT" = yes ]; then
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET faac"
fi

if [ "$ENCODER_LAME" = yes ]; then
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET lame"
fi

if [ "$BLURAY_SUPPORT" = yes ]; then
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET libbluray"
fi

if [ "$AVAHI_DAEMON" = yes ]; then
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET avahi"
fi


if [ "$AIRPLAY_SUPPORT" = yes ]; then
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET libplist"
fi

if [ "$AIRTUNES_SUPPORT" = yes ]; then
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET libshairplay"
fi

if [ "$NFS_SUPPORT" = yes ]; then
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET libnfs"
fi

if [ "$AFP_SUPPORT" = yes ]; then
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET afpfs-ng"
fi

if [ "$SAMBA_SUPPORT" = yes ]; then
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET samba"
fi

if [ "$WEBSERVER" = yes ]; then
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET libmicrohttpd"
fi


if [ "$SSHLIB_SUPPORT" = yes ]; then
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET libssh"
fi

if [ ! "$XBMCPLAYER_DRIVER" = default ]; then
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET $XBMCPLAYER_DRIVER"

fi

if [ "$VDPAU" = yes ]; then
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET libvdpau"
fi

if [ "$VAAPI" = yes ]; then
# configure GPU drivers and dependencies:
  get_graphicdrivers

  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET $LIBVA"
fi

if [ "$CRYSTALHD" = yes ]; then
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET crystalhd"
fi

export CXX_FOR_BUILD="$HOST_CXX"
export CC_FOR_BUILD="$HOST_CC"
export CXXFLAGS_FOR_BUILD="$HOST_CXXFLAGS"
export CFLAGS_FOR_BUILD="$HOST_CFLAGS"
export LDFLAGS_FOR_BUILD="$HOST_LDFLAGS"

export PYTHON_VERSION="2.7"
export PYTHON_CPPFLAGS="-I$SYSROOT_PREFIX/usr/include/python$PYTHON_VERSION"
export PYTHON_LDFLAGS="-L$SYSROOT_PREFIX/usr/lib/python$PYTHON_VERSION -lpython$PYTHON_VERSION"
export PYTHON_SITE_PKG="$SYSROOT_PREFIX/usr/lib/python$PYTHON_VERSION/site-packages"
export ac_python_version="$PYTHON_VERSION"

unpack() {
        rm -rf $BUILD/${PKG_NAME}-${PKG_VERSION}
	git clone --depth 1 --branch ${PKG_VERSION} git@github.com:plexinc/plex-home-theater-public.git $BUILD/${PKG_NAME}-${PKG_VERSION}
        rm -f $BUILD/${PKG_NAME}-${PKG_VERSION}/xbmc/cores/dvdplayer/DVDCodecs/Audio/DVDAudioCodecPassthroughFFmpeg.h
        rm -f $BUILD/${PKG_NAME}-${PKG_VERSION}/xbmc/cores/dvdplayer/DVDCodecs/Audio/DVDAudioCodecPassthroughFFmpeg.cpp
}

configure_target() {

if [ $PROJECT = RPi ]; then
  # xbmc fails to build with LTO optimization if build without GOLD support
  [ ! "$GOLD_SUPPORT" = "yes" ] && strip_lto


  export CFLAGS="$CFLAGS $XBMC_CFLAGS"
  export CXXFLAGS="$CXXFLAGS $XBMC_CXXFLAGS"

	#if [ "$RASPLEX_SPEEDYLINK" == "yes" ];then
		strip_lto # way faster linking

		unset LD_OPTIM
		unset LDFLAGS
		unset TARGET_LDFLAGS
		unset GCC_OPTIM

	  export LD_OPTIM="-fuse-ld=gold"
	#  export LDFLAGS="-s"

	#fi

	export PKG_BUILD="$ROOT/$BUILD/$PKG_NAME-$PKG_VERSION"

	BUILD_DIR="$PKG_BUILD/build"
	TOOLCHAIN_DIR="$ROOT/$BUILD/toolchain"

	[ -d $BUILD_DIR ] && rm -rf $BUILD_DIR
	[ ! -d $BUILD_DIR ] && mkdir $BUILD_DIR 
	echo $TOOLCHAIN_DIR
	echo $BUILD_DIR

	cd $BUILD_DIR
	export PYTHON_EXEC="$TOOLCHAIN_DIR/armv6zk-openelec-linux-gnueabi/sysroot/usr/bin/python2.7"
	cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=$CMAKE_CONF \
				-DCMAKE_INSTALL_PREFIX=$INSTALL/usr \
				-DENABLE_PYTHON=on \
				-DSWIG_EXECUTABLE=`which swig` \
				-DSWIG_DIR=$TOOLCHAIN_DIR \
				-DLIBUSBDIR=$SYSROOT_PREFIX/usr \
				-DENABLE_DUMP_SYMBOLS=on \
				-DOPTIONAL_INCLUDE_DIR=$SYSROOT_PREFIX/usr/include \
				-DCMAKE_INCLUDE_PATH="$SYSROOT_PREFIX/usr/include/interface/vmcs_host/linux;$SYSROOT_PREFIX/usr/include/interface/vcos/pthreads;$SYSROOT_PREFIX/usr/include/python2.7/" \
				-DPYTHON_EXEC="$PYTHON_EXEC" \
				-DEXTERNAL_PYTHON_HOME="$SYSROOT_PREFIX/usr" \
				-DHOST_BREAKPAD_HOME="$ROOT/tools/breakpad" \
				-DIMAGE_BREAKPAD_HOME="$SYSROOT_PREFIX/usr" \
				-DTARGET_PLATFORM=RPI \
				-DTARGET_RPI=1 \
				-DTARGET_PREFIX=$TARGET_PREFIX \
				-DSYSROOT_PREFIX=$SYSROOT_PREFIX \
				-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE \
				$PKG_BUILD
else
  # Configure Plex
  # dont use some optimizations because of build problems
  LDFLAGS=`echo $LDFLAGS | sed -e "s|-Wl,--as-needed||"`
  # dont build parallel
  MAKEFLAGS=-j1

  # strip compiler optimization
  strip_lto

  # configure the build
  export PKG_CONFIG_PATH=$SYSROOT_PREFIX/usr/lib/pkgconfig

  cd $ROOT/$BUILD/$PKG_NAME-$PKG_VERSION
  [ ! -d build ] && mkdir build
  cd build
  cmake -DUSE_INTERNAL_FFMPEG=off -DOPENELEC=on -DENABLE_PYTHON=on -DEXTERNAL_PYTHON_HOME="$SYSROOT_PREFIX/usr" -DCMAKE_PREFIX_PATH="$SYSROOT_PREFIX" -DCMAKE_LIBRARY_PATH="$SYSROOT_PREFIX/usr/lib" -DCMAKE_INCLUDE_PATH="$SYSROOT_PREFIX/usr/include" -DFREETYPE_LIBRARY="$SYSROOT_PREFIX/usr/lib/libfreetype.so" -DFREETYPE_INCLUDE_DIRS="$SYSROOT_PREFIX/usr/include/freetype2" -DCOMPRESS_TEXTURES=on -DENABLE_AUTOUPDATE=off -DTEXTUREPACKERPATH=$PKG_DIR/config/TexturePacker -DCMAKE_INSTALL_PREFIX=/usr $ROOT/$BUILD/$PKG_NAME-$PKG_VERSION/.
fi

}

make_target() {
if [ $PROJECT = RPi ]; then
	ninja -j `nproc`

	# generate breakpad symbols
	ninja plex/CMakeFiles/PlexHomeTheater_symbols 

	# Strip the executable now that we have our breakpad symbols
	$TOOLCHAIN_DIR/bin/armv6zk-openelec-linux-gnueabi-strip plex/plexhometheater
else

# Build Plex
# dont use some optimizations because of build problems
  LDFLAGS=`echo $LDFLAGS | sed -e "s|-Wl,--as-needed||"`
# strip compiler optimization
  strip_lto

# Make the build
  export PKG_CONFIG_PATH=$SYSROOT_PREFIX/usr/lib/pkgconfig
  cd $ROOT/$BUILD/$PKG_NAME-$PKG_VERSION/build
  export CPLUS_INCLUDE_PATH="$SYSROOT_PREFIX/usr/include/python$PYTHON_VERSION"
  export PYTHON_LIBDIR=`ls -d $SYSROOT_PREFIX/usr/lib/python*`
#  export TOOLCHAIN_DIR="$ROOT/$BUILD/toolchain"
  make -j1 VERBOSE=2
fi

}

makeinstall_target() {


	PKG_BUILD=$ROOT/$BUILD/$PKG_NAME-$PKG_VERSION

	mkdir -p $INSTALL/usr/bin
		cp $PKG_DIR/scripts/cputemp $INSTALL/usr/bin
		cp $PKG_DIR/scripts/setwakeup.sh $INSTALL/usr/bin
		cp $PKG_BUILD/tools/EventClients/Clients/XBMC\ Send/xbmc-send.py $INSTALL/usr/bin/xbmc-send

	mkdir -p $INSTALL/usr/lib/plexhometheater/system/players/dvdplayer/
	mkdir -p $INSTALL/usr/lib/plexhometheater/system
		cp $PKG_BUILD/build/plex/plexhometheater $INSTALL/usr/lib/plexhometheater

	cd $PKG_BUILD
	find build/lib -not \( -name CMakeFiles -prune \) \
			-regextype posix-extended -type f \
			-not -iregex ".*svn.*|.*win32(dx)?\.vis|.*osx\.vis" \
			-iregex ".*-linux.*|.*-arm.*|.*\.vis|.*\.xbs" \
			-exec cp "{}" $INSTALL/usr/lib/plexhometheater/system/ ";"



	#need to copy over ffmpeg libs
	for i in `find build/lib/ffmpeg/ffmpeg/lib/ \
			-regextype posix-extended -type f \
			-iregex '.*so.*'` ;  do
			cp $i $INSTALL/usr/lib/plexhometheater/system/players/dvdplayer/`basename $(echo $i | sed  -r 's:lib([a-zA-Z]+)\\.so\\.([0-9]*).*:\1-\2-arm.so:')`
	done

  mkdir -p $INSTALL/usr/share/XBMC/

	cd $PKG_BUILD
	echo "pkg build: $PKG_BUILD"
	echo $INSTALL
 find system addons \
			-regextype posix-extended -type f \
			-not -iregex ".*svn.*|.*win32(dx)?\.vis|.*osx\.vis" \
			-iregex ".*-linux.*|.*-arm.*|.*\.vis|.*\.xbs" \
			-exec install -D "{}" $INSTALL/usr/lib/plexhometheater/"{}" ";"
		
	find addons language media sounds userdata system \
			-regextype posix-extended -type f \
			-not -iregex ".*-linux.*|.*-arm.*|.*\.vis|.*\.xbs|.*svn.*|.*\.orig|.*\.so|.*\.dll|.*\.pyd|.*python|.*\.zlib|.*\.conf" \
			-exec install -D -m 0644 "{}" $INSTALL/usr/share/XBMC/"{}" ";"
	cd -

	if [ ! "$XBMC_SCR_RSXS" = yes ]; then
		rm -rf $INSTALL/usr/share/XBMC/addons/screensaver.rsxs.*
	fi

	if [ ! "$XBMC_VIS_PROJECTM" = yes ]; then
		rm -rf $INSTALL/usr/share/XBMC/addons/visualization.projectm
	fi



	rm -rf $INSTALL/usr/share/XBMC/addons/visualization.dxspectrum
	rm -rf $INSTALL/usr/share/XBMC/addons/visualization.itunes
	rm -rf $INSTALL/usr/share/XBMC/addons/visualization.milkdrop
	rm -rf $INSTALL/usr/share/XBMC/addons/script.module.pysqlite
	rm -rf $INSTALL/usr/share/XBMC/addons/script.module.simplejson

	mkdir -p $INSTALL/usr/share/XBMC/addons
			cp -R $PKG_DIR/config/os.openelec.tv $INSTALL/usr/share/XBMC/addons
			$SED "s|@OS_VERSION@|$OS_VERSION|g" -i $INSTALL/usr/share/XBMC/addons/os.openelec.tv/addon.xml
			cp -R $PKG_DIR/config/repository.openelec.tv $INSTALL/usr/share/XBMC/addons
			$SED "s|@ADDON_URL@|$ADDON_URL|g" -i $INSTALL/usr/share/XBMC/addons/repository.openelec.tv/addon.xml


  mkdir -p $INSTALL/usr/lib/python"$PYTHON_VERSION"/site-packages/xbmc
    cp -R $PKG_BUILD/tools/EventClients/lib/python/* $INSTALL/usr/lib/python"$PYTHON_VERSION"/site-packages/xbmc


	mkdir -p $INSTALL/usr/share/XBMC/system/
	mkdir -p $INSTALL/usr/bin/
	mkdir -p $INSTALL/usr/share/XBMC/tools/

	cp $PKG_DIR/config/guisettings.xml $INSTALL/usr/share/XBMC/system/
	cp $PKG_DIR/config/guisettings.xml $INSTALL/usr/share/XBMC/
	cp $PKG_DIR/config/advancedsettings.xml $INSTALL/usr/share/XBMC/system/
	cp $PKG_DIR/config/advancedsettings.xml $INSTALL/usr/share/XBMC/


}

post_install() {
# link default.target to plexht.target
  ln -sf plexht.target $INSTALL/usr/lib/systemd/system/default.target

# for compatibility
  ln -sf plexht.target $INSTALL/usr/lib/systemd/system/kodi.target
  ln -sf plexht.service $INSTALL/usr/lib/systemd/system/kodi.service
  ln -sf plexht.target $INSTALL/usr/lib/systemd/system/xbmc.target
  ln -sf plexht.service $INSTALL/usr/lib/systemd/system/xbmc.service

# enable default services
  enable_service plexht-autostart.service
  enable_service plexht-cleanlogs.service
  enable_service plexht-hacks.service
  enable_service plexht-sources.service
  enable_service plexht-halt.service
  enable_service plexht-poweroff.service
  enable_service plexht-reboot.service
  enable_service plexht-waitonnetwork.service
  enable_service plexht.service
  enable_service plexht-lirc-suspend.service
}
