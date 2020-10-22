# dscsv

东方明珠的数据中台的[离线文件接入规范](http://dsftp.opg.cn)要求数据**满足[CSV](https://baike.baidu.com/item/CSV/10739)格式**，即遵循国际标准[RFC4180](https://tools.ietf.org/html/rfc4180)。不少业务线期望期望能用最小的开发成本来编解码这些*CSV*数据文件。此项目应运而生，它通过*控制器调度任务脚本*的模式，**支持业务侧快速的定制化实施自己的CSV编解码逻辑，开发人员只需要具备简单的*Shell*脚本开发能力即可。**

## 1. 安装和配置

建议业务侧在部署服务器（建议*CentOS 7.x*）上先安装好依赖的开源工具:
```bash
sudo yum install -y python3 jq
pip3 install --user PyMySQL csvkit
[ "root" == "$USER" ] && ln -sf $HOME/.local/bin $HOME/bin || true
```

安装此项目，查看*控制器*（类似`kubectl`、`systemctl`等命令行操作中心）的命令行帮助:
```bash
git clone https://github.com/opgcn/dscsv.git
cd dscsv/
chmod a+x ./ctl.sh
./ctl.sh help
```

## 2. 查看和编写任务

**任务**，指一个由业务线开发和维护的脚本程序，其通过[csvkit](https://csvkit.readthedocs.io/)、[jq](https://stedolan.github.io/jq/)等开源工具，实现业务线自己的*CSV*数据编解码逻辑，此任务在*控制器*中被加载执行。每个任务可以是有始有终的批量处理，也可以是有始无终的管道处理。

每个*任务*都有一个唯一的ID，用于完成特定的*CSV*编解码和数据文件搬家任务。每个*任务*的实现位于`tasks/${TASK_ID}`。数据中台在此项目中实现了大量示例任务，覆盖各种实际数据接入/导出需求，业务侧技术人员可以阅读`tasks/`目录下的官方任务，了解任务的一般撰写方式，然后编写自己所需的任务。

示例任务ID | 说明
---- | ----
`eg-json-to-csv.sh` | 将JSON文件导出到CSV
`eg-excel-to-csv.sh` | 将Excel表导出到CSV
`eg-nginxlog-to-csv.sh` | 将nginx的归档日志文件导出到CSV
`eg-mysql-to-csv.sh` | 将mysql表导出到CSV
`eg-csv-to-mail.sh` | 将CSV文件转换成excel并邮寄
`eg-api-to-csv.sh` | 访问API接口并导出到CSV

同时，建议业务线对接数据的技术人员了解命令行开源工具[csvkit](https://csvkit.readthedocs.io/)、[jq](https://stedolan.github.io/jq/)的基本使用。

## 3. 任务的执行

执行任务时，只需要`./ctl.sh ${TASK_ID}`即可，控制器会完成任务调度、日志处理等功能。详细信息参考`./ctl.sh help`提示。

## 4. 常见问题：

> 这个*dscsv*工具怎么把生成的*CSV*数据文件上传给数据中台？

*dscsv*用以解决**数据编解码问题**，对于**数据文件传输**问题可参考[dsftp-client](https://github.com/opgcn/dsftp-client)或自行实现。

> 子任务较为复杂，需要传参时怎么办？

如果通过框架调用如`./ctl.sh task-id.sh arg_a arg_b arg_c`，在`task.sh`中`arg_a arg_b arg_c`是新的`$@`。这个做法很实用，例如业务线可以取命令行参数`$1`作为取数的日期，日后发现任务失败时，可以通过传参来重新跑那天的任务。

> 我是你们数据中台一个业务线，要上传多个*数据类型*的离线文件，我是把多个数据类型放在一个*任务*里，还是分成多个好？

如果各个*数据类型*生产时效性一致，*Crontab*调度策略也一样，可以考虑放在一个*任务*内，否则放多个*任务*脚本；开发工作量是相似的，但都很简单。

> 我们子公司有牛逼的专业开发能力，不打算用你们这个很low的Shell脚本方式开发离线CSV数据上传，你们总部中台怎么看？

开发语言无谓贵贱，大多数业务线和数据中台对接时，都是业务线的运维兄弟顶在一线，他们很辛苦，所以此项目采用*Shell*作为二次开发语言，方便他们。如果业务线采用其它语言自行开发，建议将*CSV生成模块*和*文件传输模块*解耦开来，这样出现Bug的时候方便定位和修复，方便运维的兄弟处理故障。


