################################################################################
#      This file is part of OpenELEC - http://www.openelec.tv
#      Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
#
#  This Program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2, or (at your option)
#  any later version.
#
#  This Program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with OpenELEC.tv; see the file COPYING.  If not, write to
#  the Free Software Foundation, 51 Franklin Street, Suite 500, Boston, MA 02110, USA.
#  http://www.gnu.org/copyleft/gpl.html
################################################################################

PKG_NAME="plexht"
PKG_VERSION="0.9.10.1"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://www.plexapp.com"
PKG_URL="https://github.com/plexinc/plex-home-theater-public/archive/pht-frodo.zip"
PKG_DEPENDS="Python zlib bzip2 systemd ffmpeg libass curl rtmpdump fontconfig freetype libmad libogg libmodplug faad2 flac libmpeg2 taglib service.openelec.settings"
PKG_BUILD_DEPENDS_TARGET="toolchain boost Python zlib bzip2 systemd lzo pcre swig ffmpeg libass enca curl libmicrohttpd libssh rtmpdump fontconfig fribidi tinyxml libjpeg-turbo libpng tiff freetype jasper libmad libsamplerate libogg libcdio libmodplug faad2 fribidi flac flac++ libmpeg2 taglib yajl sqlite libshairport SDL_image SDL_mixer avahi glew libplist libcec lame"
PKG_PRIORITY="optional"
PKG_SECTION="plex"
PKG_SHORTDESC="plexht: Plex Home Theater"
PKG_LONGDESC="Plex Home Theater, is blah blah blah blah"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

# for dbus support
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET dbus"
  PKG_DEPENDS="$PKG_DEPENDS dbus"

# needed for hosttools (Texturepacker)
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET lzo:host SDL-host SDL_image-host"

# some python stuff needed for various addons
  PKG_DEPENDS="$PKG_DEPENDS Imaging"
  PKG_DEPENDS="$PKG_DEPENDS simplejson"
  PKG_DEPENDS="$PKG_DEPENDS pycrypto"

# various PVR clients
#  PKG_DEPENDS="$PKG_DEPENDS xbmc-pvr-addons"
#  PKG_DEPENDS="$PKG_DEPENDS xbmc-addon-xvdr"

if [ "$DISPLAYSERVER" = "xorg-server" ]; then
# for libX11 support
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET libX11 libXext"
  PKG_DEPENDS="$PKG_DEPENDS libX11 libXext"
# for libXrandr support
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET libXrandr"
  PKG_DEPENDS="$PKG_DEPENDS libXrandr"
  XBMC_XORG="--enable-x11 --enable-xrandr"
else
  XBMC_XORG="--disable-x11 --disable-xrandr"
fi

if [ "$OPENGL" = "Mesa" ]; then
# for OpenGL (GLX) support
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET Mesa glu glew"
  PKG_DEPENDS="$PKG_DEPENDS Mesa glu"
  XBMC_OPENGL="--enable-gl"
else
  XBMC_OPENGL="--disable-gl"
fi

if [ "$OPENGLES_SUPPORT" = yes ]; then
# for OpenGL-ES support
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET $OPENGLES"
  PKG_DEPENDS="$PKG_DEPENDS $OPENGLES"
  XBMC_OPENGLES="--enable-gles"
else
  XBMC_OPENGLES="--disable-gles"
fi

if [ "$SDL_SUPPORT" = yes ]; then
# for SDL support
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET SDL SDL_image"
  PKG_DEPENDS="$PKG_DEPENDS SDL SDL_image"
  XBMC_SDL="--enable-sdl"
else
  XBMC_SDL="--disable-sdl"
fi

if [ "$ALSA_SUPPORT" = yes ]; then
# for ALSA support
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET alsa-lib"
  PKG_DEPENDS="$PKG_DEPENDS alsa-lib"
  XBMC_ALSA="--enable-alsa"
else
  XBMC_ALSA="--disable-alsa"
fi

if [ "$CEC_SUPPORT" = yes ]; then
# for CEC support
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET libcec"
  PKG_DEPENDS="$PKG_DEPENDS libcec"
  XBMC_CEC="--enable-libcec"
