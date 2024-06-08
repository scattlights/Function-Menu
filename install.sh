#！/bin/bash
FILE="/test/one.txt"
DIRECTORY="/test"
if [[ -d "$DIRECTORY" && -f "$FILE" ]]; then
	echo "This is a test!" >> "$FILE"
else
	echo "The directory or file does not exist!"
fi
	
	
	

