#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
UDP2RAW_URL=https://soft.huayizhiyun.com/network/udptools/udp2raw/udp2raw_20200818.tar.gz
UDPSPEEDER_URL=https://soft.huayizhiyun.com/network/udptools/udpspeeder/speederv2_20200818.tar.gz

#ɾ���ɰ汾
rm -rf /usr/local/udptools/src/*

#�ж�ϵͳ�;���BIN��
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

#��װ����
Get_udp2raw()
{
#���ز���ȡ����ļ�
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
    echo "����udp2rawʧ��;"
    exit
fi
#���ݾɰ汾������
rm -f /usr/local/udptools/bin/udp2raw.bak
mv /usr/local/udptools/bin/udp2raw /usr/local/udptools/bin/udp2raw.bak
cp /usr/local/udptools/src/$UDP2RAW_BIN /usr/local/udptools/bin/udp2raw
}

Get_udpspeeder()
{
#���ز���ȡ����ļ�
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
  echo "����udpspeederʧ��;"
  exit
fi
#���ݾɰ汾������
rm -f /usr/local/udptools/bin/udpspeeder.bak
mv /usr/local/udptools/bin/udpspeeder /usr/local/udptools/bin/udpspeeder.bak
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

echo "�������,��ʹ��udptools�ű���ӷ���"
echo "Udp2Raw BIN: /usr/local/udptools/bin/udp2raw"
echo "UdpSpeeder BIN:/usr/local/udptools/bin/udpspeeder"