else
  XBMC_CEC="--disable-libcec"
fi

if [ "$XBMC_SCR_RSXS" = yes ]; then
# for RSXS Screensaver support
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET libXt libXmu"
  XBMC_RSXS="--enable-rsxs"
# fix build of RSXS Screensaver support if not using libiconv
  export jm_cv_func_gettimeofday_clobber=no
else
  XBMC_RSXS="--disable-rsxs"
fi

if [ "$XBMC_VIS_PROJECTM" = yes ]; then
# for ProjectM Visualisation support
  XBMC_PROJECTM="--enable-projectm"
else
  XBMC_PROJECTM="--disable-projectm"
fi

if [ "$XBMC_VIS_GOOM" = yes ]; then
# for GOOM Visualisation support
  XBMC_GOOM="--enable-goom"
else
  XBMC_GOOM="--disable-goom"
fi

if [ "$JOYSTICK_SUPPORT" = yes ]; then
# for Joystick support
  XBMC_JOYSTICK="--enable-joystick"
else
  XBMC_JOYSTICK="--disable-joystick"
fi

if [ "$OPTICAL_DRIVE_SUPPORT" = yes ]; then
  XBMC_OPTICAL="--enable-optical-drive"
else
  XBMC_OPTICAL="--disable-optical-drive"
fi

if [ "$NONFREE_SUPPORT" = yes ]; then
# for non-free support
  XBMC_NONFREE="--enable-non-free"
else
  XBMC_NONFREE="--disable-non-free"
fi

if [ "$DVDCSS_SUPPORT" = yes ]; then
  XBMC_DVDCSS="--enable-dvdcss"
else
  XBMC_DVDCSS="--disable-dvdcss"
fi

if [ "$FAAC_SUPPORT" = yes ]; then
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET faac"
  PKG_DEPENDS="$PKG_DEPENDS faac"
fi

if [ "$ENCODER_LAME" = yes ]; then
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET lame"
  PKG_DEPENDS="$PKG_DEPENDS lame"
  XBMC_LAMEENC="--enable-libmp3lame"
else
  XBMC_LAMEENC="--disable-libmp3lame"
fi

if [ "$ENCODER_VORBIS" = yes ]; then
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET libvorbis"
  PKG_DEPENDS="$PKG_DEPENDS libvorbis"
  XBMC_VORBISENC="--enable-libvorbisenc"
else
  XBMC_VORBISENC="--disable-libvorbisenc"
fi

if [ "$BLURAY_SUPPORT" = yes ]; then
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET libbluray"
  PKG_DEPENDS="$PKG_DEPENDS libbluray"
  XBMC_BLURAY="--enable-libbluray"
else
  XBMC_BLURAY="--disable-libbluray"
fi

if [ "$AVAHI_DAEMON" = yes ]; then
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET avahi"
  PKG_DEPENDS="$PKG_DEPENDS avahi"
  XBMC_AVAHI="--enable-avahi"
else
  XBMC_AVAHI="--disable-avahi"
fi

if [ "$MYSQL_SUPPORT" = yes ]; then
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET mysql"
  PKG_DEPENDS="$PKG_DEPENDS mysql"
  XBMC_MYSQL="--enable-mysql"
else
  XBMC_MYSQL="--disable-mysql"
fi

if [ "$AIRPLAY_SUPPORT" = yes ]; then
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET libplist"
  PKG_DEPENDS="$PKG_DEPENDS libplist"
  XBMC_AIRPLAY="--enable-airplay"
else
  XBMC_AIRPLAY="--disable-airplay"
fi

if [ "$AIRTUNES_SUPPORT" = yes ]; then
  if [ "$XBMC" = master ]; then
    PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET libshairplay"
    PKG_DEPENDS="$PKG_DEPENDS libshairplay"
  else
    PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET libshairport"
    PKG_DEPENDS="$PKG_DEPENDS libshairport"
  fi
  XBMC_AIRTUNES="--enable-airtunes"
