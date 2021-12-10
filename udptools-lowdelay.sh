#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#判断系统
#useradd -M -s /sbin/nologin -d /usr/local/udptools udptools
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
#检查目录
if [ ! -d "/usr/local/udptools" ]; then
  echo "未安装udptools,请先安装."
  exit
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

build_Udp2raw_Server()
{
#写入Udp2Raw配置
cat > /usr/local/udptools/conf/udp2raw-s${MPORT}.conf <<EOF
-s
# 服务器模式
-l 0.0.0.0:$LPORT
# 监听端口给UDP2RAW客户端
-r 127.0.0.1:$MPORT
# 连接UDPSpeeder端口
-k $PASSWD
# 密码
--cipher-mode xor
# 简单xor加密
--fix-gro
# 修复粘包
EOF

#写入Udp2Raw脚本
cat > /usr/local/udptools/udp2raw-s${MPORT}.sh <<EOF
#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#进程名
PROG=Udp2Raw-Server-${MPORT}
#BIN路径
BIN_FILE=/usr/local/udptools/bin/udp2raw
#配置路径
CONFIG_FILE=/usr/local/udptools/conf/udp2raw-s${MPORT}.conf
#日志路径
LOG_FILE=/usr/local/udptools/log/udp2raw-s${MPORT}.log
#PID路径
PID_FILE=/usr/local/udptools/pid/udp2raw-s${MPORT}.pid
EOF

cat >> /usr/local/udptools/udp2raw-s${MPORT}.sh <<"EOF"
checkSet(){
  #获取监听端口
  SERVER_PORT=`cat $CONFIG_FILE | grep '\-l ' | awk -F ":" '{print $2}'`
  #检查iptables规则
  IPTALBES=`iptables -nvL | grep DROP | grep tcp | grep $SERVER_PORT`
  echo "IPTABLES_DEBUG" >> $LOG_FILE
  echo $IPTALBES >> $LOG_FILE
  if [ ! -n "$IPTALBES" ]; then
    echo "Adding iptables rules."
    #添加iptables规则
    RULES=`$BIN_FILE --conf-file $CONFIG_FILE -g | grep iptables |grep -v rule`
    $RULES
  fi
  #赋权
  setcap cap_net_raw+ep $BIN_FILE
}
status(){
  PID=`ps aux|grep $CONFIG_FILE|grep -v sudo|grep -v grep | awk '{print $2}'`
  if [ ! -n "$PID" ]; then
    rm -f $PID_FILE
    echo "$PROG已停止."
  else
    echo $PID > $PID_FILE
    echo "$PROG已启动. PID: $PID"
  fi
}
start(){
  #启动进程
  nohup $BIN_FILE --keep-rule --conf-file $CONFIG_FILE >> $LOG_FILE 2>&1 &
  #checkSet
  #sudo -u nobody -b $BIN_FILE --conf-file $CONFIG_FILE >> $LOG_FILE 2>&1
  #Centos8无法nobody运行
  status
}
stop(){
  #结束进程
  status > /dev/null 2>&1
  PID=`cat $PID_FILE`
  kill $PID >/dev/null 2>&1
  sleep 1
  status
}
showLog(){
  cat $LOG_FILE | tail -n 50
}
case "$1" in
start)
    echo "Starting $PROG..."
    start
    ;;
stop)
    echo "Stopping $PROG..."
    stop
    ;;
restart)
    echo "Stopping $PROG..."
    stop
    sleep 2
    echo "Starting $PROG..."
    start
    ;;
status)
    status
    ;;
log)
    showLog
    ;;
*)
    echo "Usage: $PROG {start|stop|restart|status|log}"
    ;;
esac
exit 0
EOF

chmod +x /usr/local/udptools/udp2raw-s${MPORT}.sh

#判断服务模式
if pgrep systemd-journal > /dev/null; then
  if [ ! -f "/usr/lib/systemd/system/udp2raw-server@.service" ]; then
    cp ./systemctl/service/udp2raw-server@.service /usr/lib/systemd/system/
  fi
  systemctl enable udp2raw-server@${MPORT}.service
  systemctl start udp2raw-server@${MPORT}.service
else
  cat > /etc/init.d/udp2raw-s${MPORT} <<EOF
#!/bin/bash
# startup script for the Udp2Raw Server
# chkconfig: 345 80 20
# description: start the Udp2Raw deamon
#
# Source function library
. /etc/rc.d/init.d/functions

