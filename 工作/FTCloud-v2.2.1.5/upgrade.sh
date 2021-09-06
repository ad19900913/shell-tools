#!/bin/bash
#=================================================
#	System Required: Linux,Git Bash
#	Description: FTCloud2.X版本通用升级脚本
#	Version: 1.0
#	Author: 江原臣
#	Blog: https://www.sisyphus.tech
#=================================================

#======================基础函数区开始===========================
_red() {
  printf '\033[1;31;31m%b\033[0m' "${1}"
}

_green() {
  printf '\033[1;31;32m%b\033[0m' "${1}"
}

_yellow() {
  printf '\033[1;31;33m%b\033[0m' "${1}"
}

_info() {
  _green "[INFO] "
  printf -- "%s" "$(date '+%Y-%m-%d %H:%M:%S') - ${1}"
  printf "\n"
}

_warn() {
  _yellow "[WARN] "
  printf -- "%s" "$(date '+%Y-%m-%d %H:%M:%S') - ${1}"
  printf "\n"
}

_error() {
  _red "[ERROR] "
  printf -- "%s" "$(date '+%Y-%m-%d %H:%M:%S') - ${1}"
  printf "\n"
  exit 1
}
#======================基础函数区结束===========================

#======================业务函数区开始===========================
#初始化一些参数
init_param() {
  #升级脚本版本
  SH_VERSION=0.1
  #抬头信息
  HEAD_INFO=" FTCloud一键升级脚本 [v${SH_VERSION}]
    ---- jiangyuanchen | sisyphus.tech ----"
  #模块是否升级的标志
  upgrade_base_flag=y
  upgrade_report_flag=y
  #  upgrade_S17_flag=n
  upgrade_devops_flag=y
  upgrade_freight_flag=y
  upgrade_database_flag=y
  #是否清理屏幕
  CLEAR_SCREEN='true'
  #升级前版本
  ORIGINAL_VERSION='2.2.1.4'
  #升级后版本
  NEW_VERSION='2.2.1.5'
  #  NEW_REPORT_VERSION='1.0.3'
  #  NEW_DEVOPS_VERSION='V2.1.3.0_p3'
  #  NEW_BASE_VERSION='1.0.2.2'
  #  NEW_S17_VERSION='S17-V2.0.5.8N'
  #有效用户
  UPGRADE_USERS=('streamax' 'root')
  #升级日期
  upgrade_date=$(date "+%Y%m%d")
  #备份包命名格式
  backup_service_format=_bak${upgrade_date}
  #升级包名称
  upgrade_package_name=Release_FTCloud_normal_V${NEW_VERSION}_multi
  #基础目录
  base_dir=/iotp
  upgrade_package_location=${base_dir}/${upgrade_package_name}.zip

  #货运服务安装目录
  freight_install_location=${base_dir}/freight
  #货运服务列表
  freight_services=('freight-server' 'ftvision-web' 'ftmanager-web')

  #新运维服务安装目录
  devops_install_location=${base_dir}/devops
  #新运维服务列表
  devops_service='devops-server'

  #报表服务安装目录
  report_install_location=${base_dir}/base-platform/report
  #报表服务列表
  report_service='report'

  #基础服务安装目录
  base_install_location=${base_dir}/base-platform/server
  #基础服务列表
  base_service_prefix='freight-base-platform-'
  #  base_services=('alarm' 'evidence' 'gateway' 'registry' 'server' 'tap')
  base_services=('server' 'tap' 'alarm')

  _info "${HEAD_INFO}
  ———————————————升级信息如下—————————————————
  升级前版本：${ORIGINAL_VERSION}
  升级后版本：${NEW_VERSION}
  -------------------------------------------"
}

#判断当前用户是否是streamax或root
check_user() {
  USER=$(whoami)
  if [[ ! "${UPGRADE_USERS[*]}" =~ ${USER} ]]; then
    _error "You must use root or streamax to upgrade!!!"
  else
    _info "Current user is ${USER}"
  fi
}