else
  XBMC_AIRTUNES="--disable-airtunes"
fi

if [ "$NFS_SUPPORT" = yes ]; then
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET libnfs"
  PKG_DEPENDS="$PKG_DEPENDS libnfs"
  XBMC_NFS="--enable-nfs"
else
  XBMC_NFS="--disable-nfs"
fi

if [ "$AFP_SUPPORT" = yes ]; then
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET afpfs-ng"
  PKG_DEPENDS="$PKG_DEPENDS afpfs-ng"
  XBMC_AFP="--enable-afpclient"
else
  XBMC_AFP="--disable-afpclient"
fi

if [ "$SAMBA_SUPPORT" = yes ]; then
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET samba"
  PKG_DEPENDS="$PKG_DEPENDS samba"
  XBMC_SAMBA="--enable-samba"
  XBMC_LIBS="$XBMC_LIBS -ltalloc -ltdb -ltevent -lwbclient"
else
  XBMC_SAMBA="--disable-samba"
fi

if [ "$WEBSERVER" = yes ]; then
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET libmicrohttpd"
  XBMC_WEBSERVER="--enable-webserver"
else
  XBMC_WEBSERVER="--disable-webserver"
fi

if [ "$UPNP_SUPPORT" = yes ]; then
  XBMC_UPNP="--enable-upnp"
else
  XBMC_UPNP="--disable-upnp"
fi

if [ "$SSHLIB_SUPPORT" = yes ]; then
  XBMC_SSH="--enable-ssh"
else
  XBMC_SSH="--disable-ssh"
fi

if [ ! "$XBMCPLAYER_DRIVER" = default ]; then
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET $XBMCPLAYER_DRIVER"
  PKG_DEPENDS="$PKG_DEPENDS $XBMCPLAYER_DRIVER"

  if [ "$XBMCPLAYER_DRIVER" = bcm2835-driver ]; then
    XBMC_OPENMAX="--enable-openmax"
    XBMC_PLAYER="--enable-player=omxplayer"
    XBMC_CODEC="--with-platform=raspberry-pi"
    BCM2835_INCLUDES="-I$SYSROOT_PREFIX/usr/include/interface/vcos/pthreads/ \
                      -I$SYSROOT_PREFIX/usr/include/interface/vmcs_host/linux"
    XBMC_CFLAGS="$XBMC_CFLAGS $BCM2835_INCLUDES"
    XBMC_CXXFLAGS="$XBMC_CXXFLAGS $BCM2835_INCLUDES"
  elif [ "$XBMCPLAYER_DRIVER" = "marvell-libgfx" ]; then
    PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET marvell-ipp"
    PKG_DEPENDS="$PKG_DEPENDS marvell-ipp"
    XBMC_OPENMAX="--disable-openmax"
    XBMC_PLAYER="--with-platform=marvell-dove"
    XBMC_CODEC=""
  elif [ "$XBMCPLAYER_DRIVER" = "libamlplayer-m1" -o "$XBMCPLAYER_DRIVER" = "libamlplayer-m3" ]; then
    XBMC_OPENMAX="--disable-openmax"
    XBMC_PLAYER="--enable-player=amlplayer"
    XBMC_CODEC="--enable-codec=amcodec"
    AMLPLAYER_INCLUDES="-I$SYSROOT_PREFIX/usr/include/amlplayer"
    XBMC_CFLAGS="$XBMC_CFLAGS $AMLPLAYER_INCLUDES"
    XBMC_CXXFLAGS="$XBMC_CXXFLAGS $AMLPLAYER_INCLUDES"

  else
    XBMC_OPENMAX="--disable-openmax"
  fi
fi

if [ "$VDPAU" = yes ]; then
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET libvdpau"
  PKG_DEPENDS="$PKG_DEPENDS libvdpau"
  XBMC_VDPAU="--enable-vdpau"
else
  XBMC_VDPAU="--disable-vdpau"
fi

if [ "$VAAPI" = yes ]; then
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET libva"
  PKG_DEPENDS="$PKG_DEPENDS libva"
  XBMC_VAAPI="--enable-vaapi"
