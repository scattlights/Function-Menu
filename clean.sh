#!/bin/bash
# 定义颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # 无颜色

#需要清除垃圾文件的目录
read -p "(echo -e ${RED}输入需要清除垃圾文件的目录:${NC}) " directory

# 清理临时文件
echo "清理临时文件..."
find "$directory" -type f -name "*.tmp" -exec rm -f {} \;

# 清理日志文件
echo "清理日志文件..."
find "$directory" -type f -name "*.log" -exec rm -f {} \;

echo "垃圾文件清理完成!"

	
	

