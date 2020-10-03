#!/usr/bin/env bash
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Author:   li.lei03@opg.cn
# Created:  2020-09-25
# Purpose:  DS CSV tasks contollor

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# global configs

DIR_HOME=$(dirname $(realpath ${BASH_SOURCE[0]}))
DIR_TASKS=$DIR_HOME/tasks

IS_LOGGING=1

DIR_LOGS=$DIR_HOME/logs
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
    compres1ions -9
}"

TPL_BG_NOHUP="TASK_ID=任务名称 && nohup bash -l $(realpath ${BASH_SOURCE[0]}) \$TASK_ID >> $DIR_LOGS/\$TASK_ID.log 2>&1 &"

TPL_BG="
# 命令行后台进程方式启动任务
$TPL_BG_NOHUP

# 开机自启后台进程，在crontab -e中加入
@reboot $TPL_BG_NOHUP

# 每天日志轮转，在crontab -e中加入
@daily bash -l $(realpath ${BASH_SOURCE[0]}) logrotate >> $DIR_LOGS/logrotate.journal 2>&1
"

HELP="$(basename $BASH_SOURCE) - CSV编解码任务控制器 https://github.com/opgcn/dscsv

用法:
    {TASK_ID}   前台运行任务 $DIR_TASKS/{TASK_ID}
    bg          显示后台运行的任务的方法
    logrotate   轮转压缩${DIR_LOGS}目录中的日志
    help        显示此帮助
    
任务ID列表:
$(for x in $(ls -S tasks/*); do echo "    $(basename $x)"; done)
"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# common functions

function echoDebug
# echo debug message
#   $1: debug level
#   $2: message string
{
    if [ 1 -eq ${IS_LOGGING} ]; then
        sPos=${TASK_ID:-$(basename -s .sh $BASH_SOURCE)}
        echo -e "\e[7;93m$(date +'%F %T') $1 ${sPos}\e[0m \e[93m$2\e[0m" >&2
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
# main process

if [ "$1" == "help" ] || [ "$1" == '' ]; then
    echo "$HELP"
elif [ "$1" == "bg" ]; then
    mkdir -p $DIR_LOGS \
    && echo "$TPL_BG"
elif [ "$1" == "logrotate" ]; then
    mkdir -p $DIR_LOGS \
    && echo "$TPL_LOGROTATE" > $PATH_LOGROTATE_CONF \
    && runCmd logrotate -v -s $PATH_LOGROTATE_STATE $PATH_LOGROTATE_CONF
elif [[ $1 == *.sh ]]; then
    runCmd source $DIR_TASKS/$1
elif [[ $1 == *.py ]]; then
    runCmd exec python3 $DIR_TASKS/$1
else
    echoDebug FATAL "非法参数'$1'! 请使用'$0 help'查看帮助"
    exit 1
fi