else
  XBMC_VAAPI="--disable-vaapi"
fi

if [ "$XVBA" = yes ]; then
  get_graphicdrivers
  for drv in $GRAPHIC_DRIVERS; do
    if [ "$drv" = "fglrx" ]; then
      PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET xf86-video-fglrx"
    elif [ "$drv" = "fglrx-legacy" ]; then
      PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET xf86-video-fglrx-legacy"
    fi
  done
  XBMC_XVBA="--enable-xvba"
else
  XBMC_XVBA="--disable-xvba"
fi

if [ "$CRYSTALHD" = yes ]; then
  PKG_BUILD_DEPENDS_TARGET="$PKG_BUILD_DEPENDS_TARGET crystalhd"
  PKG_DEPENDS="$PKG_DEPENDS crystalhd"
  XBMC_CRYSTALHD="--enable-crystalhd"
else
  XBMC_CRYSTALHD="--disable-crystalhd"
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


pre_configure_target() {
# Configure Plex
# dont use some optimizations because of build problems
  LDFLAGS=`echo $LDFLAGS | sed -e "s|-Wl,--as-needed||"`
# dont build parallel
  MAKEFLAGS=-j1

# strip compiler optimization
  strip_lto

# set python variables
  export PYTHON_VERSION="2.7"
  export PYTHON_CPPFLAGS="-I$SYSROOT_PREFIX/usr/include/python$PYTHON_VERSION"
  export PYTHON_LDFLAGS="-L$SYSROOT_PREFIX/usr/lib/python$PYTHON_VERSION -lpython$PYTHON_VERSION"
  export PYTHON_SITE_PKG="$SYSROOT_PREFIX/usr/lib/python$PYTHON_VERSION/site-packages"
  export ac_python_version="$PYTHON_VERSION"

# configure the build
export PKG_CONFIG_PATH=$SYSROOT_PREFIX/usr/lib/pkgconfig

cd $ROOT/$BUILD/$PKG_NAME-$PKG_VERSION
[ ! -d config ] && mkdir config
cd config

cmake -DCMAKE_LIBRARY_PATH="$SYSROOT_PREFIX/usr/lib" -DCMAKE_PREFIX_PATH="$SYSROOT_PREFIX" -DCMAKE_INCLUDE_PATH="$SYSROOT_PREFIX/usr/include" -DCMAKE_BUILD_TYPE=Debug -DENABLE_DVD_DRIVE=on -DCOMPRESS_TEXTURES=off -DCMAKE_INSTALL_PREFIX=$INSTALL/usr $ROOT/$BUILD/$PKG_NAME-$PKG_VERSION/.
}

pre_build_target() {
# Do nothing
MAKEFLAGS=-j1

}

make_target() {
# Build Plex
# dont use some optimizations because of build problems
  LDFLAGS=`echo $LDFLAGS | sed -e "s|-Wl,--as-needed||"`
# dont build parallel
  MAKEFLAGS=-j1

# strip compiler optimization
  strip_lto

# set python variables
  export PYTHON_VERSION="2.7"
  export PYTHON_CPPFLAGS="-I$SYSROOT_PREFIX/usr/include/python$PYTHON_VERSION"
  export PYTHON_LDFLAGS="-L$SYSROOT_PREFIX/usr/lib/python$PYTHON_VERSION -lpython$PYTHON_VERSION"
  export PYTHON_SITE_PKG="$SYSROOT_PREFIX/usr/lib/python$PYTHON_VERSION/site-packages"
  export ac_python_version="$PYTHON_VERSION"

# configure the build
export PKG_CONFIG_PATH=$SYSROOT_PREFIX/usr/lib/pkgconfig
cd $ROOT/$BUILD/$PKG_NAME-$PKG_VERSION/config
make -j1
}

