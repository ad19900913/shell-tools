#!/usr/bin/env bash

#=================================================
#	System Required: Linux,Git Bash
#	Description: 分销系统自动部署脚本(使用时自己指定BASEDIR目录)
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

#初始化一些常量
init_param() {
    #公共常量
    #版本号
    SH_VERSION=0.6
    #基础工作目录，脚本中所有目录定位相对于此目录
    BASEDIR='/D/ta-source'
    #JAR包版本
    JAR_VERSION='7.0-SNAPSHOT'
    #是否清理屏幕
    CLEAR_SCREEN="true"
    #脚本执行环境，默认生产环境
    ENV='PROD'

    #PROD常量
    PROD_NACOS_SERVER='xxx.xxx.xxx.xxx'
    PROD_GATEWAY_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    PROD_WEB_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    PROD_TRANS_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    PROD_BATCH_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    PROD_ACTIVE_BATCH_SERVER='xxx.xxx.xxx.xxx'

    NACOS_SERVER=${PROD_NACOS_SERVER}
    GATEWAY_SERVER=("${PROD_GATEWAY_SERVER[*]}")
    WEB_SERVER=("${PROD_WEB_SERVER[*]}")
    TRANS_SERVER=("${PROD_TRANS_SERVER[*]}")
    BATCH_SERVER=("${PROD_BATCH_SERVER[*]}")
    ACTIVE_BATCH_SERVER=${PROD_ACTIVE_BATCH_SERVER}
}

#选择操作模块
choose_module(){
    clear
    _info " 分销系统一键更新、编译、打包、部署脚本 [v${SH_VERSION}]
      -- ad19900913 | sisyphus.tech --
    ————————————选择操作模块————————————-
     1. gateway[网关]
     2. base[公共服务]
     3. manager[管理台增删改查]
     4. batch[批处理]
     5. integration[ESB请求转发]
     6. trans[实时交易]
     7. flow[工作流]
     8. all
    ———————————————————————————————————" && echo

    read -p " 请输入数字 [1-8]:" num
    case "${num}" in
        1)
        MODULE='gateway'
        ;;
        2)
        MODULE='base'
        ;;
        3)
        MODULE='manager'
        ;;
        4)
        MODULE='batch'
        ;;
        5)
        MODULE='integration'
        ;;
        6)
        MODULE='trans'
        ;;
        7)
        MODULE='flow'
        ;;
        8)
        MODULE='all'
        ;;
        *)
        clear
        _warn ":请输入正确数字 [1-8]"
        sleep 1s
        choose_module
        ;;
    esac
    TA_MODULE_WORKDIR="ta-starter-${MODULE}"
}

upload() {
    case "${MODULE}" in
        gateway)
            for server in ${GATEWAY_SERVER[@]}
            do
                {
                    ssh tomcat@"${server}" "rm -f ~/ta/bin/${MODULE}-starter-${JAR_VERSION}.jar"
                    scp ${BASEDIR}/jar/${TA_MODULE_WORKDIR}-${JAR_VERSION}.jar tomcat@${server}:/home/tomcat/ta/bin/
                }&
            done
            wait
        ;;
        base | manager | flow)
            for server in ${TRANS_SERVER[@]}
            do
                {
                    ssh tomcat@"${server}" "rm -f ~/ta/bin/${MODULE}-starter-${JAR_VERSION}.jar"
                    scp ${BASEDIR}/jar/${TA_MODULE_WORKDIR}-${JAR_VERSION}.jar tomcat@${server}:/home/tomcat/ta/bin/
                }&
            done
            wait
        ;;
        integration | trans)
            for server in ${TRANS_SERVER[@]}
            do
                {
                    ssh tomcat@"${server}" "rm -f ~/ta/bin/ta-starter-${MODULE}-${JAR_VERSION}.jar"
                    scp ${BASEDIR}/jar/${TA_MODULE_WORKDIR}-${JAR_VERSION}.jar tomcat@${server}:/home/tomcat/ta/bin/
                }&
            done
            wait
        ;;
        batch)
            for server in ${BATCH_SERVER[@]}
            do
                {
                    ssh tomcat@"${server}" "rm -f ~/ta/bin/ta-starter-${MODULE}-${JAR_VERSION}.jar"
                    scp ${BASEDIR}/jar/${TA_MODULE_WORKDIR}-${JAR_VERSION}.jar tomcat@${server}:/home/tomcat/ta/bin/
                }&
            done
            wait
        ;;
        all)
            for server in ${GATEWAY_SERVER[@]}
            do
                {
                    #清理gateway的jar包
                    ssh tomcat@"${server}" "rm -f ~/ta/bin/ta-starter-gateway-${JAR_VERSION}.jar"
                    #上传gateway的jar包
                    scp ${BASEDIR}/jar/ta-starter-gateway-${JAR_VERSION}.jar tomcat@${server}:/home/tomcat/ta/bin/
                }&
            done

            for server in ${TRANS_SERVER[@]}
            do
                {
                    #清理base,ta,flow的jar包
                    ssh tomcat@"${server}" "rm -f ~/ta/bin/ta-starter-{base,manager,flow}-${JAR_VERSION}.jar"
                    #上传base,ta,flow的jar包
                    scp ${BASEDIR}/jar/ta-starter-base-${JAR_VERSION}.jar tomcat@${server}:/home/tomcat/ta/bin/
                    scp ${BASEDIR}/jar/ta-starter-manager-${JAR_VERSION}.jar tomcat@${server}:/home/tomcat/ta/bin/
                    scp ${BASEDIR}/jar/ta-starter-flow-${JAR_VERSION}.jar tomcat@${server}:/home/tomcat/ta/bin/

                    #清理integration,trans的jar包
                    ssh tomcat@"${server}" "rm -f ~/ta/bin/ta-starter-{integration,trans}-${JAR_VERSION}.jar"
                    #上传integration,trans的jar包
                    scp ${BASEDIR}/jar/ta-starter-integration-${JAR_VERSION}.jar tomcat@${server}:/home/tomcat/ta/bin/
                    scp ${BASEDIR}/jar/ta-starter-trans-${JAR_VERSION}.jar tomcat@${server}:/home/tomcat/ta/bin/
                }&
            done

            for server in ${BATCH_SERVER[@]}
            do
                {
                    #清理batch的jar包
                    ssh tomcat@"${server}" "rm -f ~/ta/bin/ta-starter-batch-${JAR_VERSION}.jar"
                    #上传batch的jar包
                    scp ${BASEDIR}/jar/ta-starter-batch-${JAR_VERSION}.jar tomcat@${server}:/home/tomcat/ta/bin/
                }&
            done
            wait
        ;;
        *)
            _error "INVALID \${MODULE}=${MODULE}"
        ;;
    esac
}

