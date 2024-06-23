#!bin/bash

# 加载 tg_info.sh 文件中的变量
source /myshell/tg_info.sh

OFFSET_FILE="/myshell/offset.txt"
if [ ! -f "$OFFSET_FILE" ]; then
	sudo touch "$OFFSET_FILE"
	sudo chmod 666 "$OFFSET_FILE"
 	OFFSET=0 # 初始的 offset 值
  else	
  	# 从文件中读取最后一次处理的 offset
	OFFSET=$(cat "$OFFSET_FILE")
fi

# 处理/restartvps命令的函数
handle_restartvps() {
	# 发送消息通知重启开始
	curl -s -X POST https://api.telegram.org/bot$BOT_TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="正在重启VPS，请稍候..."

	# 执行VPS重启的Shell脚本
	/myshell/restart.sh # 替换为你的实际脚本路径
}

# 发送消息通知重启完成
curl -s -X POST https://api.telegram.org/bot$BOT_TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="VPS已重启完成。"

# 主逻辑：监听命令并处理
while true; do
	# 获取最新消息的JSON数据
	UPDATES=$(curl -s -X GET https://api.telegram.org/bot$BOT_TOKEN/getUpdates?offset=${OFFSET})

	# 解析消息中的命令
	COMMAND=$(echo $UPDATES | jq -r '.result[-1].message.text')

	# 更新 offset 到文件
	MAX_UPDATE_ID=$(echo "$UPDATES" | jq '.result[-1].update_id')
	echo "$((MAX_UPDATE_ID + 1))" >"$OFFSET_FILE"

	# 处理/restartvps命令
	if [ "$COMMAND" == "/restart" ]; then
		handle_restartvps
	fi

	# 等待一段时间后再次轮询
	sleep 5
done