post_makeinstall_target() {
  mkdir -p $INSTALL/usr/bin
    cp $PKG_DIR/scripts/cputemp $INSTALL/usr/bin
    cp $PKG_DIR/scripts/gputemp $INSTALL/usr/bin
    cp $PKG_DIR/scripts/setwakeup.sh $INSTALL/usr/bin

    rm -rf $INSTALL/usr/bin/xbmc
    rm -rf $INSTALL/usr/bin/xbmc-standalone

  if [ ! "$DISPLAYSERVER" = "xorg-server" ]; then
    rm -rf $INSTALL/usr/lib/xbmc/xbmc-xrandr
  fi

  if [ ! "$XBMC_SCR_RSXS" = yes ]; then
    rm -rf $INSTALL/usr/share/xbmc/addons/screensaver.rsxs.*
  fi

  if [ ! "$XBMC_VIS_PROJECTM" = yes ]; then
    rm -rf $INSTALL/usr/share/xbmc/addons/visualization.projectm
  fi

  rm -rf $INSTALL/usr/share/applications
  rm -rf $INSTALL/usr/share/icons
  rm -rf $INSTALL/usr/share/xbmc/addons/repository.pvr-*
  rm -rf $INSTALL/usr/share/xbmc/addons/script.module.pysqlite
  rm -rf $INSTALL/usr/share/xbmc/addons/script.module.simplejson
  rm -rf $INSTALL/usr/share/xbmc/addons/visualization.dxspectrum
  rm -rf $INSTALL/usr/share/xbmc/addons/visualization.itunes
  rm -rf $INSTALL/usr/share/xbmc/addons/visualization.milkdrop
  rm -rf $INSTALL/usr/share/xsessions

  mkdir -p $INSTALL/usr/share/xbmc/addons
    cp -R $PKG_DIR/config/os.openelec.tv $INSTALL/usr/share/xbmc/addons
    $SED "s|@OS_VERSION@|$OS_VERSION|g" -i $INSTALL/usr/share/xbmc/addons/os.openelec.tv/addon.xml
    cp -R $PKG_DIR/config/repository.openelec.tv $INSTALL/usr/share/xbmc/addons
    $SED "s|@ADDON_URL@|$ADDON_URL|g" -i $INSTALL/usr/share/xbmc/addons/repository.openelec.tv/addon.xml

# install powermanagement hooks
  mkdir -p $INSTALL/etc/pm/sleep.d
    cp $PKG_DIR/sleep.d/* $INSTALL/etc/pm/sleep.d

# install project specific configs
  mkdir -p $INSTALL/usr/share/xbmc/config
    if [ -f $PROJECT_DIR/$PROJECT/xbmc/guisettings.xml ]; then
      cp -R $PROJECT_DIR/$PROJECT/xbmc/guisettings.xml $INSTALL/usr/share/xbmc/config
    fi

    if [ -f $PROJECT_DIR/$PROJECT/xbmc/sources.xml ]; then
      cp -R $PROJECT_DIR/$PROJECT/xbmc/sources.xml $INSTALL/usr/share/xbmc/config
    fi

  mkdir -p $INSTALL/usr/share/xbmc/system/
    if [ -f $PROJECT_DIR/$PROJECT/xbmc/advancedsettings.xml ]; then
      cp $PROJECT_DIR/$PROJECT/xbmc/advancedsettings.xml $INSTALL/usr/share/xbmc/system/
    else
      cp $PKG_DIR/config/advancedsettings.xml $INSTALL/usr/share/xbmc/system/
    fi

  if [ "$XBMC" = master ]; then
    mkdir -p $INSTALL/usr/share/xbmc/system/settings
      if [ -f $PROJECT_DIR/$PROJECT/xbmc/appliance.xml ]; then
        cp $PROJECT_DIR/$PROJECT/xbmc/appliance.xml $INSTALL/usr/share/xbmc/system/settings
      else
        cp $PKG_DIR/config/appliance.xml $INSTALL/usr/share/xbmc/system/settings
      fi
  fi

  if [ "$XBMC_EXTRA_FONTS" = yes ]; then
    mkdir -p $INSTALL/usr/share/xbmc/media/Fonts
      cp $PKG_DIR/fonts/*.ttf $INSTALL/usr/share/xbmc/media/Fonts
  fi
}

