# SSHelper 🛡️

**您的一站式 Debian / Ubuntu 服务器安全助手**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> SSHelper 是一个强大而友好的交互式Bash脚本，旨在将繁琐的 Fail2Ban 管理与 SSH 安全加固过程自动化。通过一个清晰的菜单，它让服务器安全设置变得前所未有的简单、高效和可靠，无论是新手还是经验丰富的管理员都能轻松上手。

---

## ✨ 项目亮点 (Features)

这个脚本不仅仅是安装工具，更是一个综合性的安全管理平台。

#### 全功能 Fail2Ban 管理
- **智能安装**: 一键完成Fail2Ban的安装、配置与启动。
- **状态监控**: 清晰地查看服务状态和当前被封禁的IP列表。
- **灵活解封**: 支持按IP、按编号列表或一键全部解封，管理高效。
- **实时日志**: 无需手动查找日志文件，直接在菜单中实时查看Fail2Ban日志。

#### 一站式 SSH 安全加固
- **可视化配置**: 在修改前，清晰地查看当前SSH的核心安全配置。
- **安全修改端口**: 修改SSH端口后，脚本会自动同步更新Fail2Ban的配置，确保防护无缝衔接。
- **密钥快速部署**: **支持GitHub用户名！** 只需输入用户名即可自动获取公钥并完成配置，也支持从任意URL获取。
- **密码登录管理**: 一键安全地开启或关闭密码登录，并在关闭前给出严重警告，防止误操作。
- **密码修改**: 快速为指定用户修改密码。

#### 智能化与自动化
- **系统环境自适应**: 自动检测系统日志模式（`journald` vs `/var/log/auth.log`），完美适配Debian 12等新版系统。
- **SSH端口自动发现**: 在配置Fail2Ban时，自动从您的SSH配置文件中读取当前端口号。
- **服务重启提示**: 在任何关键配置被修改后，脚本都会智能地提示并引导您重启相关服务。

#### 极致的用户体验
- **菜单驱动**: 所有功能都通过清晰的、分层的菜单完成，无需记忆任何命令。
- **彩色输出**: 通过不同颜色的文本，高亮显示关键信息、警告和错误，一目了然。
- **安全确认**: 在执行卸载、重启SSHD等高风险操作前，会要求用户确认，防止意外。

---

## 🎯 适用对象 (Target Audience)

* 拥有Debian或Ubuntu服务器的所有用户。
* 希望快速、可靠地完成基础安全配置的开发者和运维人员。
* 对Linux命令行和配置文件不太熟悉的初学者。
* 希望节约时间，用自动化脚本替代重复性工作的效率追求者。

---

## 🚀 快速开始 (Quick Start)

您只需在您的 Debian / Ubuntu 终端中复制并运行下面的一行命令即可。

*(推荐使用 `curl`，大多数系统默认安装)*

### 使用 `curl`
```bash
curl -sSL -o sshelper.sh https://raw.githubusercontent.com/chc880/SSHelper/main/sshelper.sh && chmod +x sshelper.sh && sudo ./sshelper.sh
````

### 或者使用 `wget`

```bash
wget -q -O sshelper.sh https://raw.githubusercontent.com/chc880/SSHelper/main/sshelper.sh && chmod +x sshelper.sh && sudo ./sshelper.sh
```

> **这条命令做了什么？**
>
> 1.  **下载脚本**: 使用 `curl` 或 `wget` 将最新的 `sshelper.sh` 脚本下载到您当前所在的目录。
> 2.  **授予权限**: 使用 `chmod +x` 给予该脚本可执行权限。
> 3.  **运行脚本**: 使用 `sudo ./sshelper.sh` 以root权限执行脚本。
>
> **提示**: 首次运行后，脚本文件会保留。下次您想再次使用时，只需在同一个目录下执行 `sudo ./sshelper.sh` 即可。

-----

### 开发者方式 (Developer Mode)

如果您希望先审查代码、进行修改或参与贡献，建议使用传统 `git clone` 的方式：

1.  **克隆仓库**

    ```bash
    git clone https://github.com/chc880/SSHelper.git
    ```

2.  **进入目录**

    ```bash
    cd SSHelper
    ```

3.  **以root权限运行脚本**

    ```bash
    sudo bash sshelper.sh
    ```

-----

## 🎬 项目演示 (Demo)



-----

## 🤝 贡献 (Contributing)

欢迎提交 Pull Requests 或开 Issues 来让这个项目变得更好！无论是功能建议、代码优化还是Bug修复，我们都非常欢迎。

## 📄 开源许可 (License)

本项目采用 [MIT](https://opensource.org/licenses/MIT) 许可协议。

```
```
