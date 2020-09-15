#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
UDP2RAW_URL=https://soft.huayizhiyun.com/network/udptools/udp2raw/udp2raw_20200818.tar.gz
UDPSPEEDER_URL=https://soft.huayizhiyun.com/network/udptools/udpspeeder/speederv2_20200818.tar.gz

#判断系统和决定BIN名
if [[ `getconf WORD_BIT` = '32' && `getconf LONG_BIT` = '64' ]] ; then
    Is_64bit='y'
    UDP2RAW_BIN='udp2raw_amd64'
    UDPSPEEDER_BIN='speederv2_amd64'
  else
    Is_64bit='n'
    UDP2RAW_BIN='udp2raw_x86'
    UDPSPEEDER_BIN='speederv2_x86'
fi
if uname -m | grep -Eqi "arm|aarch64"; then
    Is_ARM='y'
    UDP2RAW_BIN='udp2raw_arm'
    UDPSPEEDER_BIN='speederv2_arm'
fi

#安装程序
Get_udp2raw()
{
#下载并提取相关文件
if [ ! -d "/usr/local/udptools" ]; then
  mkdir /usr/local/udptools
fi
if [ ! -d "/usr/local/udptools/bin" ]; then
  mkdir /usr/local/udptools/bin
fi
if [ ! -d "/usr/local/udptools/src" ]; then
  mkdir /usr/local/udptools/src
fi
cd /usr/local/udptools/src

if [ ! -f "/usr/local/udptools/src/$UDP2RAW_BIN" ]; then
    if [ ! -f "/usr/local/udptools/src/udp2raw.tar.gz" ]; then
      wget -O udp2raw.tar.gz $UDP2RAW_URL
    fi
    tar -zxvf udp2raw.tar.gz
fi
if [ ! -f "/usr/local/udptools/src/$UDP2RAW_BIN" ]; then
    echo "下载udp2raw失败;"
    exit
fi
cp /usr/local/udptools/src/$UDP2RAW_BIN /usr/local/udptools/bin/udp2raw
}

Get_udpspeeder()
{
#下载并提取相关文件
if [ ! -d "/usr/local/udptools" ]; then
  mkdir /usr/local/udptools
fi
if [ ! -d "/usr/local/udptools/bin" ]; then
  mkdir /usr/local/udptools/bin
fi
if [ ! -d "/usr/local/udptools/src" ]; then
  mkdir /usr/local/udptools/src
fi
cd /usr/local/udptools/src
if [ ! -f "/usr/local/udptools/src/$UDPSPEEDER_BIN" ]; then
		if [ ! -f "/usr/local/udptools/src/udpspeeder.tar.gz" ]; then
		  wget -O udpspeeder.tar.gz $UDPSPEEDER_URL
		fi
		tar -zxvf udpspeeder.tar.gz
fi
if [ ! -f "/usr/local/udptools/src/$UDPSPEEDER_BIN" ]; then
  echo "下载udpspeeder失败;"
  exit
fi
cp /usr/local/udptools/src/$UDPSPEEDER_BIN /usr/local/udptools/bin/udpspeeder
}

if [ ! -f "/usr/local/udptools/bin/udp2raw" ]; then
    Get_udp2raw
fi 
if [ ! -f "/usr/local/udptools/bin/udpspeeder" ]; then
    Get_udpspeeder
fi 
if [ ! -d "/usr/local/udptools/pid" ]; then
  mkdir /usr/local/udptools/pid
fi
if [ ! -d "/usr/local/udptools/log" ]; then
  mkdir /usr/local/udptools/log
fi
if [ ! -d "/usr/local/udptools/conf" ]; then
  mkdir /usr/local/udptools/conf
fi

echo "安装完成,请使用udptools脚本添加服务"
echo "Udp2Raw BIN: /usr/local/udptools/bin/udp2raw"
echo "UdpSpeeder BIN:/usr/local/udptools/bin/udpspeeder"