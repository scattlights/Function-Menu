#!/bin/bash
export LANG="en_US.UTF-8"
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;36m'
nc='\033[0m'

red() {
	echo -e "${red}$1${nc}"
}

green() {
	echo -e "${green}$1${nc}"
}

yellow() {
	echo -e "${yellow}$1${nc}"
}

blue() {
	echo -e "${blue}$1${nc}"
}

[[ $EUID -ne 0 ]] && red "请以root模式运行脚本" && exit

#判断操作系统
declare -g release
if [ -f /etc/os-release ]; then
	. /etc/os-release
	case "$ID" in
	ubuntu)
		release="Ubuntu"
		;;
	debian)
		release="Debian"
		;;
	*)
		red "不支持当前的系统，请使用Debian系统或Ubuntu系统" && exit 1
		;;
	esac
else
	# 旧版本系统的兼容性检测
	if grep -q -E -i "debian" /etc/issue; then
		release="Debian"
	elif grep -q -E -i "ubuntu" /etc/issue; then
		release="Ubuntu"
	elif grep -q -E -i "debian" /proc/version; then
		release="Debian"
	elif grep -q -E -i "ubuntu" /proc/version; then
		release="Ubuntu"
	else
		red "不支持当前的系统，请使用Debian系统或Ubuntu系统" && exit 1
	fi
fi

if ! command -v curl &> /dev/null
then
    apt update -y
    apt install -y curl
fi

apt-get update
apt-get install sudo

#检查git包是否安装
check_git_installation() {
	if ! command -v git &>/dev/null; then
		yellow "正在安装 Git..."
		if [[ "$release" == "Debian" || "$release" == "Ubuntu" ]]; then
			sudo apt update
			sudo apt install git -y
		else
			sudo yum install -y git
		fi
	fi
}

#检查qrencode包是否安装
check_qrencode_installation() {
	if ! command -v qrencode &>/dev/null; then
		yellow "正在安装Qrencode..."
		if [[ "$release" == "Debian" || "$release" == "Ubuntu" ]]; then
			sudo apt update
			sudo apt install qrencode -y
		else
			sudo yum install -y qrencode
		fi
	fi
}

#GitLab私有仓库信息填写
gitlab_repo_info() {
	check_git_installation
	while true; do
		read -r -p "$(yellow 请输入GitLab用户名称:)" user_name
		# 检查字符串是否为空或者不包含空格
		if [ -z "$user_name" ] || [[ "$user_name" =~ [[:space:]] ]]; then
			red "输入不能为空或者不能包含空格，请重新输入"
			echo
			continue
		fi
		break
	done
	while true; do
		read -r -p "$(yellow 请输入仓库名称:)" repo_name
		# 检查字符串是否为空或者不包含空格
		if [ -z "$repo_name" ] || [[ "$repo_name" =~ [[:space:]] ]]; then
			red "输入不能为空或者不能包含空格，请重新输入"
			echo
			continue
		fi
		break
	done
	while true; do
		read -r -p "$(yellow 请输入令牌:)" token
		#操作符获取字符串长度
		length=${#token}
		if [ "$length" != 26 ]; then
			red "令牌不合法:"
			red "1. 重新输入"
			red "2. 返回主菜单"

			read -r -p "" choice
			case $choice in
			1)
				continue
				;;
			2)
				return
				;;
			*)
				red "无效的选择"
				continue
				;;
			esac
		fi
		break
	done
	while true; do
		read -r -p "$(yellow 请输入分支名称:)" branch_name
		# 检查字符串是否为空或者不包含空格
		if [ -z "$branch_name" ] || [[ "$branch_name" =~ [[:space:]] ]]; then
			red "输入不能为空或者不能包含空格，请重新输入"
			echo
			continue
		fi
		break
	done
}