#判断服务器当前版本
check_version() {
  count=$(ls ${base_dir}/freight/server/freight-server/dist_lib/*${ORIGINAL_VERSION}.jar | wc -l)
  if [[ "${count}" == 0 ]]; then
    _error "Current freight version is not ${ORIGINAL_VERSION}!!!"
  fi
  _info "Current freight version is ${ORIGINAL_VERSION}"
}

#解压升级包
uncompress_package() {
  #判断升级包是否存在
  if [ ! -f "${upgrade_package_location}" ]; then
    _error "The upgrade package ${upgrade_package_location} does not exist !!!"
  fi

  #解压压缩包
  unzip -d ${base_dir} ${upgrade_package_location} >/dev/null 2>&1
  _info "Uncompress the upgrade package ${upgrade_package_location}"

  for f in "${base_dir}/${upgrade_package_name}"/*.tar.gz; do
    [[ -e "${f}" ]] || break # handle the case of no *.tar.gz files
    tar -zxf "${f}" -C "${base_dir}/${upgrade_package_name}"
    _info "Uncompress the upgrade sub package ${f}"
  done
}

#启动各服务
execute_services() {
  if [[ ${upgrade_base_flag} == "y" ]]; then
    #基础服务
    for base_service in ${base_services[*]}; do
      _info "${1^} [${base_service}]......"

      base_service=${base_service_prefix}${base_service}
      cd ${base_install_location} || exit 1
      su - streamax -c "cd ${base_install_location}/${base_service}/bin && ./${1}.sh"

      _info "${1^} [${base_service}] success!!!"
    done
  fi

  if [[ ${upgrade_freight_flag} == "y" ]]; then
    #货运服务
    for freight_service in ${freight_services[*]}; do
      _info "${1^} [${freight_service}]......"

      case "${freight_service}" in
      freight-server)
        cd ${freight_install_location}/server || exit 1
        su - streamax -c "cd ${freight_install_location}/server/${freight_service}/bin && ./${1}.sh"
        ;;
      ftvision-web | ftmanager-web)
        cd ${freight_install_location}/nodeweb || exit 1
        su - streamax -c "cd ${freight_install_location}/nodeweb/${freight_service}/bin && ./${1}.sh"
        ;;
      *)
        _error "INVALID \${freight_service}=${freight_service}"
        ;;
      esac

      _info "${1^} [${freight_service}] success!!!"
    done
  fi

  if [[ ${upgrade_report_flag} == "y" ]]; then
    #报表服务
    _info "${1^} [${report_service}]......"

    cd ${report_install_location} || exit 1
    su - streamax -c "cd ${report_install_location}/${report_service}/bin && ./${1}.sh"

    _info "${1^} [${report_service}] success!!!"
  fi

  if [[ ${upgrade_devops_flag} == "y" ]]; then
    #新运维服务
    _info "${1^} [${devops_service}]......"

    cd ${devops_install_location} || exit 1
    su - streamax -c "cd ${devops_install_location}/${devops_service}/bin && ./${1}.sh"

    _info "${1^} [${devops_service}] success!!!"
  fi
}

#升级基础服务
upgrade_base_service() {
  if [[ ${upgrade_base_flag} == "n" ]]; then
    _info "Skip upgrade [${base_services[*]}]......"
    return
  fi

  for base_service in ${base_services[*]}; do
    base_service=${base_service_prefix}${base_service}
    _info "Upgrade [${base_service}]......"

    cd ${base_install_location} || exit 1
    rm -rf ${base_service}${backup_service_format}
    mv ${base_service} ${base_service}${backup_service_format}
    mkdir -p ${base_service}
    mv ${base_dir}/${upgrade_package_name}/freight-base-platform*/lib/${base_service}_*.tar.gz ${base_install_location}
    tar -zxf ${base_service}_*.tar.gz -C ${base_service}
    rm -f ${base_service}_*.tar.gz
    \cp -rf ${base_service}${backup_service_format}/config/* ${base_service}/config/
    case "${base_service}" in
    freight-base-platform-tap)
      #增加配置
      echo "
#人脸处理开关
device.face.handle.flag=true
#人脸对比失败报警开关
device.face.alarm.flag=true" >>${base_service}/config/application.properties
      ;;
    *) ;;
    esac
    chown -R streamax:streamax ${base_service}
    chmod a+x ${base_install_location}/${base_service}/bin/*.sh

    _info "Upgrade [${base_service}] success!!!"
  done
}

#升级基础服务
rollback_base() {
  if [[ ${upgrade_base_flag} == "n" ]]; then
    _info "Skip rollback [${base_services[*]}]......"
    return
  fi

  for base_service in ${base_services[*]}; do
    base_service=${base_service_prefix}${base_service}
    _info "Rollback [${base_service}]......"

    cd ${base_install_location} || exit 1
    rm -rf ${base_service}
    mkdir ${base_service}
    \cp -rf ${base_service}${backup_service_format}/* ${base_service}/
    chown -R streamax:streamax ${base_service}
    chmod a+x ${base_install_location}/${base_service}/bin/*.sh

    _info "Rollback [${base_service}] success!!!"
  done
}

#升级货运上层服务
upgrade_freight() {
  if [[ ${upgrade_freight_flag} == "n" ]]; then
    _info "Skip upgrade [${freight_services[*]}]......"
    return
  fi

  for freight_service in ${freight_services[*]}; do
    _info "Upgrade [${freight_service}]......"

    case "${freight_service}" in
    freight-server)
      cd ${freight_install_location}/server || exit 1
      rm -rf ${freight_service}${backup_service_format}
      mv ${freight_service} ${freight_service}${backup_service_format}
      mkdir -p ${freight_service}
      mv ${base_dir}/${upgrade_package_name}/FTCloud_normal_V${NEW_VERSION}/freight/${freight_service}* ${freight_install_location}/server
      tar -zxf ${freight_service}_*.tar.gz -C ${freight_service}
      rm -f ${freight_service}_*.tar.gz
      \cp -rf ${freight_service}${backup_service_format}/config/* ${freight_service}/config/
      #增加配置
      echo "
#需要过滤的报警回传配置的报警类型（证据相关页面不展示），逗号分隔
filter.alarm.type=96" >>${freight_service}/config/application.properties
      chown -R streamax:streamax ${freight_service}
      chmod a+x ${freight_install_location}/server/${freight_service}/bin/*.sh
      ;;
    ftvision-web | ftmanager-web)
      cd ${freight_install_location}/nodeweb || exit 1
      rm -rf ${freight_service}${backup_service_format}
      mv ${freight_service} ${freight_service}${backup_service_format}
      mkdir -p ${freight_service}
      mv ${base_dir}/${upgrade_package_name}/FTCloud_normal_V${NEW_VERSION}/freight/${freight_service}* ${freight_install_location}/nodeweb
      tar -zxf ${freight_service}_*.tar.gz -C .
      rm -f ${freight_service}_*.tar.gz
      \cp -rf ${freight_service}${backup_service_format}/config.json ${freight_service}
      chown -R streamax:streamax ${freight_service}
      chmod a+x ${freight_install_location}/nodeweb/${freight_service}/bin/*.sh
      ;;
    *)
      _error "INVALID \${freight_service}=${freight_service}"
      ;;
    esac

    _info "Upgrade [${freight_service}] success!!!"
  done
}

#回滚货运上层服务
rollback_freight() {
  if [[ ${upgrade_freight_flag} == "n" ]]; then
    _info "Skip rollback [${freight_services[*]}]......"
    return
  fi

  for freight_service in ${freight_services[*]}; do
    _info "Rollback [${freight_service}]......"

    case "${freight_service}" in
    freight-server)
      cd ${freight_install_location}/server || exit 1
      rm -rf ${freight_service}
      mkdir ${freight_service}
      \cp -rf ${freight_service}${backup_service_format}/* ${freight_service}/
      chown -R streamax:streamax ${freight_service}
      chmod a+x ${freight_install_location}/server/${freight_service}/bin/*.sh
      ;;
    ftvision-web | ftmanager-web)
      cd ${freight_install_location}/nodeweb || exit 1
      rm -rf ${freight_service}
      mkdir ${freight_service}
      \cp -rf ${freight_service}${backup_service_format}/* ${freight_service}/
      chown -R streamax:streamax ${freight_service}
      chmod a+x ${freight_install_location}/nodeweb/${freight_service}/bin/*.sh
      ;;
    *)
      _error "INVALID \${freight_service}=${freight_service}"
      ;;
    esac

    _info "Rollback [${freight_service}] success!!!"
  done
}

#升级报表服务
upgrade_report() {
  if [[ ${upgrade_report_flag} == "n" ]]; then
    _info "Skip upgrade [${report_service}]......"
    return
  fi
  _info "Upgrade [${report_service}]......"

  cd ${report_install_location} || exit 1
  rm -rf ${report_service}${backup_service_format}
  mv ${report_service} ${report_service}${backup_service_format}
  mkdir -p ${report_service}
  mv ${base_dir}/${upgrade_package_name}/FTCloud_normal*/report/FTCloud-${report_service}_*.tar.gz ${report_install_location}
  tar --wildcards -zxf FTCloud-${report_service}_*.tar.gz FTCloud-report_normal*/lib/report_*
  tar -zxf FTCloud-report_normal*/lib/report_*.tar.gz -C ${report_service}
  rm -rf FTCloud-${report_service}_*.tar.gz FTCloud-report_normal*
  \cp -rf ${report_service}${backup_service_format}/config/* ${report_service}/config/
  chown -R streamax:streamax ${report_service}
  chmod a+x ${report_install_location}/${report_service}/bin/*.sh

  _info "Upgrade [${report_service}] success!!!"
}

#回滚报表服务
rollback_report() {
  if [[ ${upgrade_report_flag} == "n" ]]; then
    _info "Skip rollback [${report_service}]......"
    return
  fi
  _info "Rollback [${report_service}]......"

  cd ${report_install_location} || exit 1
  rm -rf ${report_service}
  mkdir ${report_service}
  \cp -rf ${report_service}${backup_service_format}/* ${report_service}/
  chown -R streamax:streamax ${report_service}
  chmod a+x ${report_install_location}/${report_service}/bin/*.sh

  _info "Rollback [${report_service}] success!!!"
}

upgrade_s17() {
  _info 'developing......'
}

upgrade_database() {
  if [[ ${upgrade_database_flag} == "n" ]]; then
    _info "Skip upgrade [database]......"
    return
  fi
  _info "Upgrade [database]......"
  mysql -uroot -h127.0.0.1 -p"$(cat /iotp/data/mariadb/.pswd)" -P13306 <${base_dir}/upgrade.sql
  _info "Upgrade [database] success!!!"
}

rollback_database() {
  if [[ ${upgrade_database_flag} == "n" ]]; then
    _info "Skip rollback [database]......"
    return
  fi
  _info "Rollback [database]......"
  mysql -uroot -h127.0.0.1 -p"$(cat /iotp/data/mariadb/.pswd)" -P13306 <${base_dir}/rollback.sql
  _info "Rollback [database] success!!!"
}

#升级新运维服务
upgrade_devops() {
  if [[ ${upgrade_devops_flag} == "n" ]]; then
    _info "Skip upgrade [${devops_service}]......"
    return
  fi

  _info "Upgrade [${devops_service}]......"

  cd ${devops_install_location} || exit 1
  rm -rf ${devops_service}${backup_service_format}
  mv ${devops_service} ${devops_service}${backup_service_format}
  mkdir ${devops_service}
  mv /iotp/Release_FTCloud_normal_V${NEW_VERSION}_multi/devops_normal_*/${devops_service}_*.tar.gz ${devops_service}
  tar -zxf ${devops_service}/${devops_service}_*.tar.gz -C ${devops_service}
  rm -f ${devops_service}/${devops_service}_*.tar.gz
  \cp -rf ${devops_service}${backup_service_format}/config/* ${devops_service}/config/
  #替换全量同步接口
  #config.businessSystemConfig.queryVehicleListUrl=/api/v1.0/car/list
  sed -i -E "s#^\s*config.businessSystemConfig.queryVehicleListUrl=.*#config.businessSystemConfig.queryVehicleListUrl=/api/v1.0/car/list#g" ${devops_service}/config/application-pro.properties
  #增加定时任务配置
  echo "
##定时任务,时间单位为分钟
schedule.sync.time=10" >>${devops_service}/config/application-pro.properties
  chown -R streamax:streamax ${devops_service}
  chmod a+x ${devops_install_location}/${devops_service}/bin/*.sh

  _info "Upgrade [${devops_service}] success!!!"
}

#回滚新运维服务
rollback_devops() {
  if [[ ${upgrade_devops_flag} == "n" ]]; then
    _info "Skip rollback [${devops_service}]......"
    return
  fi

  _info "Rollback [${devops_service}]......"

  cd ${devops_install_location} || exit 1
  rm -rf ${devops_service}
  mkdir ${devops_service}
  \cp -rf ${devops_service}${backup_service_format}/* ${devops_service}/
  chown -R streamax:streamax ${devops_service}
  chmod a+x ${devops_install_location}/${devops_service}/bin/*.sh

  _info "Rollback [${devops_service}] success!!!"
}

#删除升级包
clean_package() {
  _info "Clean the upgrade resources......"
  rm -f ${base_dir}/upgrade.sh
  rm -f ${base_dir}/upgrade.sql
  rm -f ${base_dir}/rollback.sql
  rm -rf ${base_dir}/${upgrade_package_name:?}*
  _info "Clean the upgrade resources success!!!"
}

#检查各服务状态
check_service() {
  _info "Check base-platform services ......"
  jps | grep base-platform
  count=$(jps | grep -c base-platform)
  if [[ "${count}" == 7 ]]; then
    _info "Check base-platform services pass!!!"
  else
    _error "Please check base-platform services and try again."
  fi

  _info "Check S17 services ......"

  if sh ${base_dir}/s17/script/install/get_S17_status.sh; then
    _info "Check S17 services pass!!!"
  else
    _error "Please check S17 services and try again."
  fi

  _info "Check devops services ......"
  jps | grep -i devops
  count=$(jps | grep -ic devops)
  if [[ "${count}" == 2 ]]; then
    _info "Check devops services pass!!!"
  else
    _error "Please check devops services and try again."
  fi

  _info "Check freight services ......"
  jps | grep -i freight-server
  count=$(jps | grep -c freight-server)
  if [[ "${count}" == 1 ]]; then
    _info "Check freight services pass!!!"
  else
    _error "Please check freight services and try again."
  fi

  _info "Check web services ......"
  pm2 list
  count=$(pm2 list | grep -c online)
  if [[ "${count}" == 4 ]]; then
    _info "Check web services pass!!!"
  else
    _error "Please check web services and try again."
  fi

  CLEAR_SCREEN=false
}

rollback_all() {
    rollback_base
    rollback_report
    rollback_devops
    rollback_freight
    rollback_database
}

#关闭守护脚本
stop_daemon() {
  count=$(ps -aux | grep -v grep | grep -c iotp_daemon_freight)
  if [[ "${count}" == 1 ]]; then
    kill -9 "$(ps -aux | grep iotp_daemon_freight | grep -v grep | awk '{print $2}')"
    _info "Kill daemon script."
  else
     _info "No daemon script exist."
  fi
}

#启动守护脚本
start_daemon() {
  sh /iotp/freight/script/iotp_daemon_freight.sh start
}

upgrade_all() {
  #升级前准备
  _info '====================================prepare start......=================================='
  stop_daemon
  execute_services stop
  check_user
  check_version
  uncompress_package
  _info '====================================prepare successed!!!=================================='

  #升级
  _info '====================================upgrade start......=================================='
  upgrade_freight
  upgrade_report
  upgrade_base_service
  #upgrade_s17
  upgrade_devops
  upgrade_database
  _info '====================================upgrade successed!!!=================================='

  #升级后验证
  _info '====================================business validation start......=================================='
  execute_services start
  sleep 30s
  check_service
  #clean_package
  _info '====================================business validation successed!!!=================================='
  sleep 10s
  start_daemon

  CLEAR_SCREEN=false
}

configure(){
    clear
    _info "${HEAD_INFO}" && echo

    read -r -p "是否更新base模块?(y/n)" upgrade_base_flag
    if [[ ${upgrade_base_flag} == "y" ]]
    then
        select_base_module
    fi

    read -r -p "是否更新report模块?(y/n)" upgrade_report_flag
    read -r -p "是否更新devops模块?(y/n)" upgrade_devops_flag
    read -r -p "是否更新数据库?(y/n)" upgrade_database_flag
    read -r -p "是否更新freight模块?(y/n)" upgrade_freight_flag
    if [[ ${upgrade_freight_flag} == "y" ]]
    then
        select_freight_module
    fi

}
#======================业务函数区结束===========================

#======================主流程开始===========================
init_param

while true; do
  if [[ ${CLEAR_SCREEN} == "true" ]]; then
    clear
  fi
  CLEAR_SCREEN="true"
  _info "${HEAD_INFO}
    ———————————————请选择要执行的操作—————————————————
     1. 验证服务
     2. 回滚服务
     3. 升级服务
     4. 配置脚本
     q. 退出脚本
    ------------------------------------------------" && echo

  read -r -p " 请输入数字 [0-5]:" CHOOSE
  case "${CHOOSE}" in
  q)
    exit 1
    ;;
  1)
    check_service
    ;;
  2)
    rollback_all
    ;;
  3)
    upgrade_all
    ;;
  4)
    configure
    ;;
  *)
    clear
    _warn ":请输入正确数字 [0-5]"
    sleep 1s
    ;;
  esac
done
#======================主流程结束===========================
