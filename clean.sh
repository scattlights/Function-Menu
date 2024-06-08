#!/bin/bash

# 垃圾文件目录
TRASH_DIR="/"

# 清理临时文件
echo "清理临时文件..."
find "$TRASH_DIR" -type f -name "*.tmp" -exec rm -f {} \;

# 清理日志文件
echo "清理日志文件..."
find "$TRASH_DIR" -type f -name "*.log" -exec rm -f {} \;

echo "垃圾文件清理完成!"

	
	

