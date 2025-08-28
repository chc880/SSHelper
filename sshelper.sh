#!/bin/bash

# ==============================================================================
# Fail2Ban & SSH Ultimate Management Script for Debian (v1.0)
#
# Author: Gemini
# Description: A comprehensive, menu-driven script to manage Fail2Ban and harden SSH.
#              - [FIXED] All 'read' commands now read from /dev/tty to allow
#                execution via curl/wget pipes.
# ==============================================================================

# --- 全局变量和颜色定义 ---
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly RED='\033[0;31m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# --- 辅助函数 ---
info() { echo -e "${GREEN}[INFO] $1${NC}"; }
warn() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }
check_root() { if [ "$(id -u)" -ne 0 ]; then error "此脚本需以root或sudo权限运行"; exit 1; fi; }
check_fail2ban_installed() { if command -v fail2ban-client &> /dev/null; then return 0; else return 1; fi; }
pause() { echo ""; read -p "按 [Enter] 键继续..." < /dev/tty; } # FIX

# --- 主菜单 ---
show_main_menu() {
    clear
    echo -e "${CYAN}====================================================${NC}"
    echo -e "${CYAN}     Fail2Ban & SSH 终极管理脚本 v1.0 (Debian)      ${NC}"
    echo -e "${CYAN}====================================================${NC}"
    echo "  1. Fail2Ban 管理 (状态、日志、解封...)"
    echo "  2. SSH 安全管理 (端口、密钥、密码登录...)"
    echo "  3. 安装与卸载"
    echo -e "\n  q. 退出脚本"
    echo -e "${CYAN}----------------------------------------------------${NC}"
}

