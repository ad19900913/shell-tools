#!/bin/sh
#=================================================
#	System Required: Linux,Git Bash
#	Description: 分销系统服务启停脚本
#	Version: 0.6
#	Author: ad19900913
#	Blog: https://www.sisyphus.tech
#=================================================

_red(){
    printf '\033[1;31;31m%b\033[0m' "$1"
}

_green(){
    printf '\033[1;31;32m%b\033[0m' "$1"
}

_yellow(){
    printf '\033[1;31;33m%b\033[0m' "$1"
}

_info(){
    _green "[Info] "
    printf -- "%s" "$1"
    printf "\n"
}

_warn(){
    _yellow "[Warning] "
    printf -- "%s" "$1"
    printf "\n"
}

_error(){
    _red "[Error] "
    printf -- "%s" "$1"
    printf "\n"
    exit 1
}

MODULE="$2"
ENV="$3"
WORK_DIR="/home/tomcat/ta"
BIN_DIR="${WORK_DIR}/bin"
FRONT_DIR="${WORK_DIR}/html"
BACK_UP_DIR="${WORK_DIR}/backup"
PID_NAME="${WORK_DIR}/pids/${MODULE}.pid"
JAR_NAME="ta-starter-${MODULE}-7.0-SNAPSHOT.jar"
HEAP_DUMP_PATH="${WORK_DIR}/logs/jvm"
CURRENT_DATE=`date +%Y-%m-%d`
CURRENT_TIME=`date +%H:%M:%S`
#IP=`ifconfig | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}'`
IP=`hostname -i`


#----- JVM Config ------------------------------------------------------
# HeadDump log file path
mkdir -p ${HEAP_DUMP_PATH}
# GC log file path
GC_LOG_PATH="${HEAP_DUMP_PATH}/${JAR_NAME}_GC.log"

# Java 虚拟机参数
JAVA_VM_OPTIONS=" "

# Server 模式
JAVA_OPTS=${JAVA_OPTS}" -server"

if [[ ${ENV} != "PROD" ]];
then
  case "${MODULE}" in
    base | manager | flow | gateway)
      JAVA_OPTS=${JAVA_OPTS}" -Dspring.config.location=/home/tomcat/ta/bin/${MODULE}.yml"
    ;;
    integration | trans | batch)
      JAVA_OPTS=${JAVA_OPTS}" -Dspring.config.location=/home/tomcat/ta/bin/${MODULE}.properties"
    ;;
  esac
fi

if [[ ${ENV} == "DEV" ]] || [[ ${ENV} == "SIT" ]] || [[ ${ENV} == "UAT" ]];
then
    # 内存设置
    ## 最大堆内存
    JAVA_OPTS=${JAVA_OPTS}" -Xmx512M"
    ## 初始堆内存
    JAVA_OPTS=${JAVA_OPTS}" -Xms512M"
    ##
    JAVA_OPTS=${JAVA_OPTS}" -XX:MaxMetaspaceSize=64M"
    ##
    JAVA_OPTS=${JAVA_OPTS}" -XX:MetaspaceSize=64M"
else
    case "${MODULE}" in
      base | flow | trans | manager | integration )
      # 内存设置
      ## 最大堆内存
      JAVA_OPTS=${JAVA_OPTS}" -Xmx512M"
      ## 初始堆内存
      JAVA_OPTS=${JAVA_OPTS}" -Xms512M"
      ##
      JAVA_OPTS=${JAVA_OPTS}" -XX:MaxMetaspaceSize=256M"
      ##
      JAVA_OPTS=${JAVA_OPTS}" -XX:MetaspaceSize=256M"
    ;;
    gateway )
      # 内存设置
      ## 最大堆内存
      JAVA_OPTS=${JAVA_OPTS}" -Xmx2048M"
      ## 初始堆内存
      JAVA_OPTS=${JAVA_OPTS}" -Xms1024M"
      ##
      JAVA_OPTS=${JAVA_OPTS}" -XX:MaxMetaspaceSize=512M"
      ##
      JAVA_OPTS=${JAVA_OPTS}" -XX:MetaspaceSize=256M"
    ;;
    batch )
      # 内存设置
      ## 最大堆内存
      JAVA_OPTS=${JAVA_OPTS}" -Xmx4096M"
      ## 初始堆内存
      JAVA_OPTS=${JAVA_OPTS}" -Xms2048M"
      ##
      JAVA_OPTS=${JAVA_OPTS}" -XX:MaxMetaspaceSize=512M"
      ##
      JAVA_OPTS=${JAVA_OPTS}" -XX:MetaspaceSize=512M"
      # ftps用启动参数
      JAVA_OPTS=${JAVA_OPTS}" -Djdk.tls.useExtendedMasterSecret=false"
    ;;
    esac