prog=Udp2Raw-Server-${MPORT}
/usr/local/udptools/udp2raw-s${MPORT}.sh \$1
EOF
chmod +x /etc/init.d/udp2raw-s${MPORT}
chkconfig --add udp2raw-s${MPORT}
chkconfig udp2raw-s${MPORT} on
service udp2raw-s${MPORT} start
fi
}

build_UdpSpeeder_Server()
{
#写入UdpSpeeder脚本
cat > /usr/local/udptools/udpspeeder-s${MPORT}.sh <<EOF
#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#进程名
PROG=UDPspeeder-Server-${MPORT}
#BIN路径
BIN_FILE=/usr/local/udptools/bin/udpspeeder
#配置参数
CONFIG="-s -l 127.0.0.1:${MPORT} -r 127.0.0.1:${RPORT} --mode 0 -f2:1 --timeout 1"
#-l 127.0.0.1:${MPORT}监听端口给udp2raw用
#-r 127.0.0.1:${RPORT}连接原始服务端口
#日志路径
LOG_FILE=/usr/local/udptools/log/udpspeeder-s${MPORT}.log
#PID路径
PID_FILE=/usr/local/udptools/pid/udpspeeder-s${MPORT}.pid
#PS查找进程用的关键词
PSKEY=":${MPORT}"
EOF

cat >> /usr/local/udptools/udpspeeder-s${MPORT}.sh <<"EOF"
status(){
  PID=`ps aux|grep udpspeeder|grep "$PSKEY"|grep -v sudo|grep -v grep | awk '{print $2}'`
  if [ ! -n "$PID" ]; then
    rm -f $PID_FILE
    echo "$PROG已停止."
  else
    echo $PID > $PID_FILE
    echo "$PROG已启动. PID: $PID"
  fi
}
start(){
  #启动进程
  #sudo -u nobody -b $BIN_FILE $CONFIG >> $LOG_FILE 2>&1
  nohup $BIN_FILE $CONFIG >> $LOG_FILE 2>&1 &
  status
}
stop(){
  #结束进程
  status > /dev/null 2>&1
  PID=`cat $PID_FILE`
  kill $PID >/dev/null 2>&1
  sleep 1
  status
}
showLog(){
  cat $LOG_FILE | tail -n 50
}
case "$1" in
start)
    echo "Starting $PROG..."
    start
    ;;
stop)
    echo "Stopping $PROG..."
    stop
    ;;
restart)
    echo "Stopping $PROG..."
    stop
    sleep 2
    echo "Starting $PROG..."
    start
    ;;
status)
    status
    ;;
log)
    showLog
    ;;
*)
    echo "Usage: $PROG {start|stop|restart|status|log}"
    ;;
esac
exit 0
EOF
chmod +x /usr/local/udptools/udpspeeder-s${MPORT}.sh

#判断服务模式
if pgrep systemd-journal > /dev/null; then
  if [ ! -f "/usr/lib/systemd/system/udpspeeder-server@.service" ]; then
    cp ./systemctl/service/udpspeeder-server@.service /usr/lib/systemd/system/
  fi
  systemctl enable udpspeeder-server@${MPORT}.service
  systemctl start udpspeeder-server@${MPORT}.service
else

  cat > /etc/init.d/udpspeeder-s${MPORT} <<EOF
#!/bin/bash
# startup script for the UDPspeeder Server
# chkconfig: 345 80 20
# description: start the UDPspeeder deamon
#
# Source function library
. /etc/rc.d/init.d/functions

prog=UDPspeeder-Server-${MPORT}
/usr/local/udptools/udpspeeder-s${MPORT}.sh \$1
EOF
chmod +x /etc/init.d/udpspeeder-s${MPORT}
chkconfig --add udpspeeder-s${MPORT}
chkconfig udpspeeder-s${MPORT} on
service udpspeeder-s${MPORT} start
fi
}

