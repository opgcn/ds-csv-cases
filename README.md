# dscsv

东方明珠的数据中台的[离线文件接入](http://dsftp.opg.cn)、[实时数据流接入](https://gitlab.opg.cn/snippets/21)都要求数据**满足[CSV](https://baike.baidu.com/item/CSV/10739)格式，即遵循国际标准[RFC4180](https://tools.ietf.org/html/rfc4180)**。同时，数据中台离线数据导出给业务线时也是*CSV*格式。

由于业务线的研发能力参差不齐，不少数据对接业务线期望期望能用最小的开发成本来编解码这些*CSV*数据文件。此项目应运而生，它通过*控制器调度任务脚本*的模式，**支持业务侧快速的定制化实施自己的CSV编解码逻辑**，开发人员只需要具备简单的*Shell*脚本开发能力即可。

## 1. 基本概念

**任务**，指一个由业务线开发的shell脚本，其中通过[csvkit](https://csvkit.readthedocs.io/)、[jq](https://stedolan.github.io/jq/)等开源工具，实现业务线自己的*CSV*数据编解码逻辑。此任务在*控制器*中被执行，并配合[dsftp-client](https://github.com/opgcn/dsftp-client)等*传输工具*，接入或导出数据中台。每个任务可以是有始有终的批量处理，也可以是有始无终的管道处理。

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

每个*任务*都有一个唯一的ID，用于完成特定的*CSV*编解码和数据文件搬家任务。每个*任务*的实现位于`tasks/${TASK_ID}`。

数据中台在此项目中实现了大量任务示例，覆盖大量实际数据接入/导出需求，业务侧技术人员可以阅读`tasks/`目录下的官方任务，了解任务的一般撰写方式，然后编写自己所需的任务。

## 4. 任务的执行

执行任务时，只需要`./ctl.sh ${TASK_ID}`即可，控制器会完成任务调度、日志处理等功能。