fi


# GC 设置 大于 4GB 用 G1GC
JAVA_OPTS=${JAVA_OPTS}" -XX:+UseG1GC"
## GC 最大停顿时间
JAVA_OPTS=${JAVA_OPTS}" -XX:MaxGCPauseMillis=100"
## 并行
JAVA_OPTS=${JAVA_OPTS}" -XX:+ParallelRefProcEnabled"
## 并行收集器线程数(与处理器数目相等)
JAVA_OPTS=${JAVA_OPTS}" -XX:ParallelGCThreads=4"
##
JAVA_OPTS=${JAVA_OPTS}" -XX:ConcGCThreads=4"

# GC 日志参数
##
JAVA_OPTS=${JAVA_OPTS}" -verbose:class"
## 打印 GC 详细信息
JAVA_OPTS=${JAVA_OPTS}" -XX:+PrintGCDetails"
## 打印 GC 日志时间戳
JAVA_OPTS=${JAVA_OPTS}" -XX:+PrintGCDateStamps"
##
JAVA_OPTS=${JAVA_OPTS}" -XX:+PrintClassHistogramBeforeFullGC"
##
JAVA_OPTS=${JAVA_OPTS}" -XX:+PrintClassHistogramAfterFullGC"
## 打印应用执行时间
JAVA_OPTS=${JAVA_OPTS}" -XX:+PrintGCApplicationConcurrentTime"
## 打印应用暂停时间
JAVA_OPTS=${JAVA_OPTS}" -XX:+PrintGCApplicationStoppedTime"
## 打印 Tenuring 年龄
JAVA_OPTS=${JAVA_OPTS}" -XX:+PrintTenuringDistribution"
## 打印堆信息
JAVA_OPTS=${JAVA_OPTS}" -XX:+PrintHeapAtGC"

## GC 日志输出路径
JAVA_OPTS=${JAVA_OPTS}" -Xloggc:${GC_LOG_PATH}"
## GC 日志文件数量
JAVA_OPTS=${JAVA_OPTS}" -XX:NumberOfGCLogFiles=10"
## GC 日志文件大小
JAVA_OPTS=${JAVA_OPTS}" -XX:GCLogFileSize=100M"
##
JAVA_OPTS=${JAVA_OPTS}" -XX:ErrorFile=${HEAP_DUMP_PATH}/hs_err_pid%p.log"

# OOM 日志
JAVA_OPTS=${JAVA_OPTS}" -XX:+HeapDumpOnOutOfMemoryError"
JAVA_OPTS=${JAVA_OPTS}" -XX:HeapDumpPath=${HEAP_DUMP_PATH}"

# 远程调试(测试环境开启) 生产关掉
# JAVA_OPTS=${JAVA_OPTS}" -agentlib:jdwp=transport=dt_socket,address=5005,server=y,suspend=n"

# 监控(测试环境开启) 生产关掉
#JAVA_OPTS=${JAVA_OPTS}" -Dcom.sun.management.jmxremote.port=8999"
#JAVA_OPTS=${JAVA_OPTS}" -Dcom.sun.management.jmxremote.authenticate=false"
#JAVA_OPTS=${JAVA_OPTS}" -Dcom.sun.management.jmxremote.ssl=false"
#-----------------------------------------------------------------------


