#!/bin/bash

# 网络地址和子网掩码
NETWORK="192.168.1.0/24"

# 输出文件
OUTPUT_FILE="network_scan_results.txt"

# 执行网络扫描
nmap -sP "$NETWORK" -oN "$OUTPUT_FILE"

echo "网络扫描完成，结果保存在 $OUTPUT_FILE 文件中。"
