#!/usr/bin/env bash
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Author:   li.lei03@opg.cn
# Created:  2020-09-25
# Purpose:  DS CSV cases contollor

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# global configs

DIR_HOME=$(dirname $(realpath ${BASH_SOURCE[0]}))
DIR_CASES=$DIR_HOME/cases
DIR_WORKSHOP=$DIR_HOME/workshop
DIR_INPUT=$DIR_HOME/input
DIR_OUTPUT=$DIR_HOME/output
DIR_LOGS=$DIR_HOME/logs

IS_LOGGING=1
FILE_THIS=$(basename ${BASH_SOURCE[0]})

PATH_LOGROTATE_CONF=$DIR_LOGS/logrotate.conf
PATH_LOGROTATE_STATE=$DIR_LOGS/logrotate.state
TPL_LOGROTATE="# 此配置文件由 $(realpath ${BASH_SOURCE[0]}) 自动更新
$DIR_LOGS/*.log {
    daily
    rotate 30
    notifempty
    missingok
    dateext
    dateyesterday
    copytruncate
    compress
    compresscmd $(which xz)
    uncompresscmd $(which unxz)
    compressext .xz
    compressoptions -9
}"

TPL_BG_NOHUP="CASEID=用例名称 && nohup bash -l $(realpath ${BASH_SOURCE[0]}) \$CASEID >> $DIR_LOGS/\$CASEID.log 2>&1 &"

TPL_BG="
# 命令行后台进程方式启动案例
$TPL_BG_NOHUP

# 开机自启后台进程，在crontab -e中加入
@reboot $TPL_BG_NOHUP

# 每天日志轮转，在crontab -e中加入
@daily bash -l $(realpath ${BASH_SOURCE[0]}) logrotate >> $DIR_LOGS/logrotate.journal 2>&1
"

HELP="$FILE_THIS - 数据中台CSV编解码范例控制器 https://github.com/opgcn/ds-csv-cases

用法:
    {CASEID}    前台运行案例 $DIR_CASES/{CASEID}.sh
    bg          显示后台运行的案例的方法
    logrotate   轮转压缩${DIR_LOGS}目录中的日志
    help        显示此帮助
    
案例ID列表:
$(for x in $(ls -S cases/case-*.sh); do echo "    $(basename -s .sh $x)"; done)
"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# common functions

function echoDebug
# echo debug message
#   $1: debug level
#   $2: message string
{
    sPos=""
    for x in ${FUNCNAME[@]}; do
        [ "echoDebug" != "$x" ] && [ "runCmd" != "$x" ] && sPos="${sPos}${x}@"
    done
    if [ 1 -eq ${IS_LOGGING} ]; then
        echo -e "\e[7;93m[${sPos}${FILE_THIS} $(date +'%F %T') $1]\e[0m \e[93m$2\e[0m" >&2
    fi
}

function runCmd
{
    echoDebug DEBUG "命令: $*"
    $@
    nRet=$?; [ 0 -eq $nRet ] || echoDebug WARN "命令返回非零值: $nRet"
    return $nRet
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# process functions

function parseOpts
{
    declare sOpt="$1"
    if [ "$sOpt" == "help" ] || [ "$sOpt" == '' ]; then
        echo "$HELP"
    elif [ "$sOpt" == "bg" ]; then
        mkdir -p $DIR_LOGS \
        && echo "$TPL_BG"
    elif [ "$sOpt" == "logrotate" ]; then
        mkdir -p $DIR_LOGS \
        && echo "$TPL_LOGROTATE" > $PATH_LOGROTATE_CONF \
        && runCmd logrotate -v -s $PATH_LOGROTATE_STATE $PATH_LOGROTATE_CONF
    elif [[ $sOpt == case-* ]]; then
        runCmd source $DIR_CASES/$sOpt.sh
    else
        echoDebug ERROR "非法参数'$sOpt'! 请使用'$FILE_THIS help'查看帮助"
        return 1
    fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# main process
parseOpts $@
