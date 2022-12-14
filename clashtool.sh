#!/usr/bin/env bash

set -e

# clash平台
platform='clash-linux-amd64'
# clash 程序目录
clash_catalog="/usr/local/clash"
# clash 配置目录
config_catalog="${HOME}/.config/clash"

# clash UI目录
clash_gh_pages_catalog="${clash_catalog}/clash_gh_pages"
# subscribe配置文件
subscribe_config_catalog="${config_catalog}/subscribe"
# clash文件
clash_path="${clash_catalog}/clash"
# clash配置文件
config_path="${config_catalog}/config.yaml"
# clashtool 配置文件
clashtool_config_path="${config_catalog}/clashtool.ini"

# 当前脚本目录
tool_catalog=$(cd $(dirname $0);pwd)
# 保存程序运行状态
state=$(ps -ef | grep "${clash_path}" | grep -v grep | awk '{print $1}')

# 公共配置操作函数 开始

# 获取值
function ini_get_value()
{
    local file=$1
    local sec=$2
    local key=$3
    local val=$(awk -F "[=;#]+" '/^\[[ \t]*'${sec}'[ \t]*\]/{a=1}a==1&&$1~/^[ \t]*'${key}'[ \t]*/{gsub(/[ \t]+/,"",$2);print $2;exit}' ${file}) 
    echo ${val}
}

 # 更新值
function ini_set_value(){
    local file=$1
    local sec=$2
    local key=$3
    local val=$4
    # 转义特殊字符
    val=$(echo "${val}" | sed 's/\//\\\//g')
    # 更新字符串
    sed -i "/^\[[ \t]*${sec}[ \t]*\]/,/^\[/s/^[ \t]*\(${key}[ \t]*=[ \t]*\)[^ \t;#]*/\1${val}/" ${file}
}

#判断section是否存在
function ini_existence_section(){
    local file=$1
    local sec=$2
    # 转义特殊字符
    grep -q "^\[${sec}\]" ${file} >> /dev/null
    echo $?
}


# 删除订阅
function ini_del_value() {    
    local file=$1
    local sec=$2
    # 转义特殊字符
    sec=$(echo "${val}" | sed 's/\//\\\//g')
    sed -i "/^\[${sec}\]/,/^\[/d" ${clashtool_config_path}
}
# 公共配置操作函数 结束


# 获取clashtool配置
function get_clashtool_config() {
    local key=$1
    local val=$(ini_get_value ${clashtool_config_path} 'clashtool' "${key}")
    echo ${val}
}

# 写入clashtool配置
function set_clashtool_config() {
    local key=$1
    local val=$2
    ini_set_value ${clashtool_config_path} "clashtool" "${key}" "${val}"
}

# 获取订阅配置
function get_subscribe_config() {
    local sec=$1
    local key=$2
    if [[ -z "${sec}" ]];then
        local sec="subscribe"
    else
        local sec="subscribe_$1"
    fi
    local val=$(ini_get_value "${clashtool_config_path}" "${sec}" "${key}")
    echo ${val}
}

# 写入订阅配置
function set_subscribe_config() {
    local sec=$1
    local key=$2
    local val=$3
    if [[ -z "${sec}" ]];then
        sec="subscribe"
    else
        sec="subscribe_${sec}"
    fi
    ini_set_value ${clashtool_config_path} "${sec}" "${key}" "${val}"
}

# 判断订阅是否存在
function existence_subscrib_config(){
    local sec=$1
    local exis=$(ini_existence_section ${clashtool_config_path} "subscribe_${sec}")
    echo ${exis}
}
# 创建订阅配置
function create_subscrib_config(){
    local sec="subscribe_$1"
    local url="$2"
    local interval="$3"
    local update="$4"
    echo -e "\n[${sec}]\nurl=${url}\ninterval=${interval}\nupdate=${update}" >> ${clashtool_config_path}
}

# 删除订阅
function del_subscribe_config() {    
    local sec=subscribe_$1;
    # 转义特殊字符
    sed -i "/^\[${sec}\]/,/^\[/d" ${clashtool_config_path}
}