build_Udp2raw_Client()
{
#写入Udp2Raw配置
cat > /usr/local/udptools/conf/udp2raw-c${MPORT}.conf <<EOF
-c
# 客户端模式
-l 127.0.0.1:$MPORT
# 监听端口给UdpSpeeder用
-r $REMOTEIP:$RPORT
# 连接UDP2RAW服务端
-k $PASSWD
# 密码
--cipher-mode xor
# 简单xor加密
--fix-gro
# 修复粘包
EOF


#写入Udp2Raw脚本
cat > /usr/local/udptools/udp2raw-c${MPORT}.sh <<EOF
#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#进程名
PROG=Udp2Raw-Client-${MPORT}
#BIN路径
BIN_FILE=/usr/local/udptools/bin/udp2raw
#配置路径
CONFIG_FILE=/usr/local/udptools/conf/udp2raw-c${MPORT}.conf
#日志路径
LOG_FILE=/usr/local/udptools/log/udp2raw-c${MPORT}.log
#PID路径
PID_FILE=/usr/local/udptools/pid/udp2raw-c${MPORT}.pid
EOF

cat >> /usr/local/udptools/udp2raw-c${MPORT}.sh <<"EOF"
checkSet(){
  #获取监听端口
  SERVER_PORT=`cat $CONFIG_FILE | grep '\-r ' | awk -F ":" '{print $2}'`
  SERVER_ADDRESS=`cat $CONFIG_FILE | grep '\-r ' | awk -F ":" '{print $1}' | awk '{print $2}'`
  #检查iptables规则
  IPTALBES=`iptables -nvL | grep DROP | grep tcp | grep $SERVER_PORT | grep $SERVER_ADDRESS`
  echo "IPTABLES_DEBUG" >> $LOG_FILE
  echo $IPTALBES >> $LOG_FILE
  if [ ! -n "$IPTALBES" ]; then
    echo "Adding iptables rules."
    #添加iptables规则
    RULES=`$BIN_FILE --conf-file $CONFIG_FILE -g | grep iptables |grep -v rule`
    $RULES
  fi
  #赋权
  setcap cap_net_raw+ep $BIN_FILE
}
status(){
  PID=`ps aux|grep $CONFIG_FILE|grep -v sudo|grep -v grep | awk '{print $2}'`
  if [ ! -n "$PID" ]; then
    rm -f $PID_FILE
    echo "$PROG已停止."
  else
    echo $PID > $PID_FILE
    echo "$PROG已启动. PID: $PID"
  fi
}
start(){
  #启动进程
  nohup $BIN_FILE --keep-rule --conf-file $CONFIG_FILE >> $LOG_FILE 2>&1 &
  #checkSet
  #sudo -u nobody -b $BIN_FILE --conf-file $CONFIG_FILE >> $LOG_FILE 2>&1
  #Centos8无法nobody运行
  status
}
stop(){
  #结束进程
  status > /dev/null 2>&1
  PID=`cat $PID_FILE`
  kill $PID >/dev/null 2>&1
  sleep 1
  status
}
showLog(){
  cat $LOG_FILE | tail -n 50
}
case "$1" in
start)
    echo "Starting $PROG..."
    start
    ;;
stop)
    echo "Stopping $PROG..."
    stop
    ;;
restart)
    echo "Stopping $PROG..."
    stop
    sleep 2
    echo "Starting $PROG..."
    start
    ;;
status)
    status
    ;;
log)
    showLog
    ;;
*)
    echo "Usage: $PROG {start|stop|restart|status|log}"
    ;;
esac
exit 0
EOF

chmod +x /usr/local/udptools/udp2raw-c${MPORT}.sh

#判断服务模式
if pgrep systemd-journal > /dev/null; then
  if [ ! -f "/usr/lib/systemd/system/udp2raw-client@.service" ]; then
    cp ./systemctl/service/udp2raw-client@.service /usr/lib/systemd/system/
  fi
  systemctl enable udp2raw-client@${MPORT}.service
  systemctl start udp2raw-client@${MPORT}.service
else
  cat > /etc/init.d/udp2raw-c${MPORT} <<EOF
#!/bin/bash
# startup script for the Udp2Raw Client
# chkconfig: 345 80 20
# description: start the Udp2Raw deamon
#
# Source function library
. /etc/rc.d/init.d/functions

prog=Udp2Raw-Client-${MPORT}
/usr/local/udptools/udp2raw-c${MPORT}.sh \$1
EOF
chmod +x /etc/init.d/udp2raw-c${MPORT}
chkconfig --add udp2raw-c${MPORT}
chkconfig udp2raw-c${MPORT} on
service udp2raw-c${MPORT} start
fi
}

