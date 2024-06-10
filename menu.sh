#!/bin/bash
export LANG="en_US.UTF-8"

echo "请选择:
1.显示系统信息
2.显示磁盘空间
3.退出"
echo -n "请选择数字:"
echo
read -n 1 num
echo

if [[ $num =~ ^[0-3]$ ]]; then
   if [[ $num == 0 ]]; then
     echo "程序退出"
     exit;
   fi

  if [[ $num == 1 ]]; then
    echo "Hostname :$HOSTNAME"
    uptime
    exit
  fi

  if [[ $num == 2 ]]; then
    df -h
    exit;
  fi

else
 echo "无效的输入" >&2
 exit 1
fi
