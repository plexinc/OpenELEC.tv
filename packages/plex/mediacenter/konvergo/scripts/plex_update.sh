#!/bin/sh

UPDATE_DIR="/storage/.update"
if [ "`ls -1 $UPDATE_DIR | wc -l`" = "0" ]; then
  exit 0
fi

UPDATE_TAR="`ls -1tr /storage/.update/*.tar |tail -1`"
MD5_FAILED=0

if [ "`tar tf ${UPDATE_TAR} | grep -c plex_mini_update`" -gt 0 ]; then
  # Found new plex archive. extracting...
  mkdir -p $UPDATE_DIR/.tmp &>/dev/null
  tar -xf "$UPDATE_TAR" -C $UPDATE_DIR/.tmp &>/dev/null
  while read sum file
  do
    prev_sum=$(md5sum $UPDATE_DIR/.tmp/$file | awk '{print $1}')
    if [ "$sum" != "$prev_sum" ]; then
      export MD5_FAILED=1
    fi
  done < $UPDATE_DIR/.tmp/md5.txt
  if [ "$MD5_FAILED" -eq "0" ] ; then
  # Updating plex to latest version..
    rm -rf /storage/.plex_update
    mkdir /storage/.plex_update
    mv $UPDATE_DIR/.tmp/* /storage/.plex_update/.
    rm -rf $UPDATE_DIR/[0-9a-zA-Z]* $UPDATE_DIR/.tmp &>/dev/null
  else
    rm -rf $UPDATE_DIR/[0-9a-zA-Z]* $UPDATE_DIR/.tmp &>/dev/null
    # md5 check failed. Resuming normal startup..
    sync
  fi
fi
