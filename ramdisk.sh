#!/bin/bash
#reference: http://www.cocoachina.com/ios/20170425/19116.html
#记得添加执行权限：chmod +x ramdisk.sh
#并且可能需要使用Sudo执行

RAMDISK=ramdisk
SIZE=2048         #size in MB for ramdisk.
diskutil erasevolume HFS+ $RAMDISK \
     `hdiutil attach -nomount ram://$[SIZE*2048]`
