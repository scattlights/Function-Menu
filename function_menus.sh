#!/bin/bash
export LANG="en_US.UTF-8"
# 定义颜色代码
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;36m'
#无颜色
nc='\033[0m'

[[ $EUID -ne 0 ]] && echo -e "${red}请以root模式运行脚本${nc}" && exit

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
		echo -e "${red}不支持当前的系统。请使用 Debian 或 Ubuntu 系统。${nc}" && exit 1
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
		echo -e "${red}不支持当前的系统。请使用 Debian 或 Ubuntu 系统。${nc}" && exit 1
	fi
fi

apt-get update
apt-get install sudo

#检查git包是否安装
check_git_installation() {
	if ! command -v git &>/dev/null; then
		echo -e "${yellow}正在安装Git...${nc}"
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
		echo -e "${yellow}正在安装Qrencode...${nc}"
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
		#请输入用户名称
		read -r -p "$(echo -e "${yellow}"请输入GitLab用户名称:"${nc}") " user_name
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
		read -r -p "$(echo -e "${yellow}"请输入仓库名称:"${nc}") " repo_name
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
		read -r -p "$(echo -e "${yellow}"请输入令牌:"${nc}") " token
		#操作符获取字符串长度
		length=${#token}
		if [ "$length" != 26 ]; then
			echo -e "${red}令牌不合法:${nc}"
			echo -e "${red}1.重新输入${nc}"
			echo -e "${red}2.返回主菜单${nc}"
			read -r -p "" choice
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
		read -r -p "$(echo -e "${yellow}"请输入分支名称:"${nc}") " branch_name
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
	echo -e "${green}1. 显示系统信息${nc}"
	echo -e "${green}2. 显示磁盘空间${nc}"
	echo -e "${green}3. 生成GitLab私有仓库访问链接${nc}"
	echo -e "${green}4. 推送单个文件到GitLab私有仓库并生成访问链接${nc}"
	echo -e "${green}5. 安装并自动配置fail2ban${nc}"
	echo -e "${green}6. 查看fail2ban封禁ip情况${nc}"
	echo -e "${green}7. 卸载fail2ban${nc}"
	echo -e "${green}8. 修改SSH登录端口${nc}"
	echo -e "${green}9. 拉取GitLab私有仓库指定文件到本地${nc}"
	echo -e "${green}10. 安装Nginx${nc}"
	echo -e "${green}11. 卸载Nginx${nc}"
	echo -e "${green}0. 退出${nc}"
	echo -e "${yellow}==============================${nc}"
}

# 选项1：显示系统信息
display_system_info() {
	echo "主机名称: $HOSTNAME"
	echo "运行时间：$(uptime)"
	read -r -p "$(echo -e "${blue}"按回车键返回主菜单..."${nc}")"
}

# 选项2：显示磁盘空间
display_disk_space() {
	echo "磁盘空间:"
	df -h
	read -r -p "$(echo -e "${blue}"按回车键返回主菜单..."${nc}")"
}

#选项3：生成gitlab私有仓库访问链接
generate_gitlab_access_link() {
	clear
	check_qrencode_installation
	gitlab_repo_info
	while true; do
		#请输入文件名称
		# shellcheck disable=SC2162
		read -p "$(echo -e "${yellow}"请输入包含路径的文件名称,当前在"/"路径下:"${nc}") " file_name
		# 检查字符串是否为空或者不包含空格
		if [ -z "$file_name" ] || [[ "$file_name" =~ [[:space:]] ]]; then
			echo -e "${red}输入不能为空或者不能包含空格,请重新输入...${nc}"
			echo
			continue
		fi
		#输入合法，则跳出循环
		break
	done
 	# 替换 '/' 为 '%2F'
	file_name_encoded=$(echo "$file_name" | sed 's/\//%2F/g')
	link="https://gitlab.com/api/v4/projects/${user_name}%2F${repo_name}/repository/files/${file_name_encoded}/raw?ref=${branch_name}&private_token=${token}"

	# 发送HEAD请求，检查状态码
	response_code=$(curl --silent --head --output /dev/null --write-out "%{http_code}" "$link")

	if [ "$response_code" -eq 200 ]; then
		echo
		echo -e "${green}链接已生成，可以正常访问:${link}${nc}"
		echo
		#生成二维码,纠错级别为H
		qrencode -t ANSIUTF8 -l H "${link}"
		echo
		read -r -p "$(echo -e "${blue}"按回车键返回主菜单..."${nc}")"
	else
		echo
		echo -e "${green}输入信息有误，链接无法访问，状态码为:${red}${response_code}${nc}"
		echo
		read -r -p "$(echo -e "${blue}"按回车键返回主菜单..."${nc}")"
	fi
}

#选项4：推送单个文件到gitlab私有仓库，并生成访问链接
push_file_to_gitlab() {
	check_git_installation
	check_qrencode_installation
	# 清屏
	clear
	# 调用
	gitlab_repo_info
	# 配置Git全局用户信息
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
	git pull origin "$branch_name"
	while true; do
		# 上传文件的路径
		# shellcheck disable=SC2162
		read -p "$(echo -e "${green}"请输入需要推送的包含路径的文件名称:"${nc}") " file_path
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
		echo -e "${green}推送成功...${nc}"
	else
		echo -e "${green}推送失败...${nc}"
	fi
	# 删除本地仓库
	cd ..
	rm -r "$repo_name"
	link="https://gitlab.com/api/v4/projects/${user_name}%2F${repo_name}/repository/files/${access_file_name}/raw?ref=${branch_name}&private_token=${token}"
	echo
	echo -e "${green}链接:${link}${nc}"
	echo
	#生成二维码,纠错级别为H
	qrencode -t ANSIUTF8 -l H "${link}"
	echo
	read -r -p "$(echo -e "${blue}"按回车键返回主菜单..."${nc}")"
}
#5.安装fail2ban
install_fail2ban() {
	clear
	#停止fail2ban服务
	sudo systemctl stop fail2ban
	sudo apt remove --purge fail2ban -y
	#如果存在，删除本地配置文件
	if [ -f /etc/fail2ban/jail.local ]; then
		sudo rm /etc/fail2ban/jail.local
	fi
	read -r -p "$(echo -e "${green}"请输入SSH端口号:"${nc}")" port
	echo
	# 更新包列表并安装Fail2ban
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
	echo -e "${yellow}Fail2ban安装和配置完成。${nc}"
	echo
	read -r -p "$(echo -e "${blue}"按回车键返回主菜单..."${nc}")"
}
#6.查看fail2ban状态
check_fail2ban_status() {
	clear
	# 检查命令是否存在
	if ! command -v fail2ban-client >/dev/null 2>&1; then
		echo -e "${yellow}Fail2ban未安装。${nc}"
		echo
		read -r -p "$(echo -e "${blue}"按回车键返回主菜单..."${nc}")"
	else
		sudo fail2ban-client status
		sudo fail2ban-client status sshd
		echo
		read -r -p "$(echo -e "${blue}"按回车键返回主菜单..."${nc}")"
	fi
}
#7.卸载fail2ban
uninstall_fail2ban() {
	clear
	sudo systemctl stop fail2ban
	sudo rm -rf /etc/fail2ban/jail.local
	sudo apt remove --purge fail2ban -y
	echo -e "${yellow}Fail2ban已卸载。${nc}"
	echo
	read -r -p "$(echo -e "${blue}"按回车键返回主菜单..."${nc}")"
}
#8.修改SSH端口
update_ssh_port() {
	clear
	read -r -p "$(echo -e "${green}"输入新的SSH登录的端口号："${nc}") " port
	# 定义新的SSH端口号
	NEW_PORT=$port
	# 修改SSH配置文件
	sudo sed -i "s/^Port .*/Port $NEW_PORT/" /etc/ssh/sshd_config
	# 重启SSH服务使更改生效
	sudo systemctl restart sshd
	echo -e "${yellow}$SSH端口已修改为$NEW_PORT!!!${nc}"
	echo
	read -r -p "$(echo -e "${blue}"按回车键返回主菜单..."${nc}")"
}
#9.拉取GitLab私有仓库指定文件到本地
pull_the_specified_file_to_local() {
	LOCAL_DIR="root" # 本地目录名称
	check_git_installation
	# 清屏
	clear
	# 调用
	gitlab_repo_info
	# 配置Git全局用户信息
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
	read -p "$(echo -e "${yellow}"请输入需要拉取的包含路径的文件名称:"${nc}") " file_path
	echo "$file_path" >>.git/info/sparse-checkout
	git pull origin "$branch_name"
	# 检查拉取是否成功
	if [ $? -eq 0 ]; then
		echo -e "${yellow}文件已成功拉取到/$LOCAL_DIR/$repo_name/$file_path${nc}"
	else
		echo -e "${yellow}文件拉取失败${nc}"
	fi
	echo
	read -r -p "$(echo -e "${blue}"按回车键返回主菜单..."${nc}")"
}

# 检查 Nginx 是否已安装
check_nginx_installed() {
	if dpkg -l | grep -q '^ii  nginx '; then
		read -r -p "$(echo -e "${blue}"Nginx已存在，按回车键返回主菜单..."${nc}")"
	fi
}
# 10.安装Nginx
install_nginx() {
	clear
	check_nginx_installed
	echo "正在安装 Nginx..."

	# 更新包列表
	sudo apt update

	# 安装 Nginx
	sudo apt install -y nginx

	# 启动 Nginx 服务
	sudo systemctl start nginx

	# 设置 Nginx 开机自启动
	sudo systemctl enable nginx

	echo
	read -r -p "$(echo -e "${blue}"}Nginx安装并启动成功，按回车键返回主菜单..."${nc}")"
}
# 11.卸载Nginx
uninstall_nginx() {
	clear
	# 检查 Nginx 是否已安装
	if dpkg -l | grep -q '^ii  nginx'; then
		echo -e "${GREEN}Nginx 已安装。正在卸载...${NC}"

		# 停止 Nginx 服务
		echo "停止 Nginx 服务..."
		systemctl stop nginx

		# 卸载 Nginx 软件包
		echo "卸载 Nginx 软件包..."
		apt remove --purge -y nginx nginx-common nginx-core

		# 删除不再需要的依赖包
		echo "删除不再需要的依赖包..."
		apt autoremove -y

		# 删除配置文件和日志
		echo "删除配置文件和日志文件..."
		rm -rf /etc/nginx
		rm -rf /var/log/nginx
		rm -rf /var/www/html

		# 删除 Nginx 相关的用户和组（如果存在）
		if id -u www-data >/dev/null 2>&1; then
			echo "删除 Nginx 用户和组..."
			deluser www-data
			delgroup www-data
		fi
		# 删除所有残留的 Nginx 文件
		echo "删除所有残留的 Nginx 文件..."
		find / -name '*nginx*' -exec rm -rf {} + 2>/dev/null
		read -r -p "$(echo -e "${blue}"}Nginx已成功卸载并删除所有相关文件，按回车键返回主菜单..."${nc}")"
	else
		read -r -p "$(echo -e "${blue}"}Nginx未安装，按回车键返回主菜单..."${nc}")"
	fi
}

main() {
	# 清屏
	clear
	# 主循环
	while true; do
		main_menu
		#等待用户输入数字，可编辑数字，按回车确定
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
		9) pull_the_specified_file_to_local ;;
		10) install_nginx ;;
		11) uninstall_nginx ;;
		0)
			echo -e "${blue}程序已退出...${nc}"
			exit
			;;
		*) echo -e "${red}输入有误，请重试...${nc}" ;;
		esac
	done
}
main