# ==============================================================================
# 模块一：FAIL2BAN 管理
# ==============================================================================
show_fail2ban_menu() {
    clear
    echo -e "${CYAN}------------------ Fail2Ban 管理 ------------------${NC}"
    echo "  1. 查看服务状态及被封禁IP"
    echo "  2. 解封 IP 地址"
    echo "  3. 查看实时日志"
    echo "  4. 重启 Fail2Ban 服务"
    echo -e "\n  ${YELLOW}b. 返回主菜单${NC}"
    echo -e "${CYAN}-------------------------------------------------${NC}"
}
manage_fail2ban() {
    if ! check_fail2ban_installed; then error "Fail2Ban 未安装，请先从'安装'菜单安装。"; pause; return; fi
    while true; do show_fail2ban_menu; read -p "选择: " choice < /dev/tty # FIX
        case "$choice" in
            1) show_status; pause ;;
            2) manage_unban ;;
            3) show_log; pause ;;
            4) restart_fail2ban; pause ;;
            b|B) break ;;
            *) error "无效输入"; sleep 1 ;;
        esac
    done
}
show_status() { info "--- Fail2Ban服务状态 ---"; systemctl status fail2ban --no-pager -l; echo ""; info "--- [sshd]Jail封禁IP列表 ---"; local banned_ips; banned_ips=$(fail2ban-client status sshd | grep 'Banned IP list:' | sed 's/.*Banned IP list:\s*//'); if [ -z "$banned_ips" ]; then echo -e "${GREEN}当前无IP被封禁${NC}"; else echo -e "${RED}$banned_ips${NC}"; fi; }
show_log() { local log_path="/var/log/fail2ban.log"; echo -e "${YELLOW}--- 实时日志 ${log_path} (Ctrl+C退出) ---${NC}"; if [ -f "$log_path" ]; then tail -f "$log_path"; else error "日志文件不存在"; fi; }
restart_fail2ban() { info "重启Fail2Ban..."; systemctl restart fail2ban; sleep 1; if systemctl is-active --quiet fail2ban; then info "✅ Fail2Ban运行中"; else error "❌ Fail2Ban重启失败!"; fi; }
manage_unban() { while true; do clear; echo -e "${CYAN}--- 解封管理 ---\n  1. 手动输入IP\n  2. 列表选择\n  3. 全部解封\n\n  ${YELLOW}b. 返回${NC}\n${CYAN}----------------${NC}"; read -p "选择: " choice < /dev/tty; case "$choice" in 1) unban_by_ip; pause ;; 2) unban_by_number; pause ;; 3) unban_all_sshd; pause ;; b|B) break ;; *) error "无效输入"; sleep 1 ;; esac; done; } # FIX
unban_by_ip() { read -p "请输入IP: " ip < /dev/tty; if [ -z "$ip" ]; then error "IP不能为空"; return; fi; info "尝试从[sshd]解封IP: ${ip}..."; local out; out=$(fail2ban-client set sshd unbanip "$ip"); if [ "$out" = "1" ]; then info "✅ 成功解封"; else warn "IP未在[sshd]封禁列表或解封失败"; fi; } # FIX
unban_by_number() { info "获取IP列表..."; local ip_str; ip_str=$(fail2ban-client status sshd | grep 'Banned IP list:' | sed 's/.*Banned IP list:\s*//'); if [ -z "$ip_str" ]; then info "当前无被封禁IP"; return; fi; local -a ips; read -r -a ips <<< "$ip_str"; echo "当前被封禁IP:"; for i in "${!ips[@]}"; do echo -e "  ${YELLOW}$((i+1)).${NC} ${ips[$i]}"; done; read -p "输入编号: " num < /dev/tty; if ! [[ "$num" =~ ^[0-9]+$ ]] || [ "$num" -lt 1 ] || [ "$num" -gt ${#ips[@]} ]; then error "无效编号"; return; fi; local ip=${ips[$((num-1))]}; info "解封IP: ${ip}..."; local out; out=$(fail2ban-client set sshd unbanip "$ip"); if [ "$out" = "1" ]; then info "✅ 成功解封"; else warn "解封失败"; fi; } # FIX
unban_all_sshd() { warn "确定解封SSHD jail中所有IP?"; read -p "(y/N): " choice < /dev/tty; case "$choice" in y|Y) info "执行解封所有IP..."; local ip_str; ip_str=$(fail2ban-client status sshd | grep 'Banned IP list:' | sed 's/.*Banned IP list:\s*//'); if [ -z "$ip_str" ]; then info "无IP需解封"; return; fi; local -a ips; read -r -a ips <<< "$ip_str"; local count=0; for ip in "${ips[@]}"; do if [ "$(fail2ban-client set sshd unbanip "$ip")" = "1" ]; then ((count++)); fi; done; info "✅ 操作完成, 共解封${count}个IP";; *) info "操作取消";; esac; } # FIX

# ==============================================================================
# 模块二：SSH 安全管理
# ==============================================================================
show_ssh_menu() {
    clear
    echo -e "${CYAN}------------------ SSH 安全管理 ------------------${NC}"
    echo "  1. 查看当前 SSH 配置"
    echo "  2. 修改 SSH 端口号"
    echo "  3. 管理密码登录 (开启/关闭)"
    echo "  4. 添加公钥 (支持GitHub用户名)"
    echo "  5. 修改用户密码"
    echo "  6. 重启 SSHD 服务"
    echo -e "\n  ${YELLOW}b. 返回主菜单${NC}"
    echo -e "${CYAN}-------------------------------------------------${NC}"
}
manage_ssh() {
    while true; do show_ssh_menu; read -p "选择: " choice < /dev/tty # FIX
        case "$choice" in
            1) view_ssh_config; pause ;;
            2) change_ssh_port; pause ;;
            3) toggle_password_auth; pause ;;
            4 | 4) add_key_from_input; pause ;;
            5) change_user_password; pause ;;
            6) restart_sshd; pause ;;
            b|B) break ;;
            *) error "无效输入"; sleep 1 ;;
        esac
    done
}
get_ssh_config_value() { local val; val=$(grep -i "^\s*${1}\s" /etc/ssh/sshd_config | awk '{print $2}'); echo "${val:-${2}}"; }
view_ssh_config() { info "--- 当前 SSH 服务核心配置 ---"; local port; port=$(get_ssh_config_value "Port" "22"); local pass_auth; pass_auth=$(get_ssh_config_value "PasswordAuthentication" "yes"); local pubkey_auth; pubkey_auth=$(get_ssh_config_value "PubkeyAuthentication" "yes"); local root_login; root_login=$(get_ssh_config_value "PermitRootLogin" "prohibit-password"); printf "%-25s: %s\n" "SSH 端口号" "$port"; printf "%-25s: %s\n" "允许密码登录" "$pass_auth"; printf "%-25s: %s\n" "允许密钥登录" "$pubkey_auth"; printf "%-25s: %s\n" "允许root登录策略" "$root_login"; }
change_ssh_port() {
    local current_port; current_port=$(get_ssh_config_value "Port" "22"); info "当前SSH端口是: ${current_port}"
    read -p "输入新端口号(1025-65535): " new_port < /dev/tty # FIX
    if ! [[ "$new_port" =~ ^[0-9]+$ ]] || [ "$new_port" -lt 1025 ] || [ "$new_port" -gt 65535 ]; then error "无效端口号"; return; fi
    info "修改SSH配置文件..."; if grep -q -i '^\s*Port\s' /etc/ssh/sshd_config; then sed -i -E "s/^\s*Port\s+[0-9]+/Port ${new_port}/I" /etc/ssh/sshd_config; else echo -e "\nPort ${new_port}" >> /etc/ssh/sshd_config; fi
    info "SSH端口已更新为 ${new_port}"; if check_fail2ban_installed; then info "同步更新Fail2Ban配置..."; sed -i "/^\[sshd\]/,/^\[/ s/port\s*=.*/port = ${new_port}/" /etc/fail2ban/jail.local; info "Fail2Ban [sshd] jail 端口已同步"; fi
    warn "配置已修改! 必须重启SSHD服务才能生效"; restart_sshd
}
change_user_password() { read -p "输入用户名(默认root): " user < /dev/tty; user=${user:-root}; info "为用户'${user}'修改密码..."; passwd "$user"; } # FIX
add_key_from_input() {
    read -p "请输入要添加密钥的用户名 (默认root): " username < /dev/tty # FIX
    username=${username:-root}; if ! id "$username" &>/dev/null; then error "用户'${username}'不存在"; return; fi
    read -p "请输入 GitHub 用户名 或 完整的公钥URL: " user_input < /dev/tty # FIX
    if [ -z "$user_input" ]; then error "输入不能为空。"; return; fi
    local key_url; if [[ "$user_input" == http* ]]; then info "检测到完整URL，将直接使用: ${user_input}"; key_url="$user_input"; else info "检测到GitHub用户名，自动构造URL..."; key_url="https://github.com/${user_input}.keys"; info "将从以下URL获取公钥: ${key_url}"; fi
    info "下载公钥..."; local key_content; key_content=$(curl -sSL "$key_url"); if [ -z "$key_content" ] || [[ ! "$key_content" == ssh-* ]]; then error "下载公钥失败或内容无效。请检查URL或用户名。"; return; fi
    local home_dir; home_dir=$(eval echo "~$username"); local ssh_dir="${home_dir}/.ssh"; local auth_keys_file="${ssh_dir}/authorized_keys"
    info "配置目录权限..."; mkdir -p "$ssh_dir"; touch "$auth_keys_file"; chown -R "${username}:${username}" "$ssh_dir"; chmod 700 "$ssh_dir"; chmod 600 "$auth_keys_file"
    info "追加公钥到 ${auth_keys_file}..."; local tmp_key_file; tmp_key_file=$(mktemp); echo "$key_content" > "$tmp_key_file"
    if grep -qFf "$tmp_key_file" "$auth_keys_file"; then info "URL中的一个或多个公钥已存在于authorized_keys中，未添加重复项。"; else cat "$tmp_key_file" >> "$auth_keys_file"; info "✅ 公钥已成功添加。"; fi; rm -f "$tmp_key_file"
}
toggle_password_auth() {
    local status; status=$(get_ssh_config_value "PasswordAuthentication" "yes"); info "当前密码登录状态: ${status}"
    local new_status; if [ "$status" = "yes" ]; then
        warn "准备关闭密码登录!"; warn "关闭前请务必确认密钥登录可用, 否则将无法登录!"; read -p "确定关闭? (y/N): " choice < /dev/tty; if [[ "$choice" != "y" && "$choice" != "Y" ]]; then info "操作取消"; return; fi; new_status="no" # FIX
    else read -p "确定开启密码登录? (y/N): " choice < /dev/tty; if [[ "$choice" != "y" && "$choice" != "Y" ]]; then info "操作取消"; return; fi; new_status="yes"; fi # FIX
    info "修改SSH配置文件..."; if grep -q -i '^\s*PasswordAuthentication\s' /etc/ssh/sshd_config; then sed -i -E "s/^\s*PasswordAuthentication\s+(yes|no)/PasswordAuthentication ${new_status}/I" /etc/ssh/sshd_config; else echo -e "\nPasswordAuthentication ${new_status}" >> /etc/ssh/sshd_config; fi
    info "密码登录已设为: ${new_status}"; warn "配置已修改! 必须重启SSHD服务才能生效"; restart_sshd
}
restart_sshd() { warn "重启SSHD可能中断当前连接!"; read -p "确定? (y/N): " choice < /dev/tty; case "$choice" in y|Y) info "重启SSHD..."; systemctl restart sshd; sleep 1; if systemctl is-active --quiet sshd; then info "✅ SSHD运行中"; else error "❌ SSHD重启失败!"; fi;; *) info "操作取消";; esac; } # FIX