main_menu() {
	clear
	yellow "=============================="
	green "1. 显示系统信息"
	green "2. 显示磁盘空间"
	green "3. 生成GitLab私有仓库访问链接"
	green "4. 推送单个文件到GitLab私有仓库并生成访问链接"
	green "5. 安装并自动配置Fail2ban"
	green "6. 查看Fail2ban封禁IP情况"
	green "7. 卸载Fail2ban"
	green "8. 修改SSH登录端口"
	green "9. 拉取GitLab私有仓库指定文件"
	green "10. 安装NGINX"
	green "11. 卸载NGINX"
	green "12. 软件更新"
	green "13. 使用UFW防火墙开放指定端口"
	green "14. 查看或修改当前时区"
	green "15. 查看或编辑定时任务"
	green "0. 退出"
	yellow "=============================="
}

# 选项1：显示系统信息
display_system_info() {
	echo "主机名称: $HOSTNAME"
	echo "运行时间：$(uptime)"
	read -r -p "$(blue "按回车键返回主菜单...")"
}

# 选项2：显示磁盘空间
display_disk_space() {
	echo "磁盘空间:"
	df -h
	read -r -p "$(blue "按回车键返回主菜单...")"
}

# 选项3：生成gitlab私有仓库访问链接
generate_gitlab_access_link() {
	clear
	check_qrencode_installation
	gitlab_repo_info
	while true; do
		read -p "$(yellow "请输入包含路径的文件名称, 当前路径: / :") " file_name
		# 检查字符串是否为空或者不包含空格
		if [ -z "$file_name" ] || [[ "$file_name" =~ [[:space:]] ]]; then
			red "输入不能为空或者不能包含空格，请重新输入"
			echo
			continue
		fi
		break
	done
	# 替换 '/' 为 '%2F'
	file_name_encoded=$(echo "$file_name" | sed 's/\//%2F/g')
	link="https://gitlab.com/api/v4/projects/${user_name}%2F${repo_name}/repository/files/${file_name_encoded}/raw?ref=${branch_name}&private_token=${token}"

	# 发送HEAD请求，检查状态码
	response_code=$(curl --silent --head --output /dev/null --write-out "%{http_code}" "$link")

	if [ "$response_code" -eq 200 ]; then
		echo
		green "链接已生成，可以正常访问: ${link}"
		echo
		#生成二维码,纠错级别为H
		qrencode -t ANSIUTF8 -l H "${link}"
		echo
		read -r -p "$(blue "按回车键返回主菜单...")"
	else
		echo
		green "输入信息有误，链接无法访问，状态码为: "
		red "${response_code}"
		echo
		read -r -p "$(blue "按回车键返回主菜单...")"
	fi
}

