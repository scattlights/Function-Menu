#！/bin/bash
FILE="/test/one.txt"
DIRECTORY="/test"
IF [[ -d "$DIRECTORY" && -f "$FILE" ]]; then
	echo "This is a test" >> one.txt
else
	echo "目录或文件不存在！"
fi
	
	
	

