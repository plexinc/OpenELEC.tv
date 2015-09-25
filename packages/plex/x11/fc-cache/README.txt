To build the pre-cache fc-cache use the following from a 64 bits ubuntu build host

- ARM
* Apply fc-cache-arm.patch
* PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig ./configure --build=i686-pc-linux-gnu "CFLAGS=-m32 -malign-double" "CXXFLAGS=-m32 -malign-double" "LDFLAGS=-m32" --with-expat-lib=/usr/lib/i386-linux-gnu/ --with-default-fonts=/usr/share/fonts --without-add-fonts --disable-dependency-tracking --disable-docs --enable-static --disable-shared --with-cache-dir=/usr/share/plexmediaplayer/fc-cache --disable-largefile --with-arch=arm
* make -j8

- Intel (64 bits)
* ./configure  --with-default-fonts=/usr/share/fonts --without-add-fonts --disable-dependency-tracking --disable-docs --enable-static --disable-shared --with-cache-dir=/usr/share/plexmediaplayer/fc-cache --with-arch=x86_64
* make -j8