# 选项4：推送单个文件到gitlab私有仓库，并生成访问链接
push_file_to_gitlab() {
	check_git_installation
	check_qrencode_installation
	clear
	gitlab_repo_info
	git config --global user.name "$user_name"
	git config --global user.email "$user_name@example.com"
	cd /usr || exit
	if [ -d "$repo_name" ]; then
		rm -r "$repo_name"
	fi
	mkdir "$repo_name"
	cd "$repo_name" || exit
	# 初始化本地仓库，指定初始化时创建的分支名和GitLab分支名一致
	git init -b "$branch_name"
	# 设置远程仓库
	git remote add origin https://"$user_name":"$token"@gitlab.com/"$user_name"/"$repo_name".git
	# 拉取最新
	git pull origin "$BRANCH_NAME" --no-rebase
	while true; do
		# 上传文件的路径
		# shellcheck disable=SC2162
		read -p "$(green "请输入需要推送的包含路径的文件名称:") " file_path
		if [ ! -f "$file_path" ]; then
			red "文件不存在，请重新输入"
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
		yellow "注意：GitLab 仓库中存在同名文件，所以自动更改需要推送的文件名为: ${new_file_name}"
		echo
		cp "$file_path" /usr/"$repo_name"/"$new_file_name"
		# 添加文件
		git add "$new_file_name"
		access_file_name=$new_file_name
	else
		cp "$file_path" /usr/"$repo_name"/"$file_name"
		# 添加文件
		git add "$file_name"
		access_file_name=$file_name
	fi
	# 提交
	git commit -m "初次提交"
	# 推送到远程仓库的指定分支
	git push -u origin "$branch_name"
	# 检查命令执行结果
	if [ $? -eq 0 ]; then
		green "推送成功"
	else
		green "推送失败"
	fi
	cd ..
	rm -r "$repo_name"
	link="https://gitlab.com/api/v4/projects/${user_name}%2F${repo_name}/repository/files/${access_file_name}/raw?ref=${branch_name}&private_token=${token}"
	echo
	green "链接: ${link}"
	echo
	#生成二维码,纠错级别为H
	qrencode -t ANSIUTF8 -l H "${link}"
	echo
	read -r -p "$(blue "按回车键返回主菜单...")"
}
# 5.安装fail2ban
install_fail2ban() {
	clear
	sudo systemctl stop fail2ban
	sudo apt remove --purge fail2ban -y
	if [ -f /etc/fail2ban/jail.local ]; then
		sudo rm /etc/fail2ban/jail.local
	fi
	read -r -p "$(green "请输入 SSH 端口号:")" port
	echo
	sudo apt update
	sudo apt install -y fail2ban
	# 创建本地配置文件
	sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

	# 配置Fail2ban
	sudo bash -c "cat > /etc/fail2ban/jail.local <<EOL
[DEFAULT]
#定义哪些IP地址应该被忽略，不会被拉黑
ignoreip = 127.0.0.1/8 192.168.1.0/24
#指定被拉黑IP的拉黑时长，单位为秒
bantime  = 31622400
#定义在多少秒内发生maxretry次失败尝试会导致拉黑
findtime  = 600
#指定在findtime时间内允许的最大失败尝试次数。超过这个次数，IP将被拉黑
maxretry = 5
#定义日志后端的类型。auto会自动选择最合适的后端。
backend = auto
#指定接收Fail2ban通知的电子邮件地址
destemail = root@localhost
#发送通知时的发件人名称
sendername = Fail2Ban
#指定发送邮件的邮件传输代理
mta = sendmail

[sshd]
#启用或禁用这个jail
enabled = true
#监控的端口
port = ${port}
#指定Fail2ban使用的过滤器文件
filter = sshd
#指定Fail2ban监控的日志文件路径
logpath = /var/log/auth.log
#在这个jail中，指定在findtime时间内允许的最大失败尝试次数
maxretry = 5
EOL"

	# 启动并启用Fail2ban服务
	sudo systemctl start fail2ban
	sudo systemctl enable fail2ban
	yellow "Fail2ban 安装和配置完成"
	echo
	read -r -p "$(blue "按回车键返回主菜单...")"
}
#6.查看fail2ban状态
check_fail2ban_status() {
	clear
	# 检查命令是否存在
	if ! command -v fail2ban-client >/dev/null 2>&1; then
		yellow "Fail2ban 未安装"
		echo
		read -r -p "$(blue "按回车键返回主菜单...")"
	else
		sudo fail2ban-client status
		sudo fail2ban-client status sshd
		echo
		read -r -p "$(blue "按回车键返回主菜单...")"
	fi
}
# 7.卸载fail2ban
uninstall_fail2ban() {
	clear
	sudo systemctl stop fail2ban
	sudo rm -rf /etc/fail2ban/jail.local
	sudo apt remove --purge fail2ban -y
	yellow "Fail2ban 已卸载"
	echo
	read -r -p "$(blue "按回车键返回主菜单...")"
}
# 8.修改SSH端口
update_ssh_port() {
	clear
	read -r -p "$(green "输入新的 SSH 登录的端口号：") " port
	echo
	# 定义新的SSH端口号
	NEW_PORT=$port
	# 修改SSH配置文件
	sudo sed -i "s/^#\?Port .*/Port $NEW_PORT/" /etc/ssh/sshd_config && yellow "修改成功！！！"
	# 重启SSH服务使更改生效
	sudo systemctl restart sshd
	yellow "新端口为 $NEW_PORT "
	echo
	read -r -p "$(blue "按回车键返回主菜单...")"
}
# 9.拉取GitLab私有仓库指定文件
pull_the_specified_file() {
	LOCAL_DIR="root" # 本目录名称
	check_git_installation
	clear
	gitlab_repo_info
	git config --global user.name "$user_name"
	git config --global user.email "$user_name@example.com"
	cd /
	cd "$LOACL_DIR" || exit
	if [ -d "$repo_name" ]; then
		rm -r "$repo_name"
	fi
	mkdir "$repo_name"
	cd "$repo_name" || exit
	# 初始化本地仓库，指定初始化时创建的分支名和GitLab分支名一致
	git init -b "$branch_name"
	# 设置远程仓库
	git remote add origin https://"$user_name":"$token"@gitlab.com/"$user_name"/"$repo_name".git
	git config core.sparseCheckout true
	# shellcheck disable=SC2162
	read -p "$(yellow "请输入需要拉取的包含路径的文件名称:") " file_path
	echo "$file_path" >>.git/info/sparse-checkout
	git pull origin "$branch_name"
	# 检查拉取是否成功
	if [ $? -eq 0 ]; then
		yellow "文件已成功拉取到 /$LOCAL_DIR/$repo_name/$file_path"
	else
		yellow "文件拉取失败"
	fi
	echo
	read -r -p "$(blue "按回车键返回主菜单...")"
}