# 自动创建clash目录和相关配置文件
function autoecreate () {
    # 创建clash目录
    if [[ ! -d "${clash_catalog}" ]]; then
		mkdir -p ${clash_catalog}
	fi
    # 创建clash备份目录
    if [[ ! -d "${clash_catalog}/backup" ]]; then
		mkdir ${clash_catalog}/backup
	fi
	# 创建配置目录
    if [[ ! -d "${config_catalog}" ]]; then
		mkdir -p ${config_catalog}
	fi
	# 创建subscribe配置目录
    if [[ ! -d "${subscribe_config_catalog}" ]]; then
		mkdir  ${subscribe_config_catalog}
	fi
   # 创建subscribe配置备份目录
    if [[ ! -d "${subscribe_config_catalog}/backup" ]]; then
		mkdir ${subscribe_config_catalog}/backup
	fi
	# 创建clashtool和订阅配置文件
	if [[ ! -f "${clashtool_config_path}" ]]; then
        echo -e "[clashtool]\nui=dashboard\nconfig=default\nversion=v0.0.0\npid=\n\n[subscribe]\nnames=\nuse=" > ${clashtool_config_path}
	fi
    # 创建默认clash配置文件
    if [[ ! -f "${config_path}" ]]; then
        echo -e "port: 7890\nsocks-port: 7891\nallow-lan: true\nmode: Rule\nlog-level: error\nexternal-controller: 0.0.0.0:9090\nsecret: 12123" >> ${config_path}
	fi
}

# 如果记录状态为运行则启动
function autostart(){
    if [[ -n "$state" ]]; then
        start $1
    fi
}

# 如果记录状态为运行则重新启动
function autorestart(){
    if [[ -n "$state" ]]; then
        restart $1
     fi
}

# 如果记录状态为运行则重载配置
function autoreload(){
    if [[ -n "$state" ]]; then
        reload $1
    fi
}

# 帮助
function myhepl(){
	echo "fun                                     var"
	echo "install               (version) default'' Install the latest version"
	echo "install_ui            (dashboard or yacd) default'' Install dashboard UI"          
	echo "uninstall             (not var)"     
	echo "uninstall_ui          (not var)"
	echo "update                (not var)"
	echo "update_ui             (dashboard or yacd) default '' Install the currently installed UI"  
	echo "start                 (Subscription Name) defaul '' Current configuration"
	echo "stop                  (not var)"
	echo "restart               (Subscription Name) default'' Current configuration"
	echo "reload                (Subscription Name) default'' Current configuration"
    echo "add                   (*subscribe) name::url::date::0/1"
	echo "del                   (*Subscription Name)"
	echo "update_sub                   (Subscription Name) default'' Download all subscriptions"
	echo "list                  (not var)"
	echo "auto_start            (*true/false)"
	echo "auto_auto_sub         (not var)"

}

