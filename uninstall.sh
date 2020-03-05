#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

echo "杀掉进程"
killall udp2raw
killall udpspeeder
echo "删除所有udptools文件"
rm -rf /usr/local/udptools
echo "删除相关服务"
#判断服务模式
if pgrep systemd-journal; then
    find /usr/lib/systemd/system/ -name "udp2raw*.service" | xargs -0 rm
    find /usr/lib/systemd/system/ -name "udpspeeder*.service" | xargs -0 rm
  else
    find /etc/init.d/ -name "udp2raw*" | xargs -0 rm
    find /etc/init.d/ -name "udpspeeder*" | xargs -0 rm
fi