#!/bin/sh

# 确保脚本有执行权限
chmod +x "$0"

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
IPINFO_SCRIPT="$SCRIPT_DIR/IPInfoQuery.sh"

# 获取用户类型和目录
if [ "$(id -u)" = "0" ]; then
    # root 用户
    TARGET_DIR="/root/.ipinfo"
    if [ -f "/root/.zshrc" ]; then
        SHELL_RC="/root/.zshrc"
        SHELL_TYPE="zsh"
    elif [ -f "/root/.bashrc" ]; then
        SHELL_RC="/root/.bashrc"
        SHELL_TYPE="bash"
    elif [ -f "/root/.bash_profile" ]; then
        SHELL_RC="/root/.bash_profile"
        SHELL_TYPE="bash"
    else
        echo "错误: 未找到 root 用户的 shell 配置文件"
        exit 1
    fi
else
    # 普通用户
    TARGET_DIR="$HOME/.ipinfo"
    if [ -f "$HOME/.zshrc" ]; then
        SHELL_RC="$HOME/.zshrc"
        SHELL_TYPE="zsh"
    elif [ -f "$HOME/.bashrc" ]; then
        SHELL_RC="$HOME/.bashrc"
        SHELL_TYPE="bash"
    elif [ -f "$HOME/.bash_profile" ]; then
        SHELL_RC="$HOME/.bash_profile"
        SHELL_TYPE="bash"
    else
        echo "错误: 未找到 shell 配置文件"
        exit 1
    fi
fi

TARGET_SCRIPT="$TARGET_DIR/IPInfoQuery.sh"

# 创建目标目录
mkdir -p "$TARGET_DIR"

# 检查 IPInfoQuery.sh 是否存在
if [ ! -f "$IPINFO_SCRIPT" ]; then
    echo "错误: 未找到 IPInfoQuery.sh 文件"
    exit 1
fi

# 复制脚本到用户家目录
cp "$IPINFO_SCRIPT" "$TARGET_SCRIPT"

# 确保脚本有执行权限
chmod +x "$TARGET_SCRIPT"

# 检查是否已经存在别名
if grep -q "alias a=" "$SHELL_RC"; then
    echo "警告: 别名 'a' 已存在，将被更新"
    # 删除旧的别名定义（兼容 Linux 和 macOS）
    case "$(uname)" in
        "Darwin")
            sed -i '' '/alias a=.*IPInfoQuery.sh/d' "$SHELL_RC"
            ;;
        *)
            sed -i '/alias a=.*IPInfoQuery.sh/d' "$SHELL_RC"
            ;;
    esac
fi

# 添加新的别名
echo "alias a='$TARGET_SCRIPT'" >> "$SHELL_RC"

# 将帮助信息添加到shell配置中（只显示一次）
cat >> "$SHELL_RC" << EOF

# IPinfo帮助信息 - 只显示一次
if [ ! -f "$TARGET_DIR/.help_shown" ]; then
  echo ""
  echo "现在你可以使用 'a' 命令来查询 IP 信息了。"
  echo "示例："
  echo "  a 8.8.8.8        # 查询基本信息"
  echo "  a -a 8.8.8.8     # 查询完整信息"
  echo "  a 8.8.8.8 -a     # 查询完整信息（参数位置可调）"
  echo "  a 8.8.8.8 a      # 查询完整信息（简写）"
  echo "  a all 8.8.8.8    # 查询完整信息（使用 all 参数）"
  echo "  a 8.8.8.8 all    # 查询完整信息（all 参数位置可调）"
  echo "  a                # 使用剪贴板中的 IP 地址查询"
  touch "$TARGET_DIR/.help_shown"
fi
EOF

echo "安装完成！"
echo "正在重启 shell..."

# 直接重启shell，不考虑配置问题
if [ "$SHELL_TYPE" = "zsh" ]; then
    exec zsh
else
    exec bash
fi 