# https://github.com/opgcn/dscsv
# 这是一个官方示例任务。
# 它将通过DSFTP同步到本地的.csv.gz文件，解压成,csv，存放到指定目录中，然后通过SMTP协议发送指定邮箱
# 此任务需要提前安装以下依赖：
# sudo yum install -y python3
# sudo yum install -y mailx # 除了mailx，同时推荐命令行发SMTP邮件的神器swaks
# pip3 install --user csvkit

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 全局配置

# 任务ID, 必须固定为脚本文件名
TASK_ID=$(basename $BASH_SOURCE)
TASK_SMTP_HOST='smtp.partner.outlook.cn:587'
TASK_SMTP_USER='发信账号@opg.cn'
TASK_SMTP_PASS='发信账号密码'
TASK_SMTP_TO=('收件人1@opg.cn' '收件人2@opg.cn')

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 多个数据类型的处理过程

# 数据类型 biz_csv_to_mail
function biz_csv_to_mail
{    
    # 数据导出的数据类型1的配置
    TASK_TYPE=$FUNCNAME # 数据类型的ID，作为导出数据的子目录名称
    TASK_TYPE_DIR_IN=$DIR_HOME/$TASK_ID/in/$TASK_TYPE # 服务器上可以获取该数据的目录
    TASK_TYPE_DIR_WORK=$DIR_HOME/$TASK_ID/work/$TASK_TYPE # 该数据类型的中间工作目录
    TASK_TYPE_FILE_PREFIX=$(date -Idate) # 数据生成ISO8601格式的时间戳作为文件名前缀, 按需要生成
    TASK_TYPE_PATH_CSVGZ=$TASK_TYPE_DIR_IN/$TASK_TYPE_FILE_PREFIX.csv.gz # 输入目录的.csv.gz文件路径
    TASK_TYPE_PATH_CSV=$TASK_TYPE_DIR_WORK/$TASK_TYPE_FILE_PREFIX.csv # 工作目录的.csv文件路径
    
    # mock输入数据
    runCmd mkdir -p $TASK_TYPE_DIR_IN || return $?
    curl -L https://raw.githubusercontent.com/wireservice/csvkit/master/examples/realdata/ne_1033_data.xlsx | in2csv -v -f xlsx | gzip -9 -c > $TASK_TYPE_PATH_CSVGZ || return 0
    
    # 工作目录中处理
    runCmd mkdir -p $TASK_TYPE_DIR_WORK || return $?
    echoDebug INFO "开始生成 $TASK_TYPE_PATH_CSV"
    runCmd gzip -dc $TASK_TYPE_PATH_CSVGZ > $TASK_TYPE_PATH_CSV || return $?
    echoDebug INFO "生成文件字节大小: $(stat -c%s $TASK_TYPE_PATH_CSV)"
    
    # 邮件
    echo "由数据中台导出的 $TASK_TYPE_PATH_CSVGZ 数据统计信息如下：" > $TASK_TYPE_PATH_CSV.stat
    runCmd csvstat -v $TASK_TYPE_PATH_CSV >> $TASK_TYPE_PATH_CSV.stat
    runCmd mailx -n -v -r $TASK_SMTP_USER -s "$TASK_ID@$(hostname -I|cut -d' ' -f1)" -S smtp="$TASK_SMTP_HOST" -S smtp-auth-user="$TASK_SMTP_USER" -S smtp-auth-password="$TASK_SMTP_PASS" -S smtp-use-starttls -S smtp-auth=login -S ssl-verify=ignore -S nss-config-dir=/etc/pki/nssdb -a $TASK_TYPE_PATH_CSV ${TASK_SMTP_TO[@]} < $TASK_TYPE_PATH_CSV.stat
    
    # 日志中显示统计信息，性能较差时可以注释掉
    # echoDebug INFO "产出CSV文件的详细统计信息如下" && runCmd csvstat -v -H $TASK_TYPE_PATH_CSVGZ
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 主过程

echoDebug INFO "任务 $TASK_ID 执行开始"

TASK_TYPES=( biz_csv_to_mail )
declare -i TASK_TYPE_COUNT=0
declare -i TASK_TYPE_FAIL=0

for eachType in ${TASK_TYPES[@]}; do
    TASK_TYPE_COUNT+=1
    echoDebug INFO "开始处理第 $TASK_TYPE_COUNT 个数据类型: $eachType"
    $eachType || { echoDebug ERROR "数据类型 $eachType 处理失败! 返回码: $?"; TASK_TYPE_FAIL+=1; }
done

echoDebug INFO "任务 $TASK_ID 执行完毕, 数据类型失败 $TASK_TYPE_FAIL/${#TASK_TYPES[@]} 个"
exit $TASK_TYPE_FAIL
