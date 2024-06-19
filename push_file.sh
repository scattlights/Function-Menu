#!/bin/bash
#Function: Push files to GitLab private repository.

export LANG="en_US.UTF-8"

# 定义颜色代码
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;36m'
#无颜色
nc='\033[0m' 

#清屏
clear

# 设置GitLab用户信息
read -p "$(echo -e ${green}请输入GitLab用户名${nc})：" user_name
read -p "$(echo -e ${green}请输入GitLab仓库名${nc})：" repo_name
read -p "$(echo -e ${green}请输入令牌${nc})：" token
read -p "$(echo -e ${green}请输入分支名${nc})：" branch_name

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
   if [ ! -f "$file_path" ];then
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

#新文件名为旧文件名加时间戳
new_file_name="${file_name%.*}_${timestamp}.${file_name##*.}"

# 如果GitLab仓库中存在同名文件，则自动重新命名要推送的文件
if [ -f "$repo_file_path" ]; then
	  echo
      echo -e "${yellow}注意：GitLab仓库中存在同名文件,所以自动更改需要推送的文件名为:${new_file_name}${nc}"
      echo
      cp $file_path /usr/$repo_name/$new_file_name
      # 添加文件
      git add $new_file_name
    else
    cp $file_path /usr/$repo_name/$file_name
    # 添加文件 
    git add $file_name
fi

# 提交
git commit -m "初次提交"

# 推送到远程仓库的main分支
git push -u origin $branch_name

#检查命令执行结果
if [ $? -eq 0 ]; then
    echo -e "${green}推送成功...${nc}"
else
	echo -e "${green}推送失败...${nc}"
fi

#删除本地仓库
cd ..
rm -r $repo_name
