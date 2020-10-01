# ds-csv-cases

东方明珠的数据中台的[离线文件接入](http://dsftp.opg.cn)、[实时数据流接入](https://gitlab.opg.cn/snippets/21)都要求数据**满足[CSV](https://baike.baidu.com/item/CSV/10739)格式，即遵循国际标准[RFC4180](https://tools.ietf.org/html/rfc4180)**。同时，数据中台离线数据导出给业务线时也是*CSV*格式。

由于业务线的研发能力参差不齐，不少数据对接业务线期望期望能用最小的开发成本来编解码这些*CSV*数据文件。此项目应运而生，它通过*案例插件*的引擎模式，**支持业务侧快速的定制化实施自己的CSV编解码逻辑**，开发人员只需要具备简单的*Shell*脚本开发能力即可。

## 1. 基本概念

**案例**，指一个由业务线开发的shell脚本，其中通过[csvkit](https://csvkit.readthedocs.io/)、[jq](https://stedolan.github.io/jq/)等开源工具，实现业务线自己的*CSV*数据编解码逻辑，然后在“案例调度引擎”中被执行，并配合[dsftp-client](https://github.com/opgcn/dsftp-client)等，接入或导出数据中台。

## 2. 安装

建议业务侧在部署服务器上先安装好依赖:
```bash
yum install -y python3 jq
pip3 install --user PyMySQL csvkit
```

安装此项目，查看命令行帮助:
```bash
git clone https://github.com/opgcn/ds-csv-cases.git
cd ds-csv-cases/
chmod a+x ./ctl.sh
./ctl.sh help
```

## 3. 查看和编写案例

每个*案例*都有一个唯一的ID，以`case-`作为前缀，用于完成特定的*CSV*编解码和数据文件搬家任务。每个*案例*的实现位于`cases/${CASE_ID}.sh`。

数据中台在此项目中实现了大量案例示例，覆盖大量实际数据接入/导出需求，业务侧技术人员可以先阅读各个`case-eg-`前缀的官方案例，了解案例的一般撰写方式，然后“fork”自己所需的案例。

## 4. 案例的执行

执行案例时，只需要`./ctl.sh ${CASE_ID}`即可，引擎会完成案例调度、日志处理等功能。