# 检查 Nginx 是否已安装
check_nginx_installed() {
	if dpkg -l | grep -q '^ii  nginx '; then
		read -r -p "$(blue "Nginx 已存在，按回车键返回主菜单...")"
	fi
}
# 10.安装Nginx
install_nginx() {
	clear
	check_nginx_installed
	echo "正在安装 Nginx..."
	sudo apt update
	sudo apt install -y nginx
	sudo systemctl start nginx
	sudo systemctl enable nginx
	echo
	read -r -p "$(blue "Nginx 安装并启动成功，按回车键返回主菜单...")"
}
# 11.卸载Nginx
uninstall_nginx() {
	clear
	# 检查 Nginx 是否已安装
	if dpkg -l | grep -q '^ii  nginx'; then
		green "Nginx 已安装，正在卸载..."
		green "停止 Nginx 服务..."
		systemctl stop nginx
		green "卸载 Nginx 软件包..."
		apt remove --purge -y nginx nginx-common nginx-core
		green "删除不再需要的依赖包..."
		apt autoremove -y
		green "删除配置文件和日志文件..."
		rm -rf /etc/nginx
		rm -rf /var/log/nginx
		rm -rf /var/www/html
		# 删除 Nginx 相关的用户和组
		if id -u www-data >/dev/null 2>&1; then
			green "删除Nginx用户和组..."
			deluser www-data
			delgroup www-data
		fi
		green "删除所有残留的 Nginx 文件..."
		find / -name '*nginx*' -exec rm -rf {} + 2>/dev/null
		read -r -p "$(blue "Nginx 已成功卸载并删除所有相关文件，按回车键返回主菜单...")"
	else
		read -r -p "$(blue "Nginx 未安装，按回车键返回主菜单...")"
	fi
}

# 12.软件更新
update() {
	clear
	sudo apt update -y
	sudo apt upgrade -y
	sudo apt full-upgrade -y
	sudo apt autoremove -y
	read -r -p "$(blue "更新成功，按回车键返回主菜单...")"
}

