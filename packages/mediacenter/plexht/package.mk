#!/bin/bash -ax
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
  if [ "$PHT_HEAD" = "HEAD" ]; then
    PKG_VERSION=HEAD
  else
    PKG_VERSION=PUBLIC
  fi
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

if [ "$PROJECT" = "Generic-PHT" ] || [ "$PROJECT" = "Generic-PHT-Pioneer" ] || [ "$PROJECT" = "Generic" ]; then
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET libva-intel-driver"
  PKG_DEPENDS="$PKG_DEPENDS libva-intel-driver"
fi

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
        patch $BUILD/$PKG_NAME-$PKG_VERSION/CMakeLists.txt < $PKG_DIR/patches/cmakelists.patch
        patch $BUILD/$PKG_NAME-$PKG_VERSION/plex/CMakeModules/PlatformConfigLINUX.cmake < $PKG_DIR/patches/platformconfig.patch
        patch $BUILD/$PKG_NAME-$PKG_VERSION/addons/skin.plex/720p/Font.xml < $PKG_DIR/patches/fontfix.patch
        patch $BUILD/$PKG_NAME-$PKG_VERSION/addons/skin.plex/720p/LeftSideMenu.xml < $PKG_DIR/patches/skinpht.patch
#        rm -f $BUILD/${PKG_NAME}-${PKG_VERSION}/xbmc/cores/dvdplayer/DVDCodecs/Audio/DVDAudioCodecPassthroughFFmpeg.h
#        rm -f $BUILD/${PKG_NAME}-${PKG_VERSION}/xbmc/cores/dvdplayer/DVDCodecs/Audio/DVDAudioCodecPassthroughFFmpeg.cpp
}

configure_target() {
  # Configure Plex
  # dont use some optimizations because of build problems
  LDFLAGS=`echo $LDFLAGS | sed -e "s|-Wl,--as-needed||"`
  # dont build parallel
  MAKEFLAGS=-j1

  # strip compiler optimization
  strip_lto

  # configure the build
  export PKG_CONFIG_PATH=$SYSROOT_PREFIX/usr/lib/pkgconfig
  export PKG_BUILD="$ROOT/$BUILD/$PKG_NAME-$PKG_VERSION"

  cd $ROOT/$BUILD/$PKG_NAME-$PKG_VERSION
  [ ! -d config ] && mkdir config
  cd config

  export PYTHON_EXEC="$SYSROOT_PREFIX/usr/bin/python2.7"
  cmake -DCMAKE_TOOLCHAIN_FILE=$CMAKE_CONF \
        -DENABLE_PYTHON=ON \
        -DEXTERNAL_PYTHON_HOME="$SYSROOT_PREFIX/usr" \
        -DPYTHON_EXEC="$PYTHON_EXEC" \
        -DSWIG_EXECUTABLE=`which swig` \
        -DSWIG_DIR="$ROOT/$BUILD/toolchain" \
        -DCMAKE_PREFIX_PATH="$SYSROOT_PREFIX" \
        -DCMAKE_LIBRARY_PATH="$SYSROOT_PREFIX/usr/lib" \
        -DCMAKE_INCLUDE_PATH="$SYSROOT_PREFIX/usr/include;$SYSROOT_PREFIX/usr/include/python2.7;$SYSROOT_PREFIX/usr/lib/dbus-1.0/include" \
        -DFREETYPE_LIBRARY="$SYSROOT_PREFIX/usr/lib/libfreetype.so" -DFREETYPE_INCLUDE_DIRS="$SYSROOT_PREFIX/usr/include/freetype2" \
        -DCOMPRESS_TEXTURES=ON \
        -DTEXTUREPACKERPATH=$PKG_DIR/config/TexturePacker \
        -DENABLE_DUMP_SYMBOLS=OFF \
        -DENABLE_AUTOUPDATE=OFF \
        -DUSE_INTERNAL_FFMPEG=OFF \
        -DOPENELEC=ON \
        -DCMAKE_INSTALL_PREFIX=/usr/lib/plexht \
        -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE \
        $PKG_BUILD
}

make_target() {
  # Build Plex
  # dont use some optimizations because of build problems
  LDFLAGS=`echo $LDFLAGS | sed -e "s|-Wl,--as-needed||"`
  # strip compiler optimization
  strip_lto

  # set python variables
  export PYTHON_VERSION="2.7"
  export PYTHON_CPPFLAGS="-I$SYSROOT_PREFIX/usr/include/python$PYTHON_VERSION"
  export PYTHON_LDFLAGS="-L$SYSROOT_PREFIX/usr/lib/python$PYTHON_VERSION -lpython$PYTHON_VERSION"
  export PYTHON_SITE_PKG="$SYSROOT_PREFIX/usr/lib/python$PYTHON_VERSION/site-packages"
  export ac_python_version="$PYTHON_VERSION"

  # Make the build
  export PKG_CONFIG_PATH=$SYSROOT_PREFIX/usr/lib/pkgconfig
  cd $ROOT/$BUILD/$PKG_NAME-$PKG_VERSION/config
  export CPLUS_INCLUDE_PATH="$SYSROOT_PREFIX/usr/include/python$PYTHON_VERSION"
  export PYTHON_LIBDIR=`ls -d $SYSROOT_PREFIX/usr/lib/python*`
  make -j1


}