# ==============================================================================
# 模块三：安装与卸载
# ==============================================================================
show_installation_menu() { clear; echo -e "${CYAN}------------------ 安装与卸载 ------------------\n  1. 安装 / 重新安装 Fail2Ban\n  2. 卸载 Fail2Ban\n\n  ${YELLOW}b. 返回主菜单${NC}\n${CYAN}-------------------------------------------------${NC}"; }
manage_installation() {
    while true; do show_installation_menu; read -p "选择: " choice < /dev/tty # FIX
        case "$choice" in
            1) do_install; pause ;;
            2) do_uninstall; pause ;;
            b|B) break ;;
            *) error "无效输入"; sleep 1 ;;
        esac
    done
}
do_install() { clear; if check_fail2ban_installed; then warn "Fail2Ban已安装"; read -p "卸载重装? (y/N): " choice < /dev/tty; case "$choice" in y|Y) info "执行卸载..."; _internal_uninstall; info "开始重装...";; *) info "操作取消"; return;; esac; fi; info "安装Fail2Ban..."; apt-get update -y &> /dev/null || { error "源更新失败"; return; }; apt-get install -y fail2ban || { error "安装失败"; return; }; info "创建和配置jail.local..."; if [ -f /etc/fail2ban/jail.local ]; then mv /etc/fail2ban/jail.local "/etc/fail2ban/jail.local.bak_$(date +%F_%T)"; info "备份旧配置"; fi; cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local; configure_sshd_jail; info "启动服务..."; systemctl enable fail2ban >/dev/null 2>&1; systemctl restart fail2ban || { error "服务启动失败!"; return; }; echo ""; info "🎉 安装配置完成!"; echo -e "\n${CYAN}SSHD防护状态:${NC}"; fail2ban-client status sshd; } # FIX
do_uninstall() { clear; if ! check_fail2ban_installed; then warn "未安装"; return; fi; warn "将彻底移除Fail2Ban!"; read -p "确定? (y/N): " choice < /dev/tty; case "$choice" in y|Y) _internal_uninstall; rm -f /etc/fail2ban/jail.local.bak*; info "✅ 已卸载";; *) info "操作取消";; esac; } # FIX
_internal_uninstall() { info "停止服务..."; systemctl stop fail2ban &> /dev/null; systemctl disable fail2ban &> /dev/null; info "卸载软件包..."; apt-get purge -y fail2ban &> /dev/null || { error "卸载失败"; return; }; info "清理文件..."; rm -f /etc/fail2ban/jail.local; rm -f /etc/fail2ban/fail2ban.local; }
configure_sshd_jail() { info "--- 自定义防护参数 ---"; local d_bantime="1h"; local d_findtime="10m"; local d_maxretry="3"; read -p "封禁时长(默认:${d_bantime}): " bantime < /dev/tty; bantime=${bantime:-$d_bantime}; read -p "检测窗口(默认:${d_findtime}): " findtime < /dev/tty; findtime=${findtime:-$d_findtime}; read -p "最大次数(默认:${d_maxretry}): " maxretry < /dev/tty; maxretry=${maxretry:-$d_maxretry}; local port; port=$(get_ssh_config_value "Port" "22"); clear; info "配置确认:"; echo -e "  - ${CYAN}SSH端口:${NC} ${port}(自动)\n  - ${CYAN}封禁时长:${NC} ${bantime}\n  - ${CYAN}检测窗口:${NC} ${findtime}\n  - ${CYAN}最大次数:${NC} ${maxretry}"; echo ""; info "写入配置..."; sed -i "/^\[sshd\]/,/^\[/ s/enabled[[:space:]]*=.*/enabled = true/" /etc/fail2ban/jail.local; sed -i "/^\[sshd\]/,/^\[/ s/bantime[[:space:]]*=.*/bantime = ${bantime}/" /etc/fail2ban/jail.local; sed -i "/^\[sshd\]/,/^\[/ s/findtime[[:space:]]*=.*/findtime = ${findtime}/" /etc/fail2ban/jail.local; sed -i "/^\[sshd\]/,/^\[/ s/maxretry[[:space:]]*=.*/maxretry = ${maxretry}/" /etc/fail2ban/jail.local; sed -i "/^\[sshd\]/,/^\[/ s/port\s*=.*/port = ${port}/" /etc/fail2ban/jail.local; sed -i '/^\[sshd\]/,/^\[/ { /^\s*logpath\s*=/d; /^\s*backend\s*=/d; }' /etc/fail2ban/jail.local; if [ -f /var/log/auth.log ]; then info "检测到传统日志, 配置logpath..."; sed -i "/^\[sshd\]/a logpath = /var/log/auth.log" /etc/fail2ban/jail.local; else info "检测到新版系统, 配置backend=systemd..."; sed -i "/^\[sshd\]/a backend = systemd" /etc/fail2ban/jail.local; fi; } # FIX (3x)

# --- 主循环 ---
main() {
    check_root
    while true; do show_main_menu; read -p "请输入您的选择 [1-3, q]: " choice < /dev/tty # FIX
        case "$choice" in
            1) manage_fail2ban ;;
            2) manage_ssh ;;
            3) manage_installation ;;
            q|Q) echo "正在退出脚本..."; exit 0 ;;
            *) error "无效输入"; sleep 1 ;;
        esac
    done
}

# --- 脚本入口 ---
main