build_UdpSpeeder_Client()
{
#写入UdpSpeeder脚本
cat > /usr/local/udptools/udpspeeder-c${MPORT}.sh <<EOF
#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#进程名
PROG=UDPspeeder-Client-${MPORT}
#BIN路径
BIN_FILE=/usr/local/udptools/bin/udpspeeder
#配置参数
CONFIG="-c -l 0.0.0.0:${LPORT} -r 127.0.0.1:${MPORT} --mode 0 -f2:1 --timeout 1"
#-l 0.0.0.0:${LPORT}监听端口给其他程序用
#-r 127.0.0.1:${MPORT}连接Udp2Raw
#日志路径
LOG_FILE=/usr/local/udptools/log/udpspeeder-c${MPORT}.log
#PID路径
PID_FILE=/usr/local/udptools/pid/udpspeeder-c${MPORT}.pid
#PS查找进程用的关键词
PSKEY=":${MPORT}"
EOF

cat >> /usr/local/udptools/udpspeeder-c${MPORT}.sh <<"EOF"
status(){
  PID=`ps aux|grep udpspeeder|grep "$PSKEY"|grep -v sudo|grep -v grep | awk '{print $2}'`
  if [ ! -n "$PID" ]; then
    rm -f $PID_FILE
    echo "$PROG已停止."
  else
    echo $PID > $PID_FILE
    echo "$PROG已启动. PID: $PID"
  fi
}
start(){
  #启动进程
  #sudo -u nobody -b $BIN_FILE $CONFIG >> $LOG_FILE 2>&1
  nohup $BIN_FILE $CONFIG >> $LOG_FILE 2>&1 &
  status
}
stop(){
  #结束进程
  status > /dev/null 2>&1
  PID=`cat $PID_FILE`
  kill $PID >/dev/null 2>&1
  sleep 1
  status
}
showLog(){
  cat $LOG_FILE | tail -n 50
}
case "$1" in
start)
    echo "Starting $PROG..."
    start
    ;;
stop)
    echo "Stopping $PROG..."
    stop
    ;;
restart)
    echo "Stopping $PROG..."
    stop
    sleep 2
    echo "Starting $PROG..."
    start
    ;;
status)
    status
    ;;
log)
    showLog
    ;;
*)
    echo "Usage: $PROG {start|stop|restart|status|log}"
    ;;
esac
exit 0
EOF
chmod +x /usr/local/udptools/udpspeeder-c${MPORT}.sh

#判断服务模式
if pgrep systemd-journal > /dev/null; then
  if [ ! -f "/usr/lib/systemd/system/udpspeeder-client@.service" ]; then
    cp ./systemctl/service/udpspeeder-client@.service /usr/lib/systemd/system/
  fi
  systemctl enable udpspeeder-client@${MPORT}.service
  systemctl start udpspeeder-client@${MPORT}.service
else
  cat > /etc/init.d/udpspeeder-c${MPORT} <<EOF
#!/bin/bash
# startup script for the UDPspeeder Client
# chkconfig: 345 80 20
# description: start the UDPspeeder deamon
#
# Source function library
. /etc/rc.d/init.d/functions

prog=UDPspeeder-Client-${MPORT}
/usr/local/udptools/udpspeeder-c${MPORT}.sh \$1
EOF
chmod +x /etc/init.d/udpspeeder-c${MPORT}
chkconfig --add udpspeeder-c${MPORT}
chkconfig udpspeeder-c${MPORT} on
service udpspeeder-c${MPORT} start
fi
}

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
    read -p "Remote Udp2Raw IP(Udp2Raw远程IP): " REMOTEIP
      echo""
    while [[ ! "$RPORT" =~ [1-65535] ]];do
      read -p "Remote Udp2Raw Port(Udp2Raw远程端口): " RPORT
      echo""
    done
    while [[ ! "$MPORT" =~ [1-65535] ]];do
      read -p "Middle Port(Udp2Raw与UDPSpeeder中间端口): " MPORT
      CHECKMPORT=`netstat -nul | grep $MPORT`
      if [[ "$CHECKMPORT" != "" ]]; then
        MPORT=0
        echo "端口已被占用";
      fi
      echo""
    done
    while [[ ! "$LPORT" =~ [1-65535] ]];do
      read -p "Listen Port(监听给本地其他业务用端口): " LPORT
      CHECKLPORT=`netstat -nul | grep $LPORT`
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
    
    build_Udp2raw_Client
    build_UdpSpeeder_Client
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
      CHECKMPORT=`netstat -nul | grep $MPORT`
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
    
    build_Udp2raw_Server
    build_UdpSpeeder_Server
  ;;
esac
