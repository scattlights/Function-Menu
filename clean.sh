#!/bin/bash
# 定义颜色代码
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # 无颜色

#需要清除垃圾文件的目录
read -p "$(echo -e ${YELLOW}输入需要清除垃圾文件的目录:${NC}) " directory

# 清理临时文件
echo -e "${GREEN}清除临时文件...${NC}"
find "$directory" -type f -name "*.tmp" -exec rm -f {} \;

# 清理日志文件
echo -e "${GREEN}清除日志文件...${NC}"
find "$directory" -type f -name "*.log" -exec rm -f {} \;

echo -e "${GREEN}垃圾清除完成...${NC}"

	
	

