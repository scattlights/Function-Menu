#!/bin/bash
export LANG=en_US.UTF-8

#功能：监控网络连接状态脚本

TCP_Total=$(ss -s | awk '$1=="TCP"{print $2}') #所有TCP连接个数
UDP_Total=$(ss -s | awk '$1=="UDP"{print $2}') #所有UDP连接个数
Unix_sockets_Total=$(ss -ax | awk 'BEGIN{count=0} {count++} END{print count}') #所有UNIX sockets连接个数
TCP_Listen_Total=$(ss -antlpH | awk 'BEGIN{count=0} {count++} END{print count}') #所有处于Listen监听状态的TCP端口个数
TCP_Estab_Total=$(ss -antph | awk 'BEGIN{count=0} /^ESTAB/{count++} END{print count}') #所有处于ESTABLISHED状态TCP连接个数
TCP_SYN_RECV_Total=$(ss -antpH | awk 'BEGIN{count=0} /^SYN-RECV/{count++} END{print count}') #所有处于SYN_RECV状态的TCP连接个数
TCP_TIME_WAIT_Total=$(ss -antpH | awk 'BEGIN{count=0} /^TIME-WAIT/{count++} END{print count}') #所有处于TIME-WAIT状态的TCP连接个数
TCP_TIME_WAIT1_Total=$(ss -antpH | awk 'BEGIN{count=0} /^TIME-WAIT1/{count++} END{print count}') #所有处于TIME-WAIT1状态的TCP连接个数
TCP_TIME_WAIT2_Total=$(ss -antpH | awk 'BEGIN{count=0} /^TIME-WAIT2/{count++} END{print count}') #所有处于TIME-WAIT2状态的TCP连接个数
TCP_Remote_Count=$(ss -antH | awk '$1!~/LISTEN/{IP[$5]++} END{ for(i in IP) {print IP[i],i} }' | sort -nr) #所有远程主机TCP连接次数
TCP_Port_Count=$(ss -antH | sed -r 's/ +/ /g' | awk -F"[ :]" '$1!~/LISTEN/{port[$5]++} END{for(i in port) {print port[i],i}}' | sort -nr) #每个端口被访问次数

#定义输出颜色

SUCCESS="echo -en \\033[1;32m"  #绿色
NORMAL="echo -en \\033[0;39m" #黑色

#显示TCP连接总数
tcp_total(){

	echo -n "TCP连接总数: "
	$SUCCESS
	echo "$TCP_Total"
	$NORMAL
}

#显示处于LISTEN状态的TCP端口个数

tcp_listen(){
	echo -n "处于LISTEN状态的TCP端口个数"
	$SUCCESS
	echo "$TCP_Listen_Total"
	$NORMAL
}

#显示处于ESTABLISHED状态的TCP连接个数
tcp_estab(){
	echo -n "处于ESTAB状态的TCP连接个数:"
	$SUCCESS
	echo "$TCP_Estab_Total"
	$NORMAL
}

#显示处于SYN-RECV状态的TCP连接个数

tcp_syn_recv(){
	echo -n "处于SYN-RECV状态的TCP连接个数:"
	$SUCCESS
	echo "$TCP_SYN_RECV_Total"
	$NORMAL
}

#显示处于TIME-WAIT状态的TCP连接个数

tcp_time_wait(){
	echo -n "处于TIME-WAIT状态的TCP连接个数:"
	$SUCCESS
	echo "$TCP_TIME_WAIT_Total"
	$NORMAL
}

#显示处于TIME-WAIT1状态的TCP连接个数
tcp_time_wait1(){
	echo -n "处于TIME-WAIT1状态的TCP连接个数:"
	$SUCCESS
	echo "$TCP_TIME_WAIT1_Total"
	$NoRMAL
}

#显示处于TIME-WAIT2状态的TCP连接个数
tcp_time_wait2(){
	echo -n "处于TIME-WAIT2状态的TCP连接个数:"
	$SUCCESS
	echo "$TCP_TIME_WAIT2_Total"
	$NORMAL
}

#显示UDP连接总数

udp_total(){
	echo -n "UDP连接总数:"
	$SUCCESS
	echo "$UDP_Total"
	$NORMAL
}

#显示UNIX sockets连接总数

unix_total(){
	echo -n "Unix sockets 连接总数:"
	$SUCCESS
	echo "$Unix_sockets_Total"
	$NORMAL
}

#显示每个远程主机的访问次数
remote_count(){
	echo -n "每个远程主机与本机的并发连接数:"
	$SUCCESS
	echo "$TCP_Remote_Count"
	$NORMAL
}

#显示每个端口的并发连接数

port_count(){
	echo -n "每个端口的并发连接数:"
	$SUCCESS
	echo "$TCP_Port_Count"
	$NORMAL
}

print_info(){
	echo -e "================================================================="
	$1
}

print_info tcp_total
print_info tcp_listen
print_info tcp_estab
print_info tcp_syn_recv
print_info tcp_time_wait
print_info tcp_time_wait1
print_info tcp_time_wait2
print_info udp_total
print_info unix_total
print_info remote_count
print_info port_count

echo -e "================================================================="

