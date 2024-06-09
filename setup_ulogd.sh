#!/bin/bash
export LANG=en_US.UTF-8

# 检查是否以root用户运行脚本
if [ "$(id -u)" -ne 0 ]; then
    echo "请使用root用户或通过sudo运行此脚本。"
    exit 1
fi

# 更新包列表并安装ulogd2
echo "更新包列表并安装ulogd2..."
apt-get update
apt-get install -y ulogd2

# 备份原始的ulogd配置文件
echo "备份原始的ulogd配置文件..."
cp /etc/ulogd.conf /etc/ulogd.conf.bak

# 配置ulogd
echo "配置ulogd..."
cat <<EOL > /etc/ulogd.conf
plugin="/usr/lib/ulogd/ulogd_inppkt_NFLOG.so"
plugin="/usr/lib/ulogd/ulogd_filter_IFINDEX.so"
plugin="/usr/lib/ulogd/ulogd_filter_IP2STR.so"
plugin="/usr/lib/ulogd/ulogd_filter_PRINTPKT.so"
plugin="/usr/lib/ulogd/ulogd_output_LOGEMU.so"

stack=log2:NFLOG,ip2str:IP2STR,printpkt:PRINTPKT,emu:LOGEMU

[emu-log1]
file="/var/log/ulogd.log"
sync=1
EOL

# 配置iptables规则以记录HTTP和HTTPS流量
echo "配置iptables规则以记录HTTP和HTTPS流量..."
iptables -A INPUT -p tcp --dport 80 -j NFLOG --nflog-prefix "HTTP_IN: "
iptables -A INPUT -p tcp --dport 443 -j NFLOG --nflog-prefix "HTTPS_IN: "
iptables -A OUTPUT -p tcp --dport 80 -j NFLOG --nflog-prefix "HTTP_OUT: "
iptables -A OUTPUT -p tcp --dport 443 -j NFLOG --nflog-prefix "HTTPS_OUT: "

# 定义文件路径变量
rule_path="/etc/iptables/rules.v4"

if [ -f "$rule_path" ]; then
    echo "文件已经存在：$rule_path"
    echo "保存iptables规则..."
    # 保存iptables规则
    iptables-save > "$rule_path"
else
    echo "文件不存在，创建文件：$rule_path"
    
    # 创建文件
    touch "$rule_path"
    
    if [ $? -eq 0 ]; then
        echo "文件创建成功"
    else
        echo "文件创建失败"
        exit 1
    fi
fi

# 重启ulogd服务
echo "重启ulogd服务..."
service ulogd2 restart

# 检查ulogd服务状态
echo "检查ulogd服务状态..."
systemctl status ulogd

# 提示完成
echo "配置完成,HTTP和HTTPS流量日志记录在/var/log/ulogd.log中。"
