#！/bin/bash
FILE="/test/one.txt"
DIRECTORY="/test"
if [[ -d "$DIRECTORY" && -f "$FILE" ]]; then
	echo "$(date): This is a test!" >> "$FILE"
 	echo "Execution complete!"
else
	echo "The directory or file does not exist!"
fi
	
	
	

