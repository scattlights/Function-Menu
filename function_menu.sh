#!/bin/bash
export LANG="en_US.UTF-8"

# 定义颜色代码
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;36m'
#无颜色
nc='\033[0m' 

#把带宽bit单位转换为人类可读单位
bit_to_human_readable(){
    #输入比特值
    local trafficValue=$1
    
    if [[ ${trafficValue%.*} -gt 922 ]];then
        #转换成Kb
        trafficValue=`awk -v value=$trafficValue 'BEGIN{printf "%0.1f",value/1024}'`
        if [[ ${trafficValue%.*} -gt 922 ]];then
            #转换成Mb
            trafficValue=`awk -v value=$trafficValue 'BEGIN{printf "%0.1f",value/1024}'`
            echo "${trafficValue}Mb"
        else
            echo "${trafficValue}Kb"
        fi
    else
        echo "${trafficValue}b"
    fi
}

# 主菜单函数
main_menu(){
    echo 
    #控制台输出，-e开启转义字符
    echo -e "${yellow}==============================${nc}"
    echo -e "${green}请输入你的选择，并按回车键确认:${nc}"
    echo -e "${green}1. 显示系统信息${nc}"         
    echo -e "${green}2. 显示磁盘空间${nc}"  
    echo -e "${green}3. 清除临时文件${nc}" 	
    echo -e "${green}4. 清除日志文件${nc}"
    echo -e "${green}5. 实时流量${nc}"
	echo -e "${green}6. 生成GitLab私有仓库访问链接${nc}"
    echo -e "${green}0. 退出${nc}"
    echo -e "${yellow}==============================${nc}"
}

# 选项1：显示系统信息
display_system_info(){
    echo "主机名称: $HOSTNAME"
    echo "运行时间：$(uptime)"
    read -p "$(echo -e ${blue}按回车键返回主菜单...${nc})"
}

# 选项2：显示磁盘空间
display_disk_space(){
    echo "磁盘空间:"
    df -h
    read -p "$(echo -e ${blue}按回车键返回主菜单...${nc})"
}

# 选项3：清除临时文件
delete_temporary_files(){
	#需要清除垃圾文件的目录
    read -p "$(echo -e ${yellow}输入需要清除垃圾文件的目录:${nc}) " directory
	#如果目录不存在
	if [ ! -d "$directory" ];then
	#输出
	echo -e "${red}未找到该目录，即将返回主菜单...${nc}"
	#等待1秒
	sleep 1
	else
	#如果目录存在，删除临时文件
	find "$directory" -type f -name "*.tmp" -exec rm -f {} \;
	#输出，读取回车键
    read -p "$(echo -e ${blue}已清除，按回车键返回主菜单...${nc})"
	fi
}
# 选项4：清除日志文件
delete_log_files(){
	#需要清除日志文件的目录
    read -p "$(echo -e ${yellow}输入需要清除垃圾文件的目录:${nc}) " directory
	#如果目录不存在
	if [ ! -d "$directory" ];then
	#输出
	echo -e "${red}未找到该目录，即将返回主菜单...${nc}"
	#等待1秒
	sleep 1
	else
	#如果目录存在，删除临时文件
	find "$directory" -type f -name "*.log" -exec rm -f {} \;
	#输出
    read -p "$(echo -e ${blue}已清除，按回车键返回主菜单...${nc})"
	fi
}

