#!/bin/sh

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

[ -z "$BOOT_ROOT" ] && BOOT_ROOT="/flash"
[ -z "$SYSTEM_ROOT" ] && SYSTEM_ROOT=""

# mount $BOOT_ROOT r/w
  mount -o remount,rw $BOOT_ROOT

# remove cpu freq from config if on RPi3
  REVISION="`cat /proc/cpuinfo | grep 'Revision' | awk '{print $3}' | sed 's/^1000//'`"
  if [[ "$REVISION" != "${REVISION/a02082/}" ]]; then 
    if [ "`cat $BOOT_ROOT/config.txt|grep "^arm_freq=1000"|wc -l`" != 0 ]; then
      # mount $BOOT_ROOT r/w
      mount -o remount,rw $BOOT_ROOT
      sed -e "/^arm_freq=.*/d" -i $BOOT_ROOT/config.txt
      # mount $BOOT_ROOT r/o
      sync
      mount -o remount,ro $BOOT_ROOT
      # reboot post config change
      reboot 
    fi
  else
    if [ "`cat $BOOT_ROOT/config.txt|grep "^arm_freq=1000"|wc -l`" == 0 ]; then
      # mount $BOOT_ROOT r/w
      mount -o remount,rw $BOOT_ROOT
      sed -i '/core_freq=.*/i \
arm_freq=1000' -i $BOOT_ROOT/config.txt
      # mount $BOOT_ROOT r/o
      sync
      mount -o remount,ro $BOOT_ROOT
      # reboot post config change
      reboot 
    fi
  fi