#----- function --------------------------------------------------------
# Start service
function start(){
    cd ${BIN_DIR}
    _info "** Start Info **********************"
    _info "DateTime   : ${CURRENT_DATE} ${CURRENT_TIME}"
    _info "AppName    : ${MODULE}"
    _info "JvmOpts    : ${JAVA_OPTS}"
    _info "************************************"
    sleep 1

    nohup java -jar ${JAVA_OPTS} ${JAR_NAME} > /dev/null 2>&1 &
    echo ${!} > ${PID_NAME}

    _info "Pid        : ${!}"
    _info "***** Service [${MODULE}] on ${IP} start successfully. *****"
}

# stop service
function stop(){
    cd ${BIN_DIR}
    pid=`cat ${PID_NAME}`;
    _info "*********************************"
    _info "DateTime   : ${CURRENT_DATE} ${CURRENT_TIME}"
    _info "AppName    : ${MODULE}"
    _info "Pid        : ${pid}"
    _info "*********************************"

    if [[ "${pid}" ]]; then
        kill -9 ${pid}
    else
        _info "Not pid"
        exit;
    fi

    sleep 1
    rm ${PID_NAME}
    _info "***** Service [${MODULE}] on ${IP} stop successfully. *****"
}

function backup(){
    CURRENT_DATE_DIR=`date +%Y%m%d`
    mkdir -p ${BACK_UP_DIR}/${CURRENT_DATE_DIR}
    if [ "${MODULE}" == "front" ];
    then
      cp -rf ${FRONT_DIR} ${BACK_UP_DIR}/${CURRENT_DATE_DIR}
      echo "cp -rf ${FRONT_DIR} ${BACK_UP_DIR}/${CURRENT_DATE_DIR}"
    else
      cp -f ${BIN_DIR}/${JAR_NAME} ${BACK_UP_DIR}/${CURRENT_DATE_DIR}/${JAR_NAME}
      echo "cp -f ${BIN_DIR}/${JAR_NAME} ${BACK_UP_DIR}/${CURRENT_DATE_DIR}/${JAR_NAME}"
    fi
    _info "***** Service [${MODULE}] on ${IP} backup successfully. *****"
}

function rollback(){
    cd ${BACK_UP_DIR}
    LATEST_BACKUP_DATE=`ls -l | grep -v 'total' | awk '{print $9}' | sort -n -r | head -n1`
    if [ "${MODULE}" == "front" ];
    then
      rm -rf ${FRONT_DIR}/*
      echo "rm -rf ${FRONT_DIR}/*"
      cp -rf ${BACK_UP_DIR}/${LATEST_BACKUP_DATE}/html/* ${FRONT_DIR}
      echo "cp -rf ${BACK_UP_DIR}/${LATEST_BACKUP_DATE}/html/* ${FRONT_DIR}"
    else
      rm ${BIN_DIR}/${JAR_NAME}
      echo "rm ${BIN_DIR}/${JAR_NAME}"
      cp ${BACK_UP_DIR}/${LATEST_BACKUP_DATE}/${JAR_NAME} ${BIN_DIR}/${JAR_NAME}
      echo "cp ${BACK_UP_DIR}/${LATEST_BACKUP_DATE}/${JAR_NAME} ${BIN_DIR}/${JAR_NAME}"
    fi
    _info "***** Service [${MODULE}] on ${IP} rollback to ${LATEST_BACKUP_DATE}'version successfully. *****"
}

function restart(){
    cd ${BIN_DIR}
    pid=`cat ${PID_NAME}`;
    if [ "$pid" == null ]||[ "$pid" == "" ]; then
        _info "===== 没有检测到正在运行的服务!开始启动服务... ====="
        start
    else
        stop
        sleep 2
        _info "===== 开始启动服务... ====="
        start
    fi
}
#-----------------------------------------------------------------------

case "$1" in
  start )
    _info "===== 开始启动服务... ====="
    start
  ;;
  stop )
    _info "===== 开始停止服务... ====="
    stop
  ;;
  restart )
    _info "===== 开始重启服务... ====="
    restart
  ;;
  backup )
    _info "===== 开始备份服务... ====="
    backup
  ;;
  rollback )
    _info "===== 开始回退服务... ====="
    rollback
  ;;
esac

exit 0

