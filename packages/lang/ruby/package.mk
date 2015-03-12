PKG_NAME="ruby"
PKG_VERSION="2.2.0"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://www.ruby-lang.org"
PKG_URL="http://cache.ruby-lang.org/pub/ruby/2.2/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain ruby:host"
PKG_BUILD_DEPENDS_TARGET="ruby:host"
PKG_PRIORITY="optional"
PKG_SECTION="system"
PKG_SHORTDESC="Ruby Programming language"
PKG_LONGDESC="Ruby programming language"

PKG_IS_ADDON="no"
PKG_AUTORECONF="yes"

PKG_CONFIGURE_OPTS_HOST="--without-gmp --disable-install-rdoc"
PKG_CONFIGURE_OPTS_TARGET="--disable-install-rdoc"

pre_configure_host() {
  export OPT="$HOST_CFLAGS"
}

post_makeinstall_target() {
  rm -rf $INSTALL/*
}