# 安装clash
function install(){
    local version=$1
    # 判断是否已经安装clash
    if [[ -f "${clash_path}" ]]; then
        echo "Clash installed"
	else
        echo "Start installing clash"
        # 没有指定版本则更新最新版本
        if [[ -z "${version}" ]];then
            # 获取clash最新版本号
            version=$(curl -k -s https://api.github.com/repos/Dreamacro/clash/releases/latest | sed 's/[\" ,]//g' | grep '^tag_name' | awk -F ':' '{print $2}')
            if [[ -z "${version}" ]]; then 
                echo "获取版本失败"
                exit 1
            fi            
        fi
        # 下载clash
        echo "version: ${version}"
        wget -O ${clash_catalog}/${platform}-${version}.gz https://github.com/Dreamacro/clash/releases/download/${version}/${platform}-${version}.gz
        if [[ -f ${clash_catalog}/${platform}-${version}.gz ]]; then
            # 解压clash
            gunzip -f ${clash_catalog}/${platform}-${version}.gz
            # 重命名clash
            mv ${clash_catalog}/${platform}-${version} ${clash_path}
            # 赋予运行权限
            chmod 755 ${clash_path}
            # 向clash配置文件写入当前版本
	        set_clashtool_config 'version' "${version}"
            echo "install clash succeeded"
        else
            echo "Download failed"
        fi
	fi
}

# 卸载clash
function uninstall(){
    # 删除clash
	if [[ -f "${clash_path}" ]]; then 
        # 停止clash运行
        stop
        # 删除clash程序文件
        rm -rf ${clash_path}
    fi
    echo "Uninstall succeeded"
}

# 更新clash
function update(){
    local version=$1
    if [[ ! -f "${clash_path}" ]]; then
        echo "Clash not installed"
    else
        # 获取当前版本
	    local current=$(get_clashtool_config 'version')
        # 没有指定版本则更新最新版本
        if [[ -z "${version}" ]];then
            # 获取clash最新版本号
            version=$(curl -k -s https://api.github.com/repos/Dreamacro/clash/releases/latest | sed 's/[\" ,]//g' | grep '^tag_name' | awk -F ':' '{print $2}')
            if [[ -z "${version}" ]]; then 
                echo "Failed to get the latest version"
                exit 1
            fi            
        fi
        echo "Current version: ${current}"
	    echo "Update  version: ${version}"
        # 判断版本是否相等
        if [[ "${current}" == "${version}" ]]; then
            echo "No update required"   
        else
            echo "Updating..."
            # 下载文件
            wget -O ${clash_catalog}/${platform}-${version}.gz https://github.com/Dreamacro/clash/releases/download/${version}/${platform}-${version}.gz
            if [[ -f "${clash_catalog}/${platform}-${version}.gz" ]]; then
                # 解压clash
                gunzip -f ${clash_catalog}/${platform}-${version}.gz
                # 停止clash程序
                stop
                # 备份当前版本clash
                mv ${clash_path} ${clash_catalog}/backup/clash$(date '+%Y%m%d%H%M%S')
                # 重命名clash
                mv ${clash_catalog}/${platform}-${version} ${clash_path}
                # 赋予运行权限
                chmod 755 ${clash_path}
                # 更新clashtool配置文件中版本号
	    	    set_clashtool_config 'version' "${version}"
                echo "Update succeeded"
	    	    # 根据更新前状态是否自动启动
                autostart
            else
                echo "Download failed"
            fi
        fi
    fi
}

# 安装UI
function install_ui(){
    local ui=$1
    # 判断UI是否已安装
	if [[ -d "${clash_gh_pages_catalog}" ]]; then
        echo "Clash UI installed"
	else
        # 没有指定UI 默认安装配置设置的UI
        if [[ -z "${ui}" ]]; then
	        ui=$(get_clashtool_config 'ui')
	    fi
        echo "Start install ${ui} ui"
        # 下载UI安装包
	    if [[ "${ui}" == "dashboard" ]]; then
            local ui_name="clash-dashboard-gh-pages" 
	    	wget -O ${clash_catalog}/gh-pages.zip https://codeload.github.com/Dreamacro/clash-dashboard/zip/refs/heads/gh-pages
        elif [[ "${ui}" == "yacd" ]]; then
	        local ui_name="yacd-gh-pages" 
            wget -O ${clash_catalog}/gh-pages.zip https://codeload.github.com/haishanh/yacd/zip/refs/heads/gh-pages
	    else
            echo "Command error, UI is dashboard or yacd"
	    	exit 1
	    fi 
        if [[ -f "${clash_catalog}/gh-pages.zip" ]]; then
            # 解压
            unzip -d ${clash_catalog} ${clash_catalog}/gh-pages.zip
            # 重命名
            mv ${clash_catalog}/${ui_name} ${clash_gh_pages_catalog}
            # 在配置默认配置文件中写入UI配置信息
	        if [[ -z $(grep '^external-ui:' "${config_path}")]]; then
                echo "external-ui: ${clash_gh_pages_catalog}" >> ${config_path} 
            else
                # 转义特殊字符
                local temp=$(echo "${clash_gh_pages_catalog}" | sed 's/\//\\\//g')
                sed -i "s/external-ui:/cexternal-ui: ${temp}/g" ${config_path}
            fi
            # 在clashtool配置文件中写入安装的ui名称
            set_clashtool_config 'ui' "${ui}"
            # 删除下载的临时文件
            rm -rf ${clash_catalog}/gh-pages.zip
            # 重载配置
            autorestart 
	        echo "${ui} UI Install succeeded" 
        else
            echo "Download failed"
        fi
	fi
}

# 卸载UI
function uninstall_ui(){
    echo "Start uninstalling UI"
    # 停止运行
    stop
    # 删除UI相关文件
    if [[ -d "${clash_gh_pages_catalog}" ]]; then
	    rm -rf ${clash_gh_pages_catalog}
    fi
    # 删除用户配置UI相关配置
	sed -i '/^external-ui: /d' ${config_path}
    # 根据前状态判断是否自动重载配置
    autoreload
	echo "uninstall UI succeeded"
}

# 更新UI
function update_ui(){
    local ui=$1
    # 判断UI是否安装
    if [[ -d "${clash_gh_pages_catalog}" ]]; then
        echo "Start UI Update"
        # 没有指定UI则默认更新当前使用UI
        if [[ -z "${ui}" ]]; then
            ui=$(get_clashtool_config 'ui')
        fi
        # 下载UI安装包
	    if [[ "${ui}" == "dashboard" ]]; then
            ui="clash-dashboard-gh-pages" 
	    	wget -O ${clash_catalog}/gh-pages.zip https://github.com/Dreamacro/clash-dashboard/refs/heads/gh-pages.zip
        elif [[ "${ui}" == "yacd" ]]; then
	        ui="yacd-gh-pages" 
            wget -O ${clash_catalog}/gh-pages.zip https://github.com/haishanh/yacd/archive/refs/heads/gh-pages.zip
	    else
            echo "Command error, UI is dashboard or yacd"
	    	exit 1
	    fi 
        # 删除当前已安装UI
        rm -rf ${clash_gh_pages_catalog}
        # 解压
        unzip -d ${clash_catalog} ${clash_catalog}/gh-pages.zip
        # 重命名
        mv ${clash_catalog}/${ui} ${clash_gh_pages_catalog}
        # 在clashtool配置文件中写入ui
        set_clashtool_config 'ui' "${ui}"
        # 重载配置
        autoreload
        echo "UI updated successfully"
    else
        echo "UI not installed"
    fi
}

function uninstall_all(){
    echo "Start Uninstall"
    stop
    if [[ -d "${config_catalog}" ]]; then
        rm -rf $config_catalog
    fi
    if [[ -d "${clash_catalog}" ]]; then
        rm -rf ${clash_catalog}
    fi
    echo "uninstall successfully"
}

# 启动clash
function start (){
    if [[ -z "${state}" ]]; then
        echo "start start"
        if [[ -f "${clash_path}" ]];then
            # 启动clash
            nohup ${clash_path} > ${config_catalog}/clash.log 2>&1 &
            state="$!"
            # 写入clash PID
            set_clashtool_config 'pid' "${state}"
            echo 'Starting...'
            sleep 10
            # 载入配置
            reload "$1"
            echo "start ok"
        else
            echo "Clash Program path not installed or specified"
        fi
    else
        echo "Program already running"
    fi  
}

# 停止clash
function stop (){
    # 判断程序是否运行
    if [[ -n "${state}" ]]; then
        # 判断PID文件是否存在
        local pid=$(get_clashtool_config 'pid')
        if [[ -n "${pid}" ]]; then 
            # 根据clash PID 结束Clash
            kill -9 "${pid}"
            echo "Stop succeeded"
        else
            echo "Please use this script to start the clash"
        fi
    else
        echo "not running"
    fi
}

# 重启clash
function restart (){
    stop
    start $1
    echo "restart succeeded"
}

# 重载clash配置文件
function reload (){
    local name=$1
    if [[ -z "$state" ]];then
        echo "Clash not running"
        exit 1
    fi
    # 是否指定订阅配置
    if [[ -z "${name}" ]]; then
        # 当前使用订阅配置
        name=$(get_subscribe_config '' 'use')
    elif [[ $(existence_subscrib_config "${name}") -ne '0' ]]; then
        # 不存在该订阅配置
        echo "The subscription could not be found"
        exit 1 
    else
        # 修改启用配置文件名
        set_subscribe_config '' 'use' "${name}"
    fi
    if [[ -z "${name}" ]]; then 
        # 使用默认配置
        echo "Use default configuration"
        cp ${config_path} ${config_catalog}/temp_config.yaml
    else
        # 复制出临时订阅配置
        cp ${subscribe_config_catalog}/${name}.yaml ${config_catalog}/temp_config.yaml
        # 删除临时订阅配置与config配置重合项
        IFS_old=$IFS
        IFS=$'\n'
        for line in $(cat ${config_path})
        do
            sed -i '/^'${line%: *}'/d' ${config_catalog}/temp_config.yaml
        done
        IFS=$IFS_old
    fi
    local port=$(cat ${config_path} | grep '^external-controller: ' | awk -F ':' '{print $3}' | sed "s/[\'\"]//g")
    local port=$([ -z "${port}" ] && echo "9090" || echo "${port}")
    local secret=$(cat ${config_path} | grep '^secret: ' | awk -F ': ' '{print $2}' | sed "s/[\'\"]//g")
    # 重载配置
    if [[ -z "${secret}" ]]; then
        curl -X PUT http://127.0.0.1:${port}/configs -H "Content-Type: application/json" -d "{\"path\": \"${config_catalog}/temp_config.yaml\"}"
    else
        curl -X PUT http://127.0.0.1:${port}/configs -H "Content-Type: application/json" -H "Authorization: Bearer ${secret}" -d "{\"path\": \"${config_catalog}/temp_config.yaml\"}"
    fi
    echo "reload succeeded"
}

# 显示当所有订阅
function list(){
    echo "0/1::name::url::date::0/1"
    IFS_old=$IFS
    IFS=$','
    local names=$(get_subscribe_config '' 'names')
    names=${names/%,}
    for name in ${names}
    do
        local url=$(get_subscribe_config "${name}" "url")
        local interval=$(get_subscribe_config "${name}" "interval")
        local update=$(get_subscribe_config "${name}" "update")
        echo "      ${name}"
        echo "====================="
        echo "url: ${url}"
        echo "interval: ${interval}"
        echo "update: ${update}"
        echo "====================="
    done
    IFS=$IFS_old
}

# 添加订阅
function add(){
    local input=$1
    local name=$(echo ${input} | awk -F '::' '{print $1}')
    local url=$(echo ${input} | awk -F '::' '{print $2}')
    local interval=$(echo ${input} | awk -F '::' '{print $3}')
    local update=$(echo ${input} | awk -F '::' '{print $4}')
    if [[ -z ${name} || -z ${url} || -z ${interval} || -z ${update} ]]; then
        echo "Parameter format error. Configuration name::Subscription address::Auto subscription time (hour)::Auto subscription (true/false)"
        exit 1
    fi
    local exis=$(existence_subscrib_config ${name})
    if [[ ${exis} -ne '0' ]]; then 
         # 创建配置
        create_subscrib_config "${name}" "${url}" "${interval}" "${update}"
        # 更改 subscrib name 名称
        local names=$(get_subscribe_config '' 'names')${name}','
        set_subscribe_config '' 'names' "${names}"
        echo "Add subscribe succeeded"
    else
        # 更新配置
        set_subscribe_config "${name}" 'url' "${url}"
        set_subscribe_config "${name}" 'interval' "${interval}"
        set_subscribe_config "${name}" 'update' "${update}"
    fi
    # 下载配置
    download_sub "${name}" 
}

# 删除订阅
function del(){
    local name=$1
    local exis=$(existence_subscrib_config "${name}")
    if [[ ${exis} -ne 0 ]]; then
        echo "The subscription was not found"
    else
        # 删除配置
        del_subscribe_config "${name}"
        # 删除配置列表
        sed -i "s/${name},//g" ${clashtool_config_path}
        # 删除定时更新
        crontab -l > ${config_catalog}/temp_crontab
        sed -i "/clashtool.sh update_sub ${name} >>/d" ${config_catalog}/temp_crontab
        crontab ${config_catalog}/temp_crontab
        rm -f ${config_catalog}/temp_crontab
        # 删除下载配置文件
        if [[ -f "${subscribe_config_catalog}/${name}.yaml" ]];then 
            rm ${subscribe_config_catalog}/${name}.yaml
        fi
        echo "Delete subscription succeeded"
    fi
}

# 更新订阅
function update_sub(){
    local name=$1
    # 是否更新所有订阅
    if [[ "${name}" == "all" ]]; then
        # 更新所有订阅配置
        IFS_old=$IFS
        IFS=$','
    local names=$(get_subscribe_config '' 'names')
    names=${names/%,}
    for name in ${names}
        do
            download_sub "${name}"
        done
        IFS=$IFS_old
    else
        local use=$(get_subscribe_config '' 'use') 
        # 更新当前使用配置
        if [[ -z "${name}" ]];then
            download_sub "${use}"
            autoreload
        else
            # 更新指定订阅配置
            exis=$(existence_subscrib_config "${name}")
            if [[ ${exis} == '0' ]]; then
                download_sub "${name}"
                if [[ ${use} == ${name} ]]; then
                    autoreload
                fi
                echo "update subscribe ok" 
            else
                echo "No such subscription"
            fi
        fi
    fi
}

# 下载订阅配置
function download_sub(){
    local name=$1
    local url=$(get_subscribe_config "${name}" "url")
    echo "start dowload: ${name}.conf"
    wget -O ${subscribe_config_catalog}/${name}.new.yaml ${url}
    if [[ -f "${subscribe_config_catalog}/${name}.yaml" ]]; then
        mv ${subscribe_config_catalog}/${name}.yaml ${subscribe_config_catalog}/backup/${name}.yaml$(date '+%Y%m%d%H%M%S')
    fi
    mv ${subscribe_config_catalog}/${name}.new.yaml ${subscribe_config_catalog}/${name}.yaml
    echo "download ok"
}

# 根据配置生成定时任务文件
function auto_sub(){
    IFS_old=$IFS
    IFS=$','
    # 复制原定时任务
    crontab -l > ${config_catalog}/temp_crontab
    local names=$(get_subscribe_config '' 'names')
    names=${names/%,}
    for name in ${names}
    do  
        local patt="clashtool.sh update_sub ${name}"
        # 查看任务中是否有此任务
        if [[ -n $(grep "${patt}" ${config_catalog}/temp_crontab) ]]; then
            # 有则删除
            sed -i "/${patt}/d" ${config_catalog}/temp_crontab
        fi
        local update=$(get_subscribe_config "${name}" "update")
        # 查看是否启用自动更新订阅
        if [[ "${update}" == 'true' ]]; then
            # 添加定时任务
            local interval=$(get_subscribe_config "${name}" 'interval')
            echo "0 */${interval} * * * sh ${tool_catalog}/${patt} >> ${config_catalog}/crontab.log 2>&1" >> ${config_catalog}/temp_crontab
        fi
    done
    IFS=$IFS_old
    # 启动定时任务
    crontab ${config_catalog}/temp_crontab
    # 删除临时定时任务
    rm -f ${config_catalog}/temp_crontab
    echo "Scheduled update is enabled" 
}

# 设置自动启动（由于各linux系统环境差异原因暂无法使用）
function auto_start(){
    local start=$1
    crontab -l > ${config_catalog}/temp_crontab
    if [[ ${start} == "true" ]]; then
        if [[ -z $(cat ${config_catalog}/temp_crontab | grep '/clashtool.sh start&') ]]; then
            echo "@reboot sh ${tool_catalog}/clashtool.sh start" >> ${config_catalog}/temp_crontab
        fi
        echo "Auto start enabled"
    elif [[ "${start}" == "false" ]]; then
        sed -i "/clashtool.sh start/d" ${config_catalog}/temp_crontab
        echo "Auto start is off"
    else
        echo "instructions error , true\false"
        exit 1
    fi
    crontab ${config_catalog}/temp_crontab
    rm -f ${config_catalog}/temp_crontab
}

function main(){
    local fun=$1
    local var=$2
    # 检查配置配置文件和目录是否缺失，如果缺失则创建
    if [[ -n "${fun}" ]]; then
        if [[ -z $(echo ${fun} | grep "^uninstall") ]]; then
            autoecreate
        fi
    fi
    case "${fun}" in
        "install")
            install ${var}
            ;;
        "install_ui")
            install_ui ${var}
            ;;
        "uninstall")
            uninstall
            ;;
        "uninstall_ui")
            uninstall_ui
            ;;
        "update")
            update ${var}
            ;;
        "update_ui")
            update_ui ${var}
            ;;
        "uninstall_all")
            uninstall_all
            ;;
        "start")
            start ${var}
            ;;
        "stop")
            stop
            ;;
        "restart")
            restart ${var}
            ;;
        "reload")
            reload ${var}
            ;;
        "add")
            add ${var}
            ;;
        "del")
            del ${var}
            ;;
        "update_sub")
            update_sub ${var}
            ;;
        "list")
            list
            ;;
        "auto_start")
            auto_start ${var}
            ;;
        "auto_sub")
            auto_sub ${var}
            ;;
        *)
            myhepl
    esac
}

main $@
