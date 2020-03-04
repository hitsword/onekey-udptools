#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#判断系统
if [[ -e /etc/debian_version ]]; then
    OS=debian
    GROUPNAME=nogroup
    RCLOCAL='/etc/rc.local'
    IPTABLES=`dpkg --get-selections | grep iptables`
  elif [[ -e /etc/centos-release || -e /etc/redhat-release ]]; then
    OS=centos
    GROUPNAME=nobody
    RCLOCAL='/etc/rc.d/rc.local'
    IPTABLES=`rpm -qa |grep iptables`
  else
	  echo "只支持Debian\Ubuntu\CentOS系统"
	  exit
fi
#检查依赖IPTABLES
if [ "$IPTABLES" == '' ]; then
  if [[ "$OS" = 'debian' ]]; then
		apt-get update
		apt-get install iptables -y
  else
		yum install iptables -y
  fi
fi

#判断服务模式
if pgrep systemd-journal; then
    SYSTEMCTL=1
  else
    SYSTEMCTL=0
fi

echo
echo "Which mode to run this?"
echo "你想运行在什么模式?"
echo "   1) Client(Default) - 客户端(默认)"
echo "   2) Server - 服务端"
read -p "Run Mode(运行模式) [1-2]: " -e -i 1 RUNMODE
case $RUNMODE in
  1) 
    read -p "Udp2Raw Password(Udp2Raw密码): " PASSWD
      echo""
    read -p "Remote Udp2Raw IP(Udp2Raw远程IP): " RIP
      echo""
    while [[ ! "$RPORT" =~ [1-65535] ]];do
      read -p "Remote Udp2Raw Port(Udp2Raw远程端口): " RPORT
      echo""
    done
    while [[ ! "$MPORT" =~ [1-65535] ]];do
      read -p "Middle Port(Udp2Raw与UDPSpeeder中间端口): " MPORT
      CHECKMPORT=`netstat -ntl | grep $MPORT`
      if [[ "$CHECKMPORT" != "" ]]; then
        MPORT=0
        echo "端口已被占用";
      fi
      echo""
    done
    while [[ ! "$LPORT" =~ [1-65535] ]];do
      read -p "Listen Port(监听给本地其他业务用端口): " LPORT
      CHECKLPORT=`netstat -ntl | grep $LPORT`
      if [[ "$CHECKLPORT" != "" ]]; then
        LPORT=0
        echo "端口已被占用";
      fi
      if [ "$LPORT" == "$MPORT" ]; then
        LPORT=0
        echo "端口已被占用";
      fi
      echo""
    done
  ;;
  2)
    read -p "Udp2Raw Password(Udp2Raw密码): " PASSWD
      echo""
    while [[ ! "$RPORT" =~ [1-65535] ]];do
      read -p "Other Server Port(本地其他业务端口): " RPORT
      echo""
    done
    while [[ ! "$MPORT" =~ [1-65535] ]];do
      read -p "Middle Port(Udp2Raw与UDPSpeeder中间端口): " MPORT
      CHECKMPORT=`netstat -ntl | grep $MPORT`
      if [[ "$CHECKMPORT" != "" ]]; then
        MPORT=0
        echo "端口已被占用";
      fi
      if [ "$MPORT" == "$RPORT" ]; then
        MPORT=0
        echo "端口已被占用";
      fi
      echo""
    done
    while [[ ! "$LPORT" =~ [1-65535] ]];do
      read -p "Udp2Raw Listen Port(监听给远程UDP2RAW用): " LPORT
      CHECKLPORT=`netstat -ntl | grep $LPORT`
      if [[ "$CHECKLPORT" != "" ]]; then
        LPORT=0
        echo "端口已被占用";
      fi
      if [ "$LPORT" == "$MPORT" ]; then
        LPORT=0
        echo "端口已被占用";
      fi
      echo""
    done
  ;;
esac
  echo $IP
	echo $RPORT
	echo $MPORT
  echo $LPORT