start() {
    execute start
}

stop() {
    execute stop
}

backup() {
    execute backup
}

rollback() {
    execute rollback
}

execute() {
    case "${MODULE}" in
        gateway)
            for server in ${GATEWAY_SERVER[@]}
            do
                ssh tomcat@"${server}" "cd /home/tomcat/ta/bin && ./ta.sh $1 ${MODULE} ${ENV}"
            done
        ;;
        base | manager | flow | integration | trans)
            for server in ${TRANS_SERVER[@]}
            do
                ssh tomcat@"${server}" "cd /home/tomcat/ta/bin && ./ta.sh $1 ${MODULE} ${ENV}"
            done
        ;;
        batch)
            ssh tomcat@"${ACTIVE_BATCH_SERVER}" "cd /home/tomcat/ta/bin && ./ta.sh $1 ${MODULE} ${ENV}"
        ;;
        all)
            for server in ${GATEWAY_SERVER[@]}
            do
                ssh tomcat@"${server}" "cd /home/tomcat/ta/bin && ./ta.sh $1 gateway ${ENV}"
            done
            for server in ${TRANS_SERVER[@]}
            do
                ssh tomcat@"${server}" "cd /home/tomcat/ta/bin && ./ta.sh $1 base ${ENV}"
                ssh tomcat@"${server}" "cd /home/tomcat/ta/bin && ./ta.sh $1 integration ${ENV}"
                ssh tomcat@"${server}" "cd /home/tomcat/ta/bin && ./ta.sh $1 manager ${ENV}"
                ssh tomcat@"${server}" "cd /home/tomcat/ta/bin && ./ta.sh $1 flow ${ENV}"
                ssh tomcat@"${server}" "cd /home/tomcat/ta/bin && ./ta.sh $1 trans ${ENV}"
            done
            ssh tomcat@"${ACTIVE_BATCH_SERVER}" "cd /home/tomcat/ta/bin && ./ta.sh $1 batch ${ENV}"
        ;;
        *)
            _error "INVALID \${MODULE}=${MODULE}"
        ;;
    esac
}

