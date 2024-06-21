#!/bin/bash
export LANG="en_US.UTF-8"
# 定义颜色代码
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;36m'
#无颜色
nc='\033[0m'
#带宽bit单位转换
bit_to_human_readable() {
	#输入比特值
	local trafficValue=$1
	if [[ ${trafficValue%.*} -gt 922 ]]; then
		#转换成Kb
		trafficValue=$(awk -v value=$trafficValue 'BEGIN{printf "%0.1f",value/1024}')
		if [[ ${trafficValue%.*} -gt 922 ]]; then
			#转换成Mb
			trafficValue=$(awk -v value=$trafficValue 'BEGIN{printf "%0.1f",value/1024}')
			echo "${trafficValue}Mb"
		else
			echo "${trafficValue}Kb"
		fi
	else
		echo "${trafficValue}b"
	fi
}
#GitLab私有仓库信息填写
gitlab_repo_info() {
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
		#请输入仓库名称
		read -p "$(echo -e ${yellow}请输入仓库名称:${nc}) " repo_name
		# 检查字符串是否为空或者不包含空格
		if [ -z "$repo_name" ] || [[ "$repo_name" =~ [[:space:]] ]]; then
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
		if [ $length != 26 ]; then
			echo -e "${red}令牌不合法:${nc}"
			echo -e "${red}1.重新输入${nc}"
			echo -e "${red}2.返回主菜单${nc}"
			read -p "" choice
			case $choice in
			1)
				continue
				;;
			2)
				return
				;;
			*)
				echo -e "${red}无效的选择...${nc}"
				continue
				;;
			esac
		fi
		#输入合法，则跳出循环
		break
	done

	while true; do
		#请输入分支名称
		read -p "$(echo -e ${yellow}请输入分支名称:${nc}) " branch_name
		# 检查字符串是否为空或者不包含空格
		if [ -z "$branch_name" ] || [[ "$branch_name" =~ [[:space:]] ]]; then
			echo -e "${red}输入不能为空或者不能包含空格,请重新输入...${nc}"
			echo
			continue
		fi
		#输入合法，则跳出循环
		break
	done
}
# 主菜单函数
main_menu() {
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
	echo -e "${green}7. 推送单个文件到GitLab私有仓库并生成访问链接${nc}"
	echo -e "${green}0. 退出${nc}"
	echo -e "${yellow}==============================${nc}"
}
# 选项1：显示系统信息
display_system_info() {
	echo "主机名称: $HOSTNAME"
	echo "运行时间：$(uptime)"
	read -p "$(echo -e ${blue}按回车键返回主菜单...${nc})"
}
# 选项2：显示磁盘空间
display_disk_space() {
	echo "磁盘空间:"
	df -h
	read -p "$(echo -e ${blue}按回车键返回主菜单...${nc})"
}
# 选项3：清除临时文件
delete_temporary_files() {
	#需要清除垃圾文件的目录
	read -p "$(echo -e ${yellow}输入需要清除垃圾文件的目录:${nc}) " directory
	#如果目录不存在
	if [ ! -d "$directory" ]; then
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
delete_log_files() {
	#需要清除日志文件的目录
	read -p "$(echo -e ${yellow}输入需要清除垃圾文件的目录:${nc}) " directory
	#如果目录不存在
	if [ ! -d "$directory" ]; then
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
real_time_traffic() {
	local eth=""
	local nic_arr=($(ifconfig | grep -E -o "^[a-z0-9]+" | grep -v "lo" | uniq))
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
	local clear=true
	local eth_in_peak=0
	local eth_out_peak=0
	local eth_in=0
	local eth_out=0
	echo -e "${green}请稍等，实时流量显示时可以按任意键返回主菜单...${nc}"
	sleep 2
	# 禁止光标显示
	tput civis
	while true; do
		# 设置终端属性，禁止按键显示
		stty -echo
		#检测到用户输入，就跳出循环
		read -s -n 1 -t 0.1 key
		if [[ $? -eq 0 ]]; then
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
		traffic_be=($(awk -v eth=$eth -F'[: ]+' '{if ($0 ~eth){print $3,$11}}' /proc/net/dev))
		sleep 2
		traffic_af=($(awk -v eth=$eth -F'[: ]+' '{if ($0 ~eth){print $3,$11}}' /proc/net/dev))
		#计算速率
		eth_in=$(((${traffic_af[0]} - ${traffic_be[0]}) * 8 / 2))
		eth_out=$(((${traffic_af[1]} - ${traffic_be[1]}) * 8 / 2))
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
generate_gitlab_access_link() {
	#调用
	gitlab_repo_info
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
	link="https://gitlab.com/api/v4/projects/${user_name}%2F${repo_name}/repository/files/${file_name}/raw?ref=${branch_name}&private_token=${token}"

	# 发送HEAD请求，检查状态码
	response_code=$(curl --silent --head --output /dev/null --write-out "%{http_code}" "$link")

	if [ "$response_code" -eq 200 ]; then
		echo
		echo -e "${green}链接已生成，可以正常访问:${link}${nc}"
		echo
		read -p "$(echo -e ${blue}按回车键返回主菜单...${nc})"
	else
		echo
		echo -e "${green}输入信息有误，链接无法访问，状态码为:${red}${response_code}${nc}"
		echo
		read -p "$(echo -e ${blue}按回车键返回主菜单...${nc})"
	fi
}
#选项7：推送单个文件到gitlab私有仓库，并生成访问链接
push_file_to_gitlab() {
	# 清屏
	clear
	# 调用
	gitlab_repo_info
	# 配置Git全局用户信息
	git config --global user.name "$user_name"
	git config --global user.email "$user_name@example.com"
	cd /usr
	if [ -d $repo_name ]; then
		rm -r $repo_name
	fi
	mkdir $repo_name
	cd $repo_name
	# 初始化本地仓库，指定初始化时创建的分支名和GitLab分支名一致
	git init -b $branch_name
	# 设置远程仓库
	git remote add origin https://$user_name:$token@gitlab.com/$user_name/$repo_name.git
	# 拉取最新
	git pull origin $branch_name
	while true; do
		# 上传文件的路径
		read -p "$(echo -e ${green}请输入需要推送的包含路径的文件名称:${nc}) " file_path
		# 当文件不存在
		if [ ! -f "$file_path" ]; then
			echo -e "${red}文件不存在,请重新输入...${nc}"
			continue
		else
			break
		fi
	done
	# 获取当前时间并格式化为年月日时分秒
	timestamp=$(date +"%Y%m%d_%H%M%S")
	# 获取文件名
	file_name=$(basename "$file_path")
	repo_file_path="/usr/$repo_name/$file_name"
	# 新文件名为旧文件名加时间戳
	new_file_name="${file_name%.*}_${timestamp}.${file_name##*.}"
	# 访问链接文件名
	access_file_name=
	# 如果GitLab仓库中存在同名文件，则自动重新命名要推送的文件
	if [ -f "$repo_file_path" ]; then
		echo
		echo -e "${yellow}注意：GitLab仓库中存在同名文件,所以自动更改需要推送的文件名为:${new_file_name}${nc}"
		echo
		cp $file_path /usr/$repo_name/$new_file_name
		# 添加文件
		git add $new_file_name
		access_file_name=$new_file_name
	else
		cp $file_path /usr/$repo_name/$file_name
		# 添加文件
		git add $file_name
		access_file_name=$file_name
	fi
	# 提交
	git commit -m "初次提交"
	# 推送到远程仓库的指定分支
	git push -u origin $branch_name
	# 检查命令执行结果
	if [ $? -eq 0 ]; then
		echo -e "${green}推送成功...${nc}"
	else
		echo -e "${green}推送失败...${nc}"
	fi
	# 删除本地仓库
	cd ..
	rm -r $repo_name
	link="https://gitlab.com/api/v4/projects/${user_name}%2F${repo_name}/repository/files/${access_file_name}/raw?ref=${branch_name}&private_token=${token}"
	echo
	echo -e "${green}链接:${link}${nc}"
	echo
	read -p "$(echo -e ${blue}按回车键返回主菜单...${nc})"
}
main() {
	# 主循环
	while true; do
		main_menu
		#等待用户输入数字，可编辑数字，按回车确定
		read -p "" choice
		case $choice in
		1) display_system_info ;;
		2) display_disk_space ;;
		3) delete_temporary_files ;;
		4) delete_log_files ;;
		5) real_time_traffic ;;
		6) generate_gitlab_access_link ;;
		7) push_file_to_gitlab ;;
		0)
			echo -e "${blue}程序已退出...${nc}"
			exit
			;;
		*) echo -e "${red}输入有误，请重试...${nc}" ;;
		esac
	done
}
main
