#!/bin/sh

# 确保脚本有执行权限
chmod +x "$0"

# 获取系统类型
SYSTEM_TYPE="$(uname)"

# 获取用户类型和目录
if [ "$(id -u)" = "0" ]; then
    # root 用户
    TARGET_DIR="/root/.ipinfo"
    # 检测shell配置文件（按优先级顺序）
    for RC_FILE in "/root/.zshrc" "/root/.bashrc" "/root/.bash_profile" "/root/.profile"; do
        if [ -f "$RC_FILE" ]; then
            SHELL_RC="$RC_FILE"
            SHELL_TYPE="${RC_FILE##*/}"
            SHELL_TYPE="${SHELL_TYPE#.}"
            SHELL_TYPE="${SHELL_TYPE%%rc*}"
            [ -z "$SHELL_TYPE" ] && SHELL_TYPE="bash"
            break
        fi
    done
    
    if [ -z "$SHELL_RC" ]; then
        echo "错误: 未找到 root 用户的 shell 配置文件"
        exit 1
    fi
else
    # 普通用户
    TARGET_DIR="$HOME/.ipinfo"
    # 检测shell配置文件（按优先级顺序）
    for RC_FILE in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
        if [ -f "$RC_FILE" ]; then
            SHELL_RC="$RC_FILE"
            SHELL_TYPE="${RC_FILE##*/}"
            SHELL_TYPE="${SHELL_TYPE#.}"
            SHELL_TYPE="${SHELL_TYPE%%rc*}"
            [ -z "$SHELL_TYPE" ] && SHELL_TYPE="bash"
            break
        fi
    done
    
    if [ -z "$SHELL_RC" ]; then
        echo "错误: 未找到 shell 配置文件"
        exit 1
    fi
fi

# 确定当前实际运行的shell
CURRENT_SHELL="$(basename "$SHELL")"
if [ -z "$CURRENT_SHELL" ]; then
    # 如果环境变量SHELL为空，尝试ps命令
    if command -v ps >/dev/null 2>&1; then
        CURRENT_SHELL="$(ps -p $$ -o comm=)"
    fi
fi
# 如果仍无法确定，使用配置文件推断的shell类型
[ -z "$CURRENT_SHELL" ] && CURRENT_SHELL="$SHELL_TYPE"

echo "检测到系统: $SYSTEM_TYPE"
echo "检测到shell: $CURRENT_SHELL"
echo "配置文件: $SHELL_RC"

# 删除别名配置和相关代码块
echo "正在删除别名配置..."

# 根据系统类型使用不同的sed命令
case "$SYSTEM_TYPE" in
    "Darwin")
        # macOS系统
        # 备份原文件
        cp "$SHELL_RC" "$SHELL_RC.bak.$(date +%s)"
        
        # 使用macOS版本的sed命令
        # 1. 删除别名定义
        sed -i '' '/alias a=.*IPInfoQuery.sh/d' "$SHELL_RC"
        # 2. 删除IPinfo帮助信息代码块 (从开始到结束)
        sed -i '' '/# IPinfo帮助信息/,/^fi$/d' "$SHELL_RC"
        ;;
    *)
        # Linux系统
        # 备份原文件
        cp "$SHELL_RC" "$SHELL_RC.bak.$(date +%s)"
        
        # 使用Linux版本的sed命令
        sed -i '/alias a=.*IPInfoQuery.sh/d' "$SHELL_RC"
        sed -i '/^# IPinfo帮助信息/,/^fi$/d' "$SHELL_RC"
        ;;
esac

# 删除安装目录
if [ -d "$TARGET_DIR" ]; then
    echo "正在删除安装目录..."
    rm -rf "$TARGET_DIR"
fi

# 清理可能的临时文件
rm -f "$HOME"/.ipinfo_help.sh 2>/dev/null || true

echo "卸载完成！"
echo "IPInfo 工具已成功卸载。"
echo ""
echo "正在重启 shell..."

# 根据实际运行的shell类型重启
case "$CURRENT_SHELL" in
    *zsh*)
        exec zsh
        ;;
    *bash*)
        exec bash
        ;;
    *)
        # 如果无法确定，尝试使用$SHELL环境变量
        if [ -n "$SHELL" ]; then
            exec "$SHELL"
        else
            # 最后的回退选项
            case "$SHELL_TYPE" in
                zsh)
                    exec zsh
                    ;;
                *)
                    exec bash
                    ;;
            esac
        fi
        ;;
esac 