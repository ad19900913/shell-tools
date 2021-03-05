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

_error_detect(){
    local cmd="$1"
    _warn "${cmd}"
    eval ${cmd}
    if [[ $? -ne 0 ]]; then
        _error "Execution command (${cmd}) failed, please check it and try again."
    fi
}

_exists(){
    local cmd="$1"
    if eval type type > /dev/null 2>&1; then
        eval type "${cmd}" > /dev/null 2>&1
    elif command > /dev/null 2>&1; then
        command -v "${cmd}" > /dev/null 2>&1
    else
        which "${cmd}" > /dev/null 2>&1
    fi
    local rt=$?
    return ${rt}
}

#检查环境变量
check_env(){
    if ! _exists "mvn"; then
    _error_detect "请配置maven环境变量"
    elif ! _exists "git"; then
    _error_detect "请配置git环境变量"
    elif ! _exists "npm"; then
    _error_detect "请配置npm环境变量"
    fi
}

#初始化一些常量
init_param() {
    #公共常量
    #版本号
    SH_VERSION=0.6
    #基础工作目录，脚本中所有目录定位相对于此目录
    BASEDIR='/d/projects/ta-source'
    #脚本执行环境，默认DEV开发环境
    ENV='DEV'
    #批处理相关应用
    TA_STARTER_WORKDIR='ta-starter'
    #管理台前端VUE页面
    TA_FRONT_WORKDIR='Finance-TA-WEB7/k-client'
    #MVN编译选项
    MVN_OPT='-Dfile.encoding=UTF-8 -Dmaven.compile.fork=true -T 1C -DskipTests=true'
    #JAR包版本
    JAR_VERSION='7.0-SNAPSHOT'
    #是否清理屏幕
    CLEAR_SCREEN='true'
    #当前脚本文件绝对路径
    SHELL_PATH=$(readlink -f "$0")
    #当前日期
    CURRENT_DATE=`date +%Y%m%d`
    CURRENT_TIME=`date +%H%M%S`
    #操作描述
    STEP=''
    STEP_DESC=''

    #DEV常量
    DEV_NACOS_SERVER='xxx.xxx.xxx.xxx'
    DEV_GATEWAY_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    DEV_WEB_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    DEV_TRANS_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    DEV_BATCH_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    DEV_ACTIVE_BATCH_SERVER='xxx.xxx.xxx.xxx'

    #SIT常量
    SIT_NACOS_SERVER='xxx.xxx.xxx.xxx'
    SIT_GATEWAY_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    SIT_WEB_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    SIT_TRANS_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    SIT_BATCH_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    SIT_ACTIVE_BATCH_SERVER='xxx.xxx.xxx.xxx'

    #UAT常量
    UAT_NACOS_SERVER='xxx.xxx.xxx.xxx'
    UAT_GATEWAY_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    UAT_WEB_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    UAT_TRANS_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    UAT_BATCH_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    UAT_ACTIVE_BATCH_SERVER='xxx.xxx.xxx.xxx'

    #PROD常量
    PROD_NACOS_SERVER='xxx.xxx.xxx.xxx'
    PROD_GATEWAY_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    PROD_WEB_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    PROD_TRANS_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    PROD_BATCH_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    PROD_ACTIVE_BATCH_SERVER='xxx.xxx.xxx.xxx'

    #PT常量(压力测试环境)
    PT_NACOS_SERVER='xxx.xxx.xxx.xxx'
    PT_GATEWAY_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    PT_WEB_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    PT_TRANS_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    PT_BATCH_SERVER=('xxx.xxx.xxx.xxx' 'xxx.xxx.xxx.xxx')
    PT_ACTIVE_BATCH_SERVER='xxx.xxx.xxx.xxx'
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
        TA_MODULE_WORKDIR='ta-starter-gateway'
        ;;
        2)
        MODULE='base'
        TA_MODULE_WORKDIR='ta-starter-base'
        ;;
        3)
        MODULE='manager'
        TA_MODULE_WORKDIR='ta-starter-manager'
        ;;
        4)
        MODULE='batch'
        TA_MODULE_WORKDIR='ta-starter-batch'
        ;;
        5)
        MODULE='integration'
        TA_MODULE_WORKDIR='ta-starter-integration'
        ;;
        6)
        MODULE='trans'
        TA_MODULE_WORKDIR='ta-starter-trans'
        ;;
        7)
        MODULE='flow'
        TA_MODULE_WORKDIR='ta-starter-flow'
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
}