post_makeinstall_target() {

  rm -rf $INSTALL/usr/lib/plexht/bin/lib
  rm -rf $INSTALL/usr/lib/plexht/bin/include
  rm -rf $INSTALL/usr/lib/plexht/bin/*.so
  mv -f $INSTALL/usr/lib/plexht/bin/* $INSTALL/usr/lib/plexht/
  rm -rf $INSTALL/usr/lib/plexht/bin
  mkdir -p $INSTALL/usr/share/XBMC
  mv -f $INSTALL/usr/lib/plexht/share/XBMC/* $INSTALL/usr/share/XBMC/
  mkdir -p $INSTALL/usr/lib/plexht/addons

  mkdir -p $INSTALL/usr/lib/plexht
    cp $PKG_DIR/scripts/plexht-config $INSTALL/usr/lib/plexht
    cp $PKG_DIR/scripts/plexht-hacks $INSTALL/usr/lib/plexht
    cp $PKG_DIR/scripts/plexht-sources $INSTALL/usr/lib/plexht

  mkdir -p $INSTALL/usr/lib/openelec
    cp $PKG_DIR/scripts/systemd-addon-wrapper $INSTALL/usr/lib/openelec

  mkdir -p $INSTALL/usr/bin
    cp $PKG_DIR/scripts/cputemp $INSTALL/usr/bin
      ln -sf cputemp $INSTALL/usr/bin/gputemp
    cp $PKG_DIR/scripts/setwakeup.sh $INSTALL/usr/bin
    cp ../tools/EventClients/Clients/XBMC\ Send/xbmc-send.py $INSTALL/usr/bin/xbmc-send

  if [ ! "$KODI_SCR_RSXS" = yes ]; then
    rm -rf $INSTALL/usr/share/XBMC/addons/screensaver.rsxs.*
  fi

  if [ ! "$KODI_VIS_PROJECTM" = yes ]; then
    rm -rf $INSTALL/usr/share/XBMC/addons/visualization.projectm
  fi

  rm -rf $INSTALL/usr/share/applications
  rm -rf $INSTALL/usr/share/icons
  rm -rf $INSTALL/usr/share/XBMC/addons/service.xbmc.versioncheck
  rm -rf $INSTALL/usr/share/xsessions

  mkdir -p $INSTALL/usr/share/XBMC/addons
    cp -R $PKG_DIR/config/os.openelec.tv $INSTALL/usr/share/XBMC/addons
    $SED "s|@OS_VERSION@|$OS_VERSION|g" -i $INSTALL/usr/share/XBMC/addons/os.openelec.tv/addon.xml
	
  mkdir -p $INSTALL/usr/lib/python"$PYTHON_VERSION"/site-packages/xbmc
    cp -R ../tools/EventClients/lib/python/* $INSTALL/usr/lib/python"$PYTHON_VERSION"/site-packages/xbmc

# install powermanagement hooks
  mkdir -p $INSTALL/etc/pm/sleep.d
    cp $PKG_DIR/sleep.d/* $INSTALL/etc/pm/sleep.d

# install xorg configs
    if [ -f $PKG_DIR/config/xorg/intel-xorg.conf ]; then
      cp -R $PKG_DIR/config/xorg/intel-xorg.conf $INSTALL/usr/share/XBMC/config
    fi
    if [ -f $PKG_DIR/config/xorg/nvidia-xorg.conf ]; then
      cp -R $PKG_DIR/config/xorg/nvidia-xorg.conf $INSTALL/usr/share/XBMC/config
    fi

# Install autostart.sh script
    if [ -f $PKG_DIR/scripts/autostart.sh ]; then
      cp -R $PKG_DIR/scripts/autostart.sh $INSTALL/usr/share/XBMC/config ; chmod -x $INSTALL/usr/share/XBMC/config/autostart.sh
    fi

# install project specific configs
  mkdir -p $INSTALL/usr/share/XBMC/config
    if [ -f $PROJECT_DIR/$PROJECT/plexht/guisettings.xml ]; then
      cp -R $PROJECT_DIR/$PROJECT/plexht/guisettings.xml $INSTALL/usr/share/XBMC/config
    fi

    if [ -f $PROJECT_DIR/$PROJECT/plexht/sources.xml ]; then
      cp -R $PROJECT_DIR/$PROJECT/plexht/sources.xml $INSTALL/usr/share/XBMC/config
    fi

  mkdir -p $INSTALL/usr/share/XBMC/system/
    if [ -f $PROJECT_DIR/$PROJECT/plexht/advancedsettings.xml ]; then
      cp $PROJECT_DIR/$PROJECT/plexht/advancedsettings.xml $INSTALL/usr/share/XBMC/system/
    else
      cp $PKG_DIR/config/advancedsettings.xml $INSTALL/usr/share/XBMC/system/
    fi

  if [ "$KODI_EXTRA_FONTS" = yes ]; then
    mkdir -p $INSTALL/usr/share/XBMC/media/Fonts
      cp $PKG_DIR/fonts/*.ttf $INSTALL/usr/share/XBMC/media/Fonts
  fi
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