# 选项5：实时流量
real_time_traffic(){
    local eth=""
    local nic_arr=(`ifconfig | grep -E -o "^[a-z0-9]+" | grep -v "lo" | uniq`)
    local nicLen=${#nic_arr[@]}
    if [[ $nicLen -eq 0 ]]; then
        echo "抱歉，无法检测到任何网络设备"
        exit 1
    elif [[ $nicLen -eq 1 ]]; then
        eth=$nic_arr
    else
        main_menu nic
        eth=$nic
    fi  
    #局部变量
    local clear=true
    local eth_in_peak=0
    local eth_out_peak=0
    local eth_in=0
    local eth_out=0
    echo -e "${green}请稍等，实时流量显示时可以按任意键返回主菜单...${nc}"
    sleep 2
    # 禁止光标显示
    tput civis   
    while true;do
	# 设置终端属性，禁止按键显示
        stty -echo
	#检测到用户输入，就跳出循环
	read -s -n 1 -t 0.1 key
	if [[ $? -eq 0 ]];then
		# 恢复终端属性
                stty echo
		# 恢复光标显示
		tput cnorm   
		#跳出循环
		break
	fi
        #移动光标到0:0位置
        printf "\033[0;0H"
        #如果clear为true，先清屏并打印Now Peak
        [[ $clear == true ]] && printf "\033[2J" && echo -e "${yellow}eth------Now--------Peak${nc}"
        traffic_be=(`awk -v eth=$eth -F'[: ]+' '{if ($0 ~eth){print $3,$11}}' /proc/net/dev`)
        sleep 2
        traffic_af=(`awk -v eth=$eth -F'[: ]+' '{if ($0 ~eth){print $3,$11}}' /proc/net/dev`)
        #计算速率
        eth_in=$(( (${traffic_af[0]}-${traffic_be[0]})*8/2 ))
        eth_out=$(( (${traffic_af[1]}-${traffic_be[1]})*8/2 ))
        #计算流量峰值
        [[ $eth_in -gt $eth_in_peak ]] && eth_in_peak=$eth_in
        [[ $eth_out -gt $eth_out_peak ]] && eth_out_peak=$eth_out
        #移动光标到2:1
        printf "\033[2;1H"
        #清除当前行
        printf "\033[K"  
        printf "${green}%-20s %-20s${nc}\n" "接收:  $(bit_to_human_readable $eth_in)" "$(bit_to_human_readable $eth_in_peak)"
        #清除当前行
        printf "\033[K"
        printf "${green}%-20s %-20s${nc}\n" "传输:  $(bit_to_human_readable $eth_out)" "$(bit_to_human_readable $eth_out_peak)"
	#把true的值改为false
        [[ $clear == true ]] && clear=false
    done
}

#选项6：生成gitlab私有仓库访问链接
generate_gitlab_access_link(){
while true; do
	#请输入用户名称
    read -p "$(echo -e ${yellow}请输入GitLab用户名称:${nc}) " user_name
	
	# 检查字符串是否为空或者不包含空格
    if [ -z "$user_name" ] || [[ "$user_name" =~ [[:space:]] ]]; then
	echo -e "${red}输入不能为空或者不能包含空格,请重新输入...${nc}"
	echo
	continue
	fi
	#输入合法，则跳出循环
	break
done

while true; do
	#请输入项目名称
    read -p "$(echo -e ${yellow}请输入项目名称:${nc}) " project_name
	
	# 检查字符串是否为空或者不包含空格
    if [ -z "$project_name" ] || [[ "$project_name" =~ [[:space:]] ]]; then
	echo -e "${red}输入不能为空或者不能包含空格,请重新输入...${nc}"
	echo
	continue
	fi
	#输入合法，则跳出循环
	break
done

while true; do
	#请输入文件名称
    read -p "$(echo -e ${yellow}请输入包含路径的文件名称:${nc}) " file_name
	
	# 检查字符串是否为空或者不包含空格
    if [ -z "$file_name" ] || [[ "$file_name" =~ [[:space:]] ]]; then
	echo -e "${red}输入不能为空或者不能包含空格,请重新输入...${nc}"
	echo
	continue
	fi
	#输入合法，则跳出循环
	break
done

while true; do
	#请输入令牌
    read -p "$(echo -e ${yellow}请输入令牌:${nc}) " token
	
	#使用#操作符获取字符串长度
    length=${#token}
	if [ $length != 26 ];then
	echo -e "${red}令牌不合法或输入有误,请重新输入...${nc}"
	echo
	continue
	fi
	#输入合法，则跳出循环
	break
done
	
	link="https://gitlab.com/api/v4/projects/${user_name}%2F${project_name}/repository/files/${file_name}/raw?ref=main&private_token=${token}"
	echo
	echo -e "${green}链接:${link}${nc}"
	echo
	read -p "$(echo -e ${blue}按回车键返回主菜单...${nc})"
}

main(){
# 主循环
while true; do
    main_menu
	#等待用户输入数字，可编辑数字，按回车确定
	read -p "" choice
    case $choice in
        1) display_system_info;;
        2) display_disk_space;;
        3) delete_temporary_files;;
	4) delete_log_files;;
	5) real_time_traffic;;
	6) generate_gitlab_access_link;;
        0) echo -e "${blue}程序已退出...${nc}"; exit;;
        *) echo -e "${red}输入有误，请重试...${nc}";;
    esac
done
}
main