#选择操作环境
choose_env(){
    clear
    _info " 分销系统一键更新、编译、打包、部署脚本 [v${SH_VERSION}]
      -- ad19900913 | sisyphus.tech --
    ————————————选择操作环境————————————-
     1. DEV
     2. SIT
     3. UAT
     4. PROD
     5. PT(压力测试环境)
    ———————————————————————————————————" && echo

    read -p " 请输入数字 [1-5]:" num
    case "${num}" in
        1)
        ENV='DEV'
        NACOS_SERVER=${DEV_NACOS_SERVER}
        GATEWAY_SERVER=("${DEV_GATEWAY_SERVER[*]}")
        WEB_SERVER=("${DEV_WEB_SERVER[*]}")
        TRANS_SERVER=("${DEV_TRANS_SERVER[*]}")
        BATCH_SERVER=("${DEV_BATCH_SERVER[*]}")
        ACTIVE_BATCH_SERVER=${DEV_ACTIVE_BATCH_SERVER}
        ;;
        2)
        ENV='SIT'
        NACOS_SERVER=${SIT_NACOS_SERVER}
        GATEWAY_SERVER=("${SIT_GATEWAY_SERVER[*]}")
        WEB_SERVER=("${SIT_WEB_SERVER[*]}")
        TRANS_SERVER=("${SIT_TRANS_SERVER[*]}")
        BATCH_SERVER=("${SIT_BATCH_SERVER[*]}")
        ACTIVE_BATCH_SERVER=${SIT_ACTIVE_BATCH_SERVER}
        ;;
        3)
        ENV='UAT'
        NACOS_SERVER=${UAT_NACOS_SERVER}
        GATEWAY_SERVER=("${UAT_GATEWAY_SERVER[*]}")
        WEB_SERVER=("${UAT_WEB_SERVER[*]}")
        TRANS_SERVER=("${UAT_TRANS_SERVER[*]}")
        BATCH_SERVER=("${UAT_BATCH_SERVER[*]}")
        ACTIVE_BATCH_SERVER=${UAT_ACTIVE_BATCH_SERVER}
        ;;
        4)
        ENV='PROD'
        NACOS_SERVER=${PROD_NACOS_SERVER}
        GATEWAY_SERVER=("${PROD_GATEWAY_SERVER[*]}")
        WEB_SERVER=("${PROD_WEB_SERVER[*]}")
        TRANS_SERVER=("${PROD_TRANS_SERVER[*]}")
        BATCH_SERVER=("${PROD_BATCH_SERVER[*]}")
        ACTIVE_BATCH_SERVER=${PROD_ACTIVE_BATCH_SERVER}
        ;;
        5)
        ENV='PT'
        NACOS_SERVER=${PT_NACOS_SERVER}
        GATEWAY_SERVER=("${PT_GATEWAY_SERVER[*]}")
        WEB_SERVER=("${PT_WEB_SERVER[*]}")
        TRANS_SERVER=("${PT_TRANS_SERVER[*]}")
        BATCH_SERVER=("${PT_BATCH_SERVER[*]}")
        ACTIVE_BATCH_SERVER=${PT_ACTIVE_BATCH_SERVER}
        ;;
        *)
        clear
        _warn ":请输入正确数字 [1-5]"
        sleep 1s
        choose_env
        ;;
    esac
}

