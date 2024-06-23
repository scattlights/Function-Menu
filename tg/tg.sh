#!/bin/bash

TG_INFO_FILE="/myshell/tg_info.sh"
if [ ! -f "$TG_INFO_FILE" ]; then
	sudo touch "$TG_INFO_FILE"
	sudo chmod 666 "$TG_INFO_FILE"
else
	rm "$TG_INFO_FILE"
	sudo touch "$TG_INFO_FILE"
	sudo chmod 666 "$TG_INFO_FILE"
fi

sudo rm /etc/systemd/system/tg.service

# 电报机器人的API_Token
read -p "输入电报机器人API_Token:" YOUR_BOT_TOKEN
BOT_TOKEN="${YOUR_BOT_TOKEN}"
echo "BOT_TOKEN=\"$YOUR_BOT_TOKEN\"" >/myshell/tg_info.sh
# 电报机器人的Chat_ID（接收消息的用户的ID）
read -p "输入电报机器人Chat_ID:" YOUR_CHAT_ID
CHAT_ID="${YOUR_CHAT_ID}"
echo "CHAT_ID=\"$YOUR_CHAT_ID\"" >>/myshell/tg_info.sh
if ! command -v jq &>/dev/null; then
	sudo apt install jq -y
fi
chmod +x /myshell/restart_vps.sh

#创建一个服务文件
sudo touch /etc/systemd/system/tg.service

# 写入多行内容到文件
sudo bash -c 'cat <<EOF >/etc/systemd/system/tg.service
[Unit]
#描述你的服务
Description=vps_controller
#指定服务在网络服务启动后启动
After=network.target

[Service]
#指定服务启动时执行的命令或脚本
ExecStart=/bin/bash /myshell/listening.sh
#指定服务的工作目录
WorkingDirectory=/
#设置服务失败时自动重启
Restart=always
#设置重启间隔为 3 秒
RestartSec=3
#设置输出到系统日志
StandardOutput=journal
##设置输出到系统日志
StandardError=journal
#设置服务在日志中的标识符
SyslogIdentifier=tg

[Install]
#指定服务在多用户模式下启用
WantedBy=multi-user.target
EOF'

sudo systemctl daemon-reload     # 重新加载 systemd 配置
sudo systemctl enable tg.service # 启用服务，使其开机自启
sudo systemctl start tg.service  # 启动服务
sudo systemctl status tg.service # 查看服务状态