#上传前端静态文件
frontendUpload() {
    for server in ${WEB_SERVER[@]}
    do
        {
            ssh tomcat@"${server}" "rm -rf /home/tomcat/ta/html/*"
            scp -r ${BASEDIR}/html/* tomcat@${server}:/home/tomcat/ta/html/
        }&
    done
    wait
}

frontendBackup() {
    for server in ${WEB_SERVER[@]}
    do
        {
            ssh tomcat@"${server}" "sh /home/tomcat/ta/bin/ta.sh backup front"
        }&
    done
    wait
}

frontendRollback() {
    for server in ${WEB_SERVER[@]}
    do
        {
            ssh tomcat@"${server}" "sh /home/tomcat/ta/bin/ta.sh rollback front"
        }&
    done
    wait
}

restart() {
    stop
    start
}

backend_all() {
    upload
    restart
}

all() {
    frontendUpload
    backend_all
}

#选择操作类型
choose_operation(){
    clear
    _info " 分销系统一键更新、编译、打包、部署脚本 [v${SH_VERSION}]
      -- ad19900913 | sisyphus.tech --
    ————————————选择操作类型————————————-
     0. [前端]上传
     1. [前端]备份
     2. [前端]回滚
     3. [后端]上传
     4. [后端]备份
     5. [后端]回滚
     6. [后端]启动
     7. [后端]停止
     8. [后端]重启
     9. [后端]上传&重启
     a. [前端+后端]上传&重启
    ————————————————————————————————" && echo

    read -p " 请输入数字 [0-a]:" num
    case "${num}" in
        0)
        STEP=0
        STEP_DESC='[前端]上传'
        ;;
        1)
        STEP=1
        STEP_DESC='[前端]备份'
        ;;
        2)
        STEP=2
        STEP_DESC='[前端]回滚'
        ;;
        3)
        STEP=3
        STEP_DESC='[后端]上传'
        ;;
        4)
        STEP=4
        STEP_DESC='[后端]备份'
        ;;
        5)
        STEP=5
        STEP_DESC='[后端]回滚'
        ;;
        6)
        STEP=6
        STEP_DESC='[后端]启动'
        ;;
        7)
        STEP=7
        STEP_DESC='[后端]停止'
        ;;
        8)
        STEP=8
        STEP_DESC='[后端]重启'
        ;;
        9)
        STEP=9
        STEP_DESC='[后端]上传&重启'
        ;;
        a)
        STEP=a
        STEP_DESC='[前端+后端]上传&重启'
        ;;
        *)
        clear
        _warn ":请输入正确数字 [0-a]"
        sleep 1s
        choose_operation
        ;;
    esac
}

#确认操作信息
confirm(){
    clear
    _info " 分销系统一键更新、编译、打包、部署脚本 [v${SH_VERSION}]
      -- ad19900913 | sisyphus.tech --
    ————————————确认操作信息————————————-
    基础工作目录:${BASEDIR}
    执行服务器地址:
        NACOS_SERVER:${NACOS_SERVER}
        GATEWAY_SERVER:${GATEWAY_SERVER[@]}
        WEB_SERVER:${WEB_SERVER[@]}
        TRANS_SERVER:${TRANS_SERVER[@]}
        BATCH_SERVER:${BATCH_SERVER[@]}
        ACTIVE_BATCH_SERVER:${ACTIVE_BATCH_SERVER}
    执行模块:${MODULE}
    执行操作:${STEP_DESC}
    ————————————————————————————————
    输入
     0. 执行上述操作
     1. 重新设置
    ————————————————————————————————" && echo

    read -p " 请输入数字 [0-1]:" num
    case "${num}" in
        0)
        process
        CLEAR_SCREEN="false"
        ;;
        1)
        ;;
        *)
        clear
        _warn ":请输入正确数字 [0-1]"
        sleep 1s
        confirm
        ;;
    esac
}

process(){
    clear
    _info " 分销系统一键更新、编译、打包、部署脚本 [v${SH_VERSION}]
      -- ad19900913 | sisyphus.tech --
    ————————————————————————————————" && echo

    case "${STEP}" in
        0)
        frontendUpload
        ;;
        1)
        frontendBackup
        ;;
        2)
        frontendRollback
        ;;
        3)
        upload
        ;;
        4)
        backup
        ;;
        5)
        rollback
        ;;
        6)
        start
        ;;
        7)
        stop
        ;;
        8)
        restart
        ;;
        9)
        backend_all
        ;;
        a)
        all
        ;;
        *)
        clear
        sleep 1s
        ;;
    esac
}

init_param

while true
do
    if [[ ${CLEAR_SCREEN} == "true" ]]; then
        clear
    fi
    CLEAR_SCREEN="true"
    _info " 分销系统一键更新、编译、打包、部署脚本 [v${SH_VERSION}]
      -- ad19900913 | sisyphus.tech --

     0. 退出脚本
     1. 选择操作类型
     2. 选择操作模块
     3. 执行
    ————————————————————————————————" && echo

    read -p " 请输入数字 [0-3]:" CHOOSE
    case "${CHOOSE}" in
        0)
        exit 1
        ;;
        1)
        choose_operation
        ;;
        2)
        choose_module
        ;;
        3)
        confirm
        ;;
        *)
        clear
        _warn ":请输入正确数字 [0-3]"
        sleep 1s
        ;;
    esac
done