#上传前端静态文件
frontend_upload() {
    for server in ${WEB_SERVER[@]}
    do
        {
            ssh tomcat@"${server}" "rm -rf /home/tomcat/ta/html/*"
            scp -r ${BASEDIR}/${TA_FRONT_WORKDIR}/dist/* tomcat@${server}:/home/tomcat/ta/html/
            ssh tomcat@"${server}" "sed -i \"s/WEB_SERVER/${server}/g\" /home/tomcat/ta/html/static/js/app*"
        }&
    done
    wait
}

frontend_all() {
    update_web_code
    cd ${BASEDIR}/${TA_FRONT_WORKDIR} && npm run build
    frontend_upload
}

update_ta_code() {
    case "${MODULE}" in
        gateway | base | manager | flow | batch | integration | trans)
            update_code ${BASEDIR}/${TA_STARTER_WORKDIR}/${TA_MODULE_WORKDIR}
        ;;
        all)
            update_code ${BASEDIR}
        ;;
        *)
            _error "INVALID \${MODULE}=${MODULE}"
        ;;
    esac
}

update_web_code() {
    update_code ${BASEDIR}/${TA_FRONT_WORKDIR}
}

update_code() {
    cd $1
    git pull
}

install() {
    cd ${BASEDIR}/Finance-TA-APP && mvn ${MVN_OPT} clean install &
    cd ${BASEDIR}/Finance-TA-WEB7/k-cloud && mvn ${MVN_OPT} clean install &
    wait
    cd ${BASEDIR}/Finance-TA-WEB7/k-ta && mvn ${MVN_OPT} clean install
}

auto_postman() {
    if ! _exists "newman"; then
        _warn "请执行npm install -g newman"
    else
        newman run -e ${BASEDIR}/reference/测试工具/newman/TA-${ENV}.postman_environment.json -g ${BASEDIR}/reference/测试工具/newman/globals.postman_globals.json ${BASEDIR}/reference/测试工具/newman/ta.postman_collection.json
        _info "test complete!"
        if [[ $? -ne 0 ]];
        then
            _error "test failed!"
        else
            _info "test pass!"
        fi
    fi
}

package() {
    case "${MODULE}" in
        gateway | base | manager | flow | integration)
            cd ${BASEDIR}/${TA_STARTER_WORKDIR}/${TA_MODULE_WORKDIR} && mvn ${MVN_OPT} clean package
        ;;
        batch | trans)
            cd ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-common && mvn ${MVN_OPT} clean install
            cd ${BASEDIR}/${TA_STARTER_WORKDIR}/${TA_MODULE_WORKDIR} && mvn ${MVN_OPT} clean package
        ;;
        all)
            cd ${BASEDIR}/${TA_STARTER_WORKDIR} && mvn ${MVN_OPT} clean package
        ;;
        *)
            _error "INVALID \${MODULE}=${MODULE}"
        ;;
    esac
}

upload() {
    case "${MODULE}" in
        gateway)
            sed -i "s/NACOS_SERVER/${NACOS_SERVER}/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/${TA_MODULE_WORKDIR}/target/classes/bootstrap.yml
            for server in ${GATEWAY_SERVER[@]}
            do
                {
                    ssh tomcat@"${server}" "rm -f ~/ta/bin/${TA_MODULE_WORKDIR}-${JAR_VERSION}.jar && rm -f ~/ta/bin/${MODULE}.yml"
                    scp ${BASEDIR}/${TA_STARTER_WORKDIR}/${TA_MODULE_WORKDIR}/target/${TA_MODULE_WORKDIR}-${JAR_VERSION}.jar tomcat@${server}:/home/tomcat/ta/bin/
                    scp ${BASEDIR}/${TA_STARTER_WORKDIR}/${TA_MODULE_WORKDIR}/target/classes/bootstrap.yml tomcat@${server}:/home/tomcat/ta/bin/${MODULE}.yml
                }&
            done
            wait
            sed -i "s/${NACOS_SERVER}/NACOS_SERVER/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/${TA_MODULE_WORKDIR}/target/classes/bootstrap.yml
        ;;
        base | manager | flow)
            sed -i "s/NACOS_SERVER/${NACOS_SERVER}/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/${TA_MODULE_WORKDIR}/target/classes/bootstrap.yml
            for server in ${TRANS_SERVER[@]}
            do
                {
                    ssh tomcat@"${server}" "rm -f ~/ta/bin/${TA_MODULE_WORKDIR}-${JAR_VERSION}.jar && rm -f ~/ta/bin/${MODULE}.yml"
                    scp ${BASEDIR}/${TA_STARTER_WORKDIR}/${TA_MODULE_WORKDIR}/target/${TA_MODULE_WORKDIR}-${JAR_VERSION}.jar tomcat@${server}:/home/tomcat/ta/bin/
                    scp ${BASEDIR}/${TA_STARTER_WORKDIR}/${TA_MODULE_WORKDIR}/target/classes/bootstrap.yml tomcat@${server}:/home/tomcat/ta/bin/${MODULE}.yml
                }&
            done
            wait
            sed -i "s/${NACOS_SERVER}/NACOS_SERVER/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/${TA_MODULE_WORKDIR}/target/classes/bootstrap.yml
        ;;
        integration | trans)
            sed -i "s/NACOS_SERVER/${NACOS_SERVER}/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/${TA_MODULE_WORKDIR}/target/classes/bootstrap.properties
            for server in ${TRANS_SERVER[@]}
            do
                {
                    ssh tomcat@"${server}" "rm -f ~/ta/bin/${TA_MODULE_WORKDIR}-${JAR_VERSION}.jar && rm -f ~/ta/bin/${MODULE}.properties"
                    scp ${BASEDIR}/${TA_STARTER_WORKDIR}/${TA_MODULE_WORKDIR}/target/${TA_MODULE_WORKDIR}-${JAR_VERSION}.jar tomcat@${server}:/home/tomcat/ta/bin/
                    scp ${BASEDIR}/${TA_STARTER_WORKDIR}/${TA_MODULE_WORKDIR}/target/classes/bootstrap.properties tomcat@${server}:/home/tomcat/ta/bin/${MODULE}.properties
                }&
            done
            wait
            sed -i "s/${NACOS_SERVER}/NACOS_SERVER/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/${TA_MODULE_WORKDIR}/target/classes/bootstrap.properties
        ;;
        batch)
            sed -i "s/NACOS_SERVER/${NACOS_SERVER}/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/${TA_MODULE_WORKDIR}/target/classes/bootstrap.properties
            for server in ${BATCH_SERVER[@]}
            do
                {
                    ssh tomcat@"${server}" "rm -f ~/ta/bin/${TA_MODULE_WORKDIR}-${JAR_VERSION}.jar && rm -f ~/ta/bin/${MODULE}.properties"
                    scp ${BASEDIR}/${TA_STARTER_WORKDIR}/${TA_MODULE_WORKDIR}/target/${TA_MODULE_WORKDIR}-${JAR_VERSION}.jar tomcat@${server}:/home/tomcat/ta/bin/
                    scp ${BASEDIR}/${TA_STARTER_WORKDIR}/${TA_MODULE_WORKDIR}/target/classes/bootstrap.properties tomcat@${server}:/home/tomcat/ta/bin/${MODULE}.properties
                }&
            done
            wait
            sed -i "s/${NACOS_SERVER}/NACOS_SERVER/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/${TA_MODULE_WORKDIR}/target/classes/bootstrap.properties
        ;;
        all)
            sed -i "s/NACOS_SERVER/${NACOS_SERVER}/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-gateway/target/classes/bootstrap.yml
            sed -i "s/NACOS_SERVER/${NACOS_SERVER}/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-base/target/classes/bootstrap.yml
            sed -i "s/NACOS_SERVER/${NACOS_SERVER}/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-manager/target/classes/bootstrap.yml
            sed -i "s/NACOS_SERVER/${NACOS_SERVER}/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-flow/target/classes/bootstrap.yml
            sed -i "s/NACOS_SERVER/${NACOS_SERVER}/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-integration/target/classes/bootstrap.properties
            sed -i "s/NACOS_SERVER/${NACOS_SERVER}/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-trans/target/classes/bootstrap.properties
            sed -i "s/NACOS_SERVER/${NACOS_SERVER}/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-batch/target/classes/bootstrap.properties
            for server in ${GATEWAY_SERVER[@]}
            do
                {
                    #清理gateway的jar包
                    ssh tomcat@"${server}" "rm -f ~/ta/bin/ta-starter-gateway-${JAR_VERSION}.jar && rm -f ~/ta/bin/gateway.yml"
                    #上传gateway的jar包
                    scp ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-gateway/target/ta-starter-gateway-${JAR_VERSION}.jar tomcat@${server}:/home/tomcat/ta/bin/
                    #上传gateway的启动配置文件
                    scp ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-gateway/target/classes/bootstrap.yml tomcat@${server}:/home/tomcat/ta/bin/gateway.yml
                }&
            done

            for server in ${TRANS_SERVER[@]}
            do
                {
                    #清理base,ta,flow的jar包
                    ssh tomcat@"${server}" "rm -f ~/ta/bin/{base,ta,flow}-starter-${JAR_VERSION}.jar && rm -f ~/ta/bin/{base,ta,flow}.yml"
                    #上传base,ta,flow的jar包
                    scp ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-base/target/ta-starter-base-${JAR_VERSION}.jar tomcat@${server}:/home/tomcat/ta/bin/
                    scp ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-manager/target/ta-starter-manager-${JAR_VERSION}.jar tomcat@${server}:/home/tomcat/ta/bin/
                    scp ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-flow/target/ta-starter-flow-${JAR_VERSION}.jar tomcat@${server}:/home/tomcat/ta/bin/
                    #上传base的启动配置文件
                    scp ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-base/target/classes/bootstrap.yml tomcat@${server}:/home/tomcat/ta/bin/base.yml

                    #上传ta的启动配置文件
                    scp ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-manager/target/classes/bootstrap.yml tomcat@${server}:/home/tomcat/ta/bin/manager.yml

                    #上传flow的启动配置文件
                    scp ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-flow/target/classes/bootstrap.yml tomcat@${server}:/home/tomcat/ta/bin/flow.yml


                    #清理integration,trans的jar包
                    ssh tomcat@"${server}" "rm -f ~/ta/bin/ta-starter-{integration,trans}-${JAR_VERSION}.jar && rm -f ~/ta/bin/{integration,trans}.properties"
                    #上传integration,trans的jar包
                    scp ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-integration/target/ta-starter-integration-${JAR_VERSION}.jar tomcat@${server}:/home/tomcat/ta/bin/
                    scp ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-trans/target/ta-starter-trans-${JAR_VERSION}.jar tomcat@${server}:/home/tomcat/ta/bin/
                    #上传integration的启动配置文件
                    scp ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-integration/target/classes/bootstrap.properties tomcat@${server}:/home/tomcat/ta/bin/integration.properties

                    #上传trans的启动配置文件
                    scp ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-trans/target/classes/bootstrap.properties tomcat@${server}:/home/tomcat/ta/bin/trans.properties

                }&
            done

            for server in ${BATCH_SERVER[@]}
            do
                {
                    #清理batch的jar包
                    ssh tomcat@"${server}" "rm -f ~/ta/bin/ta-starter-batch-${JAR_VERSION}.jar && rm -f ~/ta/bin/batch.properties"
                    #上传batch的jar包
                    scp ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-batch/target/ta-starter-batch-${JAR_VERSION}.jar tomcat@${server}:/home/tomcat/ta/bin/
                    #上传batch的启动配置文件
                    scp ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-batch/target/classes/bootstrap.properties tomcat@${server}:/home/tomcat/ta/bin/batch.properties

                }&
            done
            wait
            sed -i "s/${NACOS_SERVER}/NACOS_SERVER/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-gateway/target/classes/bootstrap.yml
            sed -i "s/${NACOS_SERVER}/NACOS_SERVER/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-base/target/classes/bootstrap.yml
            sed -i "s/${NACOS_SERVER}/NACOS_SERVER/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-manager/target/classes/bootstrap.yml
            sed -i "s/${NACOS_SERVER}/NACOS_SERVER/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-flow/target/classes/bootstrap.yml
            sed -i "s/${NACOS_SERVER}/NACOS_SERVER/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-integration/target/classes/bootstrap.properties
            sed -i "s/${NACOS_SERVER}/NACOS_SERVER/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-trans/target/classes/bootstrap.properties
            sed -i "s/${NACOS_SERVER}/NACOS_SERVER/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-batch/target/classes/bootstrap.properties
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

execute() {
    case "${MODULE}" in
        gateway)
            for server in ${GATEWAY_SERVER[@]}
            do
              {
                ssh tomcat@"${server}" "cd /home/tomcat/ta/bin && ./ta.sh $1 ${MODULE} ${ENV}"
              }&
            done
        ;;
        base | manager | flow | integration | trans)
            for server in ${TRANS_SERVER[@]}
            do
              {
                ssh tomcat@"${server}" "cd /home/tomcat/ta/bin && ./ta.sh $1 ${MODULE} ${ENV}"
              }&
            done
        ;;
        batch)
            ssh tomcat@"${ACTIVE_BATCH_SERVER}" "cd /home/tomcat/ta/bin && ./ta.sh $1 ${MODULE} ${ENV}"
        ;;
        all)
            for server in ${GATEWAY_SERVER[@]}
            do
              {
                ssh tomcat@"${server}" "cd /home/tomcat/ta/bin && ./ta.sh $1 gateway ${ENV}"
              }&
            done
            for server in ${TRANS_SERVER[@]}
            do
              {
                ssh tomcat@"${server}" "cd /home/tomcat/ta/bin && ./ta.sh $1 base ${ENV}"
                ssh tomcat@"${server}" "cd /home/tomcat/ta/bin && ./ta.sh $1 integration ${ENV}"
                ssh tomcat@"${server}" "cd /home/tomcat/ta/bin && ./ta.sh $1 manager ${ENV}"
                ssh tomcat@"${server}" "cd /home/tomcat/ta/bin && ./ta.sh $1 flow ${ENV}"
                ssh tomcat@"${server}" "cd /home/tomcat/ta/bin && ./ta.sh $1 trans ${ENV}"
              }&
            done
            ssh tomcat@"${ACTIVE_BATCH_SERVER}" "cd /home/tomcat/ta/bin && ./ta.sh $1 batch ${ENV}"
        ;;
        *)
            _error "INVALID \${MODULE}=${MODULE}"
        ;;
    esac
    wait
}


restart() {
    stop
    start
}

half() {
    upload
    restart
}

backend_all() {
    update_ta_code
    package
    upload
    restart
}

all() {
    update_web_code
    update_ta_code
    cd ${BASEDIR}/${TA_FRONT_WORKDIR} && npm run build &
    package
    frontend_upload
    upload
    restart
}

#选择操作类型
choose_operation(){
    clear
    _info " 分销系统一键更新、编译、打包、部署脚本 [v${SH_VERSION}]
      -- ad19900913 | sisyphus.tech --
    ————————————选择操作类型————————————-
     0. [前端]上传静态文件至服务器
     1. [前端]全家桶(更新、编译、上传服务器)
     2. [后端]更新基础包
     3. [后端]测试接口
     4. [后端]启动
     5. [后端]停止
     6. [后端]重启
     7. [后端]半桶(上传&重启)
     8. [后端]全家桶(更新&打包&上传&重启)
     9. [生产环境专用]前端+后端全家桶(更新&打包&生成产物到指定目录)
     a. [前端+后端]全家桶(更新&打包&上传&重启)
    ————————————————————————————————" && echo

    read -p " 请输入数字 [0-a]:" num
    case "${num}" in
        0)
        STEP=0
        STEP_DESC='[前端]上传静态文件至服务器'
        ;;
        1)
        STEP=1
        STEP_DESC='[前端]全家桶(更新、编译、上传服务器)'
        ;;
        2)
        STEP=2
        STEP_DESC='[后端]更新基础包'
        ;;
        3)
        STEP=3
        STEP_DESC='[后端]测试接口'
        ;;
        4)
        STEP=4
        STEP_DESC='[后端]启动'
        ;;
        5)
        STEP=5
        STEP_DESC='[后端]停止'
        ;;
        6)
        STEP=6
        STEP_DESC='[后端]重启'
        ;;
        7)
        STEP=7
        STEP_DESC='[后端]半桶(上传&重启)'
        ;;
        8)
        STEP=8
        STEP_DESC='[后端]全家桶(更新&打包&上传&重启)'
        ;;
        9)
        STEP=9
        STEP_DESC='[生产环境专用]前端+后端全家桶(更新&打包&生成产物到指定目录)'
        ;;
        a)
        STEP=a
        STEP_DESC='[前端+后端]全家桶(更新&打包&上传&重启)'
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
    基础工作目录: ${BASEDIR}
    操作环境:${ENV}
    服务器地址:
        NACOS_SERVER:${NACOS_SERVER}
        GATEWAY_SERVER:${GATEWAY_SERVER[@]}
        WEB_SERVER:${WEB_SERVER[@]}
        TRANS_SERVER:${TRANS_SERVER[@]}
        BATCH_SERVER:${BATCH_SERVER[@]}
        ACTIVE_BATCH_SERVER:${ACTIVE_BATCH_SERVER}
    操作模块:${MODULE}
    操作描述:${STEP_DESC}
    ————————————————————————————————————
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
    begin=`date +%s`
    if [[ ${ENV} == "PROD" ]];
    then
        case "${STEP}" in
            2)
            install
            ;;
            9)
            build_prod_artifacts
            ;;
            *)
            clear
            sleep 1s
            ;;
        esac
    else
        case "${STEP}" in
            0)
            frontend_upload
            ;;
            1)
            frontend_all
            ;;
            2)
            install
            ;;
            3)
            auto_postman
            ;;
            4)
            start
            ;;
            5)
            stop
            ;;
            6)
            restart
            ;;
            7)
            half
            ;;
            8)
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
    fi
    end=`date +%s`
    _info "##########本次操作耗时: `expr ${end} - ${begin}` 秒##########"
}

build_prod_artifacts(){
#   清理产出物目录
    rm -rf ${BASEDIR}/production-release/${CURRENT_DATE}
    mkdir -p ${BASEDIR}/production-release/${CURRENT_DATE}/html
    mkdir -p ${BASEDIR}/production-release/${CURRENT_DATE}/jar
#   更新代码
    update_web_code
    update_ta_code
#   编译基础库
    install
    sed -i "s/NACOS_SERVER/${NACOS_SERVER}/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-base/src/main/resources/bootstrap.yml
    sed -i "s/NACOS_SERVER/${NACOS_SERVER}/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-manager/src/main/resources/bootstrap.yml
    sed -i "s/NACOS_SERVER/${NACOS_SERVER}/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-flow/src/main/resources/bootstrap.yml
    sed -i "s/NACOS_SERVER/${NACOS_SERVER}/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-gateway/src/main/resources/bootstrap.yml
    sed -i "s/NACOS_SERVER/${NACOS_SERVER}/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-integration/src/main/resources/bootstrap.properties
    sed -i "s/NACOS_SERVER/${NACOS_SERVER}/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-trans/src/main/resources/bootstrap.properties
    sed -i "s/NACOS_SERVER/${NACOS_SERVER}/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-batch/src/main/resources/bootstrap.properties
#   编译前端
    cd ${BASEDIR}/${TA_FRONT_WORKDIR} && npm run-script build &
#   编译后端
    package
    sed -i "s/${NACOS_SERVER}/NACOS_SERVER/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-base/src/main/resources/bootstrap.yml
    sed -i "s/${NACOS_SERVER}/NACOS_SERVER/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-manager/src/main/resources/bootstrap.yml
    sed -i "s/${NACOS_SERVER}/NACOS_SERVER/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-flow/src/main/resources/bootstrap.yml
    sed -i "s/${NACOS_SERVER}/NACOS_SERVER/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-gateway/src/main/resources/bootstrap.yml
    sed -i "s/${NACOS_SERVER}/NACOS_SERVER/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-integration/src/main/resources/bootstrap.properties
    sed -i "s/${NACOS_SERVER}/NACOS_SERVER/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-trans/src/main/resources/bootstrap.properties
    sed -i "s/${NACOS_SERVER}/NACOS_SERVER/g" ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-batch/src/main/resources/bootstrap.properties

    #前端注意httpUtil.js中的 basePath
    sed -i "s/WEB_SERVER:28688/ta.cqrcwm.com:443/g" ${BASEDIR}/${TA_FRONT_WORKDIR}/dist/static/js/app*
    cp -r ${BASEDIR}/${TA_FRONT_WORKDIR}/dist/* ${BASEDIR}/production-release/${CURRENT_DATE}/html/
    sed -i "s/ta.cqrcwm.com:443/WEB_SERVER:28688/g" ${BASEDIR}/${TA_FRONT_WORKDIR}/dist/static/js/app*

#   复制产出物到指定目录
    cp ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-base/target/ta-starter-base-${JAR_VERSION}.jar ${BASEDIR}/production-release/${CURRENT_DATE}/jar/
    cp ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-manager/target/ta-starter-manager-${JAR_VERSION}.jar ${BASEDIR}/production-release/${CURRENT_DATE}/jar/
    cp ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-gateway/target/ta-starter-gateway-${JAR_VERSION}.jar ${BASEDIR}/production-release/${CURRENT_DATE}/jar/
    cp ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-flow/target/ta-starter-flow-${JAR_VERSION}.jar ${BASEDIR}/production-release/${CURRENT_DATE}/jar/
    cp ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-integration/target/ta-starter-integration-${JAR_VERSION}.jar ${BASEDIR}/production-release/${CURRENT_DATE}/jar/
    cp ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-trans/target/ta-starter-trans-${JAR_VERSION}.jar ${BASEDIR}/production-release/${CURRENT_DATE}/jar/
    cp ${BASEDIR}/${TA_STARTER_WORKDIR}/ta-starter-batch/target/ta-starter-batch-${JAR_VERSION}.jar ${BASEDIR}/production-release/${CURRENT_DATE}/jar/
    _info "build产物已输出到[${BASEDIR}/production-release/${CURRENT_DATE}]目录下"
}

set_path(){
    clear
    _info " 分销系统一键更新、编译、打包、部署脚本 [v${SH_VERSION}]
      -- ad19900913 | sisyphus.tech --" && echo

    read -p " 请输入BASEDIR(基础工作目录):" BASEDIR
    if [[ ! -d ${BASEDIR} ]]
    then
        _error_detect "请输入正确的路径"
    fi
    sed -i -E "s#^\s*BASEDIR=.*#BASEDIR='${BASEDIR}'#g" ${SHELL_PATH}

}

init_param
check_env

while true
do
    if [[ ${CLEAR_SCREEN} == "true" ]]; then
        clear
    fi
    CLEAR_SCREEN="true"
    _info " 分销系统一键更新、编译、打包、部署脚本 [v${SH_VERSION}]
      -- ad19900913 | sisyphus.tech --

     0. 退出脚本
     1. 选择操作环境
     2. 选择操作类型
     3. 选择操作应用
     4. 执行
     5. 设置基础工作目录
    ————————————————————————————————" && echo

    read -p " 请输入数字 [0-5]:" CHOOSE
    case "${CHOOSE}" in
        0)
        exit 1
        ;;
        1)
        choose_env
        ;;
        2)
        choose_operation
        ;;
        3)
        choose_module
        ;;
        4)
        confirm
        ;;
        5)
        set_path
        ;;
        *)
        clear
        _warn ":请输入正确数字 [0-5]"
        sleep 1s
        ;;
    esac
done
