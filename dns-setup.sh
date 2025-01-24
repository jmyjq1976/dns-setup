#!/bin/bash

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    echo "请使用 root 权限运行此脚本"
    exit 1
fi

# DNS 服务器配置
declare -A DNS_SERVERS=(
    ["Default"]="154.83.83.83"
    ["HK"]="154.83.83.84"
    ["JP"]="154.83.83.85"
    ["TW"]="154.83.83.86"
    ["SG"]="154.83.83.87"
    ["US"]="154.83.83.88"
    ["UK"]="154.83.83.89"
    ["DE"]="154.83.83.90"
)

# 检查并处理 systemd-resolved
if systemctl is-active systemd-resolved &>/dev/null; then
    echo "检测到 systemd-resolved 正在运行，正在停止服务..."
    systemctl disable --now systemd-resolved
    echo "已停止并禁用 systemd-resolved 服务"
fi

# 检查并处理 resolvconf
if systemctl is-active resolvconf &>/dev/null; then
    echo "检测到 resolvconf 正在运行，正在停止服务..."
    systemctl disable --now resolvconf
    echo "已停止并禁用 resolvconf 服务"
fi

# 检查并处理文件锁定状态
if lsattr /etc/resolv.conf 2>/dev/null | grep -q '^....i'; then
    echo "检测到 /etc/resolv.conf 已被锁定，正在解锁..."
    chattr -i /etc/resolv.conf
fi

# 备份原有配置
if [ -f /etc/resolv.conf ]; then
    echo "备份原有 DNS 配置..."
    cp -f /etc/resolv.conf /etc/resolv.conf.bak
    rm -f /etc/resolv.conf
fi

# 显示可用的 DNS 选项
echo "请选择 DNS 服务器位置："
echo "1) Default 154.83.83.83"
echo "2) 香港 (HK) 154.83.83.84"
echo "3) 日本 (JP) 154.83.83.85"
echo "4) 台湾 (TW) 154.83.83.86"
echo "5) 新加坡 (SG) 154.83.83.87"
echo "6) 美国 (US) 154.83.83.88"
echo "7) 英国 (UK) 154.83.83.89"
echo "8) 德国 (DE) 154.83.83.90"

# 读取用户输入
read -p "请输入选项 (1-8): " choice

# 根据用户选择设置 DNS
case $choice in
    1) selected="Default" ;;
    2) selected="HK" ;;
    3) selected="JP" ;;
    4) selected="TW" ;;
    5) selected="SG" ;;
    6) selected="US" ;;
    7) selected="UK" ;;
    8) selected="DE" ;;
    *) 
        echo "无效选项，使用默认 DNS"
        selected="Default"
        ;;
esac

# 创建新的 resolv.conf
echo "nameserver ${DNS_SERVERS[$selected]}" > /etc/resolv.conf

# 锁定文件防止修改
chattr +i /etc/resolv.conf

echo "DNS 已设置为 ${selected} (${DNS_SERVERS[$selected]})"
echo "文件已锁定，防止系统自动修改"
echo "如需修改 DNS，请先使用 'sudo chattr -i /etc/resolv.conf' 解锁文件"
echo "或重新运行此脚本"

# 测试 DNS 是否正常工作
if ping -c 1 google.com &> /dev/null; then
    echo "DNS 配置测试成功"
else
    echo "警告：DNS 可能配置有误，请检查网络连接"
fi
