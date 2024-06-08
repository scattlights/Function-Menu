#!/bin/bash
FILE="/test/one.txt"
DIRECTORY="/test"
if [[ -d "$DIRECTORY" && -f "$FILE" ]]; then
    echo "This is a test" >> "$FILE"
else
    echo "目录或文件不存在！"
fi  # 这里是 if 结构的结束符号

exit 0
