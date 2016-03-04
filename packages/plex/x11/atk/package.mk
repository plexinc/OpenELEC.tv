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

PKG_NAME="atk"
PKG_VERSION="2.18.0"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="http://ftp.gnome.org"
PKG_URL="http://ftp.acc.umu.se/pub/gnome/sources/$PKG_NAME/2.18/$PKG_NAME-$PKG_VERSION.tar.xz"
PKG_DEPENDS_TARGET="toolchain glib:host"
PKG_PRIORITY="optional"
PKG_SECTION="x11"
PKG_SHORTDESC="ATK - Accessibility Toolkit"
PKG_LONGDESC="ATK - Accessibility Toolkit"

PKG_IS_ADDON="no"
PKG_AUTORECONF="yes"
