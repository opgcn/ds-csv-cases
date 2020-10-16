# dscsv

东方明珠的数据中台的[离线文件接入](http://dsftp.opg.cn)等规范，要求数据**满足[CSV](https://baike.baidu.com/item/CSV/10739)格式，即遵循国际标准[RFC4180](https://tools.ietf.org/html/rfc4180)**。同时，数据中台*DSFTP*导出给业务线的离线数据报表也是*CSV*格式。

由于业务线的研发能力参差不齐，不少业务线期望期望能用最小的开发成本来编解码这些*CSV*数据文件。此项目应运而生，它通过*控制器调度任务脚本*的模式，**支持业务侧快速的定制化实施自己的CSV编解码逻辑**，开发人员只需要具备简单的*Shell*脚本开发能力即可。

## 1. 基本概念

**任务**，指一个由业务线开发和维护的脚本程序，其通过[csvkit](https://csvkit.readthedocs.io/)、[jq](https://stedolan.github.io/jq/)等开源工具，实现业务线自己的*CSV*数据编解码逻辑，此任务在*控制器*中被加载执行。同时，可以配合[dsftp-client](https://github.com/opgcn/dsftp-client)等*传输工具*，接入或导出数据中台。每个任务可以是有始有终的批量处理，也可以是有始无终的管道处理。

## 2. 安装

建议业务侧在部署服务器上先安装好依赖:
```bash
yum install -y python3 jq
pip3 install --user PyMySQL csvkit
```

安装此项目，查看命令行帮助:
```bash
git clone https://github.com/opgcn/dscsv.git
cd dscsv/
chmod a+x ./ctl.sh
./ctl.sh help
```

## 3. 查看和编写任务

每个*任务*都有一个唯一的ID，用于完成特定的*CSV*编解码和数据文件搬家任务。每个*任务*的实现位于`tasks/${TASK_ID}`。数据中台在此项目中实现了大量任务示例，覆盖大量实际数据接入/导出需求，业务侧技术人员可以阅读`tasks/`目录下的官方任务，了解任务的一般撰写方式，然后编写自己所需的任务。

示例任务ID | 说明
---- | ----
`eg-json-to-csv.sh` | 将JSON文件导出到CSV
`eg-excel-to-csv.sh` | 将Excel表导出到CSV
`eg-nginxlog-to-csv.sh` | 将nginx的归档日志文件导出到CSV
`eg-mysql-to-csv.sh` | 将mysql表导出到CSV
`eg-csv-to-mail.sh` | 将CSV文件转换成excel并邮寄
`eg-api-to-csv.sh` | 访问API接口并导出到CSV

同时，建议业务线对接数据的技术人员了解命令行开源工具[csvkit](https://csvkit.readthedocs.io/)、[jq](https://stedolan.github.io/jq/)的基本使用。

## 4. 任务的执行

执行任务时，只需要`./ctl.sh ${TASK_ID}`即可，控制器会完成任务调度、日志处理等功能。详细信息参考`./ctl.sh help`提示。

## 5. 常见问题：

> 子任务较为复杂，需要传参时怎么办？

如果通过框架调用如`./ctl.sh task-id.sh arg_a arg_b arg_c`，在`task.sh`中`arg_a arg_b arg_c`是新的`$@`。这个做法很实用，例如业务线可以取命令行参数`$1`作为取数的日期，日后发现任务失败时，可以通过传参来重新跑那天的任务。

> 我是你们数据中台一个业务线，要上传多个*数据类型*的离线文件，我是把多个数据类型放在一个*任务*里，还是分成多个好？

如果各个*数据类型*生产时效性一致，*Crontab*调度策略也一样，可以考虑放在一个*任务*内，否则放多个*任务*脚本；开发工作量是相似的，但都很简单。

> 我们子公司有牛逼的专业开发能力，不打算用你们这个很low的Shell脚本方式开发离线CSV数据上传，你们总部中台怎么看？

开发语言无谓贵贱，此项目是考虑大多数子公司的实际技术能力选型的。业务线自行开发时，还是建议业务线将*CSV生成模块*和*文件传输模块*解耦开来，这样出现Bug的时候方便定位和修复。