# 13.使用UFW开放指定端口
open_port() {
	clear
	sudo apt update -y
	if ! command -v ufw &>/dev/null; then
		green "UFW未安装，正在安装..."
		sudo apt install -y ufw
	fi
	if [[ $(sudo ufw status | grep -c "active") -eq 1 ]]; then
		green "UFW已安装并启用，当前已开放的端口："
		sudo ufw status
	else
		green "UFW已安装但未启用"
	fi
	while true; do
		read -p "$(green "请输入需要开放的端口，已开放的端口无需再次输入（用英文逗号分隔，例如 22,80,443）： ")" ports
		if [[ $ports =~ ^[0-9]+(,[0-9]+)*$ ]]; then
			break
		else
			red "输入格式错误，请使用英文逗号分隔端口"
		fi
	done
	for port in $(echo $ports | tr ',' ' '); do
		sudo ufw allow $port
	done
	if [[ $(sudo ufw status | grep -c "inactive") -eq 1 ]]; then
		sudo ufw enable
	fi
	sudo ufw status
	read -r -p "$(blue "按回车键返回主菜单...")"
}

# 14.查看当前时区
view_or_modify_the_current_timezone() {
	timezone_info=$(timedatectl | grep "Time zone")
	clear
	yellow "当前时区：$timezone_info"
	echo
	while true; do
		green "请选择一个选项："
		green "1) 修改时区"
		green "2) 返回主菜单"

		read -p "$(green "输入选项：")" option

		case $option in
		1)
			while true; do
				clear
				green "1) 亚洲/上海"
				green "2) 美国/纽约"
				green "3) 欧洲/伦敦"
				green "4) 澳大利亚/悉尼"
				green "5) 亚洲/东京"
				read -p "$(green "输入选项：")" timezone_option
				case $timezone_option in
				1)
					clear
					sudo timedatectl set-timezone Asia/Shanghai
					timezone_info=$(timedatectl | grep "Time zone")
					yellow "当前时区：$timezone_info"
					read -r -p "$(blue "按回车键返回主菜单...")"
					break
					;;
				2)
					clear
					sudo timedatectl set-timezone America/New_York
					timezone_info=$(timedatectl | grep "Time zone")
					yellow "当前时区：$timezone_info"
					read -r -p "$(blue "按回车键返回主菜单...")"
					break
					;;
				3)
					clear
					sudo timedatectl set-timezone Europe/London
					timezone_info=$(timedatectl | grep "Time zone")
					yellow "当前时区：$timezone_info"
					read -r -p "$(blue "按回车键返回主菜单...")"
					break
					;;
				4)
					clear
					sudo timedatectl set-timezone Australia/Sydney
					timezone_info=$(timedatectl | grep "Time zone")
					yellow "当前时区：$timezone_info"
					read -r -p "$(blue "按回车键返回主菜单...")"
					break
					;;
				5)
					clear
					sudo timedatectl set-timezone Asia/Tokyo
					timezone_info=$(timedatectl | grep "Time zone")
					yellow "当前时区：$timezone_info"
					read -r -p "$(blue "按回车键返回主菜单...")"
					break
					;;
				*)
					clear
					red "无效的选择"
					;;
				esac
			done
			break
			;;
		2)
			clear
			break
			;;
		*)
			echo
			red "无效的选项"
			echo
			;;
		esac
	done
}

