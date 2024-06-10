#!/bin/bash
export LANG="en_US.UTF-8"

# 定义颜色代码
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;36m'
nc='\033[0m' # 无颜色

# 主菜单函数
function main_menu {
    echo 
    #控制台输出，-e开启转义字符
    echo -e "${yellow}==============================${nc}"
    echo -e "${green}请输入你的选择，并按回车键确认:${nc}"
    echo -e "${green}1. 显示系统信息${nc}"         
    echo -e "${green}2. 显示磁盘空间${nc}"   
    echo -e "${green}0. 退出${nc}"
    echo -e "${yellow}==============================${nc}"
}

# 选项1：显示系统信息
function display_system_info {
    echo "主机名称: $HOSTNAME"
    echo "运行时间：$(uptime)"
    read -p "$(echo -e ${blue}按回车键返回主菜单...${nc})"
}

# 选项2：显示磁盘空间
function display_disk_space {
    echo "磁盘空间:"
    df -h
    read -p "$(echo -e ${blue}按回车键返回主菜单...${nc})"
}

# 主循环
while true; do
    main_menu
	#等待用户输入数字，可编辑数字，按回车确定
	read -p "" choice
    case $choice in
        1) display_system_info ;;
        2) display_disk_space ;;
        0) echo -e "${blue}程序已退出...${nc}"; exit ;;
        *) echo -e "${red}输入有误，请重试...${nc}" ;;
    esac
done
