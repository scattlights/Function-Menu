#!/bin/bash
export LANG=en_US.UTF-8

#!/bin/bash

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

if [ -f rules.v4 ]; then
# 保存iptables规则
	echo "保存iptables规则..."
	iptables-save > /etc/iptables/rules.v4
else 
	touch rules.v4
fi

# 重启ulogd服务
echo "重启ulogd服务..."
service ulogd2 restart

# 检查ulogd服务状态
echo "检查ulogd服务状态..."
systemctl status ulogd

# 提示完成
echo "配置完成。HTTP和HTTPS流量日志记录在/var/log/ulogd.log中。"

# 定义函数创建文件夹
create_directory() {
    local dir_path="$1"
    
    if [ ! -d "$dir_path" ]; then
        echo "创建文件夹：$dir_path"
        
        # 创建文件夹
        mkdir -p "$dir_path"
        
        if [ $? -eq 0 ]; then
            echo "创建成功"
        else
            echo "创建失败"
            exit 1
        fi
    else
        echo "文件夹已经存在：$dir_path"
    fi
}

# 定义函数创建文件
create_file() {
    local file_path="$1"
    
    if [ -f "$file_path" ]; then
        echo "文件已经存在：$file_path"
        echo "保存iptables规则..."
        # 保存iptables规则
        iptables-save > "$file_path"
    else
        echo "创建文件：$file_path"
        
        # 创建文件
        touch "$file_path"
        
        if [ $? -eq 0 ]; then
            echo "创建成功"
        else
            echo "创建失败"
            exit 1
        fi
    fi
}

# 调用创建文件夹函数
iptables_dir="/etc/iptables"
create_directory "$iptables_dir"

# 调用创建文件函数
rule_path="/etc/iptables/rules.v4"
create_file "$rule_path"

# 重启ulogd服务
echo "重启ulogd服务..."
systemctl restart ulogd2

# 等待一段时间，确保服务启动完成
sleep 5

# 检查ulogd服务状态
echo "检查ulogd服务状态..."
systemctl status ulogd2

# 提示完成
echo "配置完成,HTTP和HTTPS流量日志记录在/var/log/ulogd.log中。"
