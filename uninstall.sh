#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

echo "杀掉进程"
if ps aux | grep -e "udp2raw" | grep -q -v grep; then
  killall udp2raw
fi
if ps aux | grep -e "udpspeeder" | grep -q -v grep; then
  killall udpspeeder
fi
echo "删除所有udptools文件"
rm -rf /usr/local/udptools
echo "删除相关服务"
#判断服务模式
if pgrep systemd-journal > /dev/null; then
    if ls /usr/lib/systemd/system/ | grep -q -e "udp2raw*"; then
      find /etc/systemd/system/ -name "udp2raw*" | xargs rm
      find /usr/lib/systemd/system/ -name "udp2raw*" | xargs rm
    fi
    if ls /usr/lib/systemd/system/ | grep -q -e "udpspeeder*"; then
      find /etc/systemd/system/ -name "udpspeeder*" | xargs rm
      find /usr/lib/systemd/system/ -name "udpspeeder*" | xargs rm
    fi
  else
    if ls /etc/init.d/ | grep -q -e "udp2raw*"; then
      find /etc/init.d/ -name "udp2raw*" | xargs rm
    fi
    if ls /etc/init.d/ | grep -q -e "udpspeeder*"; then
      find /etc/init.d/ -name "udpspeeder*" | xargs rm
    fi
fi
echo "卸载完成"