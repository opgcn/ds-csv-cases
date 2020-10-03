# https://github.com/opgcn/dscsv
# 这是一个官方示例任务。
# 它将mysql表导出到CSV，并打包成gzip，存放到指定目录中。后续使用'dsftp-client'等工具异步同步到DSFTP，从而实现业务线数据表离线方式接入数据中台。
# 此任务需要提前安装以下依赖：
# sudo yum install -y python3
# pip3 install --user PyMySQL
# pip3 install --user csvkit

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 全局配置

# 任务ID, 必须固定为脚本文件名
TASK_ID=$(basename $BASH_SOURCE)

# 业务侧数据库配置, 安全起见应该创建一个只读用户
TASK_MYSQL_HOST='some-mysql-instance.rwlb.rds.aliyuncs.com'
TASK_MYSQL_PORT='3306'
TASK_MYSQL_USER='some_read_only_user'
TASK_MYSQL_PASS='some_alnum_password'
TASK_MYSQL_CONN="mysql+pymysql://${TASK_MYSQL_USER}:${TASK_MYSQL_PASS}@${TASK_MYSQL_HOST}:${TASK_MYSQL_PORT}/?charset=utf8mb4" # https://docs.sqlalchemy.org/en/13/dialects/mysql.html

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 多个数据类型的处理过程

# 数据类型 biz_test_demo
# 示例数据表：
#   CREATE TABLE `t_demo` (`f1` tinytext,`f2` tinytext,`f3` tinytext,`f4` tinytext,`f5` tinytext) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
#   INSERT INTO `t_demo` VALUES ('19','Tom','x,y','yes','6.2'),(',','Jack','a,b\"','','-3.2'),('19,99','\"Chevy\"','3\t2',' ','普通话');
function biz_test_demo
{
    # 数据导出的数据类型1的配置
    TASK_TYPE=$FUNCNAME # 数据类型的ID，作为导出数据的子目录名称
    TASK_TYPE_SQL='select * from ds_test.t_demo' # 检索数据的SQL语句
    TASK_TYPE_DIR_WORK=$DIR_HOME/$TASK_ID/work/$TASK_TYPE # 该数据类型的中间工作目录
    TASK_TYPE_DIR_OUT=$DIR_HOME/$TASK_ID/out/$TASK_TYPE # 该数据类型的最终输出目录，可配置成DSFTP挂载目录或镜像同步目录的数据类型子目录
    TASK_TYPE_FILE_PREFIX=$(date -Iseconds) # 数据生成ISO8601格式的时间戳作为文件名前缀, 按需要生成
    TASK_TYPE_PATH_CSVGZ=$TASK_TYPE_DIR_WORK/$TASK_TYPE_FILE_PREFIX.csv.gz # 工作目录的.csv.gz文件路径
    TASK_TYPE_PATH_MD5=$TASK_TYPE_PATH_CSVGZ.md5 # 工作目录的.csv.gz.md5文件路径
    
    # 工作目录中处理
    runCmd mkdir -p $TASK_TYPE_DIR_WORK || return $?
    echoDebug INFO "开始生成 $TASK_TYPE_PATH_CSVGZ"
    sql2csv -v -H --db "$TASK_MYSQL_CONN" --query "$TASK_TYPE_SQL" | gzip -9 > $TASK_TYPE_PATH_CSVGZ || return $?
    echoDebug INFO "生成文件字节大小: $(stat -c%s $TASK_TYPE_PATH_CSVGZ)"
    echoDebug INFO "生成文件的MD5: $(md5sum $TASK_TYPE_PATH_CSVGZ | cut -d' ' -f1 | tee $TASK_TYPE_PATH_MD5)"

    # 日志中显示统计信息，性能较差时可以注释掉
    # echoDebug INFO "产出CSV文件的详细统计信息如下" && runCmd csvstat -v -H $TASK_TYPE_PATH_CSVGZ

    # 数据移动到输出目录
    runCmd mkdir -p $TASK_TYPE_DIR_OUT || return $?
    runCmd mv -f $TASK_TYPE_PATH_CSVGZ* $TASK_TYPE_DIR_OUT/ || return $?
    
    # 查看输出的.csv.gz文件可以采用下面的方法：
    # gunzip --stdout xxx.csv.gz
    # zcat xxx.csv.gz
    # csvlook -H xxx.csv.gz | less -S
}

# 数据类型 biz_test_other
function biz_test_other
{
    :
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 主过程

echoDebug INFO "任务 $TASK_ID 执行开始"

TASK_TYPES=( biz_test_demo biz_test_other )
declare -i TASK_TYPE_COUNT=0
declare -i TASK_TYPE_FAIL=0

for eachType in ${TASK_TYPES[@]}; do
    TASK_TYPE_COUNT+=1
    echoDebug INFO "开始处理第 $TASK_TYPE_COUNT 个数据类型: $eachType"
    $eachType || { echoDebug ERROR "数据类型 $eachType 处理失败! 返回码: $?"; TASK_TYPE_FAIL+=1; }
done

echoDebug INFO "任务 $TASK_ID 执行完毕, 数据类型失败 $TASK_TYPE_FAIL/${#TASK_TYPES[@]} 个"
exit $TASK_TYPE_FAIL