# 15.查看或编辑定时任务
view_or_edit_cron_jobs() {
	# 显示当前的定时任务
	display_tasks() {
		green "当前的定时任务:"
		current_tasks=()
		while IFS= read -r line; do
			if [[ ! $line =~ ^# && ! -z $line ]]; then
				current_tasks+=("$line")
			fi
		done < <(crontab -l)

		if [ ${#current_tasks[@]} -eq 0 ]; then
			green "没有定时任务"
			return
		fi

		# 为每个任务编号
		for i in "${!current_tasks[@]}"; do
			yellow "$((i + 1)): ${current_tasks[i]}"
		done
	}

	# 添加定时任务
	add_task() {
		echo
		read -p "$(green "请输入一条要添加的定时任务: ")" new_task

		# 创建临时文件
		temp_file=$(mktemp)

		# 将新任务添加到临时文件
		{
			crontab -l 2>/dev/null
			echo "$new_task"
		} >"$temp_file"

		# 更新 crontab
		crontab "$temp_file"
		rm "$temp_file" # 删除临时文件
  		echo
		green "添加成功"
		sleep 1
	}

	# 修改定时任务
	modify_task() {
		while true; do
			echo
			display_tasks
			read -p "$(green "请选择要修改的任务编号: ")" task_number

			# 检查用户输入
			if [[ $task_number -lt 1 || $task_number -gt ${#current_tasks[@]} ]]; then
   				echo
				red "无效的任务编号，请重新输入"
				sleep 2
			else
				# 获取用户选择的任务
				selected_task="${current_tasks[$task_number - 1]}"
				break
			fi
		done
		echo
		yellow "当前选择的任务是: $selected_task"
		echo
		read -p "$(green "请输入新的定时任务: ")" new_task

		# 创建临时文件
		temp_file=$(mktemp)

		# 更新定时任务
		{
			for task in "${current_tasks[@]}"; do
				if [[ "$task" == "$selected_task" ]]; then
					echo "$new_task" # 替换为新任务
				else
					echo "$task" # 保留其他任务
				fi
			done
		} >"$temp_file"

		# 更新 crontab
		crontab "$temp_file"
		rm "$temp_file" # 删除临时文件
		echo
		green "定时任务已更新"
  		sleep 2
	}

	# 删除定时任务
	delete_task() {
		while true; do
			clear
			display_tasks
			read -p "$(green "请选择要删除的任务编号,用英文逗号隔开（如 1,2,3）: ")" task_numbers

			# 将用户输入的编号转换为数组
			IFS=',' read -r -a task_array <<<"$task_numbers"

			# 检查每个编号是否有效
			invalid=false
			for num in "${task_array[@]}"; do
				if [[ ! "$num" =~ ^[0-9]+$ ]] || [[ $num -lt 1 || $num -gt ${#current_tasks[@]} ]]; then
					red "无效的任务编号: $num，请重新输入"
					invalid=true
					sleep 2
					break
				fi
			done

			if ! $invalid; then
				break
			fi
		done

		# 创建临时文件
		temp_file=$(mktemp)

		# 更新定时任务
		{
			for i in "${!current_tasks[@]}"; do
				if [[ ! " ${task_array[*]} " =~ " $((i + 1)) " ]]; then
					echo "${current_tasks[i]}" # 保留未删除的任务
				fi
			done
		} >"$temp_file"

		# 更新 crontab
		crontab "$temp_file"
		rm "$temp_file" # 删除临时文件
		echo
		green "定时任务已删除"
		sleep 2
	}

	# 主循环
	while true; do
		clear
		display_tasks
		echo
		green "选择操作:"
		green "1. 添加定时任务"
		green "2. 修改指定序号的定时任务"
		green "3. 删除指定序号的定时任务"
		green "4. 返回主菜单"
		read -p "$(green "请输入选项 (1-4): ")" option

		case $option in
		1) add_task ;;
		2) modify_task ;;
		3) delete_task ;;
		4)
  			break
			;;
		*)
			red "无效的选项，请重新输入"
			sleep 1
			;;
		esac
	done
}

main() {
	clear
	while true; do
		main_menu
		read -r -p "" choice
		case $choice in
		1) display_system_info ;;
		2) display_disk_space ;;
		3) generate_gitlab_access_link ;;
		4) push_file_to_gitlab ;;
		5) install_fail2ban ;;
		6) check_fail2ban_status ;;
		7) uninstall_fail2ban ;;
		8) update_ssh_port ;;
		9) pull_the_specified_file ;;
		10) install_nginx ;;
		11) uninstall_nginx ;;
		12) update ;;
		13) open_port ;;
		14) view_or_modify_the_current_timezone ;;
		15) view_or_edit_cron_jobs ;;
		0)
			clear
			green "脚本已退出..."
			exit
			;;
		*) red "输入有误，请重试..." ;;
		esac
	done
}
main
