#!/bin/sh

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"

# 如果脚本被作为安装脚本运行
if [ "$(basename "$0")" = "IPinfo-install.sh" ]; then
    # 确保脚本有执行权限
    chmod +x "$0"

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

    # 复制脚本到用户家目录
    cp "$0" "$TARGET_SCRIPT"

    # 确保脚本有执行权限
    chmod +x "$TARGET_SCRIPT"

    # 检查是否已经存在别名
    if grep -q "alias a=" "$SHELL_RC"; then
        echo "警告: 别名 'a' 已存在，将被更新"
        # 删除旧的别名定义（兼容 Linux 和 macOS）
        case "$(uname)" in
            "Darwin")
                # 只删除与我们脚本相关的别名
                sed -i '' '/alias a=.*IPInfoQuery.sh/d' "$SHELL_RC"
                ;;
            *)
                # 只删除与我们脚本相关的别名
                sed -i '/alias a=.*IPInfoQuery.sh/d' "$SHELL_RC"
                ;;
        esac
    fi

    # 清理可能存在的旧帮助代码
    case "$(uname)" in
        "Darwin")
            # 备份原文件
            cp "$SHELL_RC" "$SHELL_RC.bak.$(date +%s)"
            # 删除旧的帮助信息代码块
            sed -i '' '/^# IPinfo帮助信息/,/^fi$/d' "$SHELL_RC"
            sed -i '' '/ipinfo_help.sh/d' "$SHELL_RC"
            ;;
        *)
            # 删除旧的帮助信息代码块
            sed -i '/^# IPinfo帮助信息/,/^fi$/d' "$SHELL_RC"
            sed -i '/ipinfo_help.sh/d' "$SHELL_RC"
            ;;
    esac

    # 添加新的别名，确保有一个前导换行符
    echo "" >> "$SHELL_RC"
    echo "alias a='$TARGET_SCRIPT'" >> "$SHELL_RC"

    # 将变量值保存到临时变量中
    TARGET_DIR_VAL="$TARGET_DIR"

    # 直接在shell配置文件中添加显示帮助信息的代码块，确保有换行符
    cat >> "$SHELL_RC" << EOF

# IPinfo帮助信息 - 只显示一次
if [ ! -f "$TARGET_DIR_VAL/.help_shown" ]; then
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
  touch "$TARGET_DIR_VAL/.help_shown"
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
fi

# IP 查询功能
# 获取剪贴板内容
get_clipboard_content() {
  local clipboard_content=""
  if command -v pbpaste >/dev/null 2>&1; then
    clipboard_content=$(pbpaste)
  elif command -v xclip >/dev/null 2>&1; then
    clipboard_content=$(xclip -o)
  else
    echo "错误: 无法获取剪贴板内容，请手动输入 IP 地址。" >&2
    return 1
  fi
  
  # 尝试从剪贴板内容中提取IP地址
  local ip_regex='([0-9]{1,3}\.){3}[0-9]{1,3}'
  local extracted_ip=$(echo "$clipboard_content" | grep -o "$ip_regex" | head -1)
  
  if [ -n "$extracted_ip" ]; then
    echo "$extracted_ip"
  else
    echo "$clipboard_content" | tr -d '\n\r\t' | xargs
  fi
}

# 显示帮助信息
show_help() {
  echo "用法: $(basename "$0") [选项] [IP地址]"
  echo "选项:"
  echo "  -a, --all    显示完整的 IP 信息"
  echo "  -h, --help   显示此帮助信息"
  echo ""
  echo "如果不提供 IP 地址，将尝试从剪贴板获取。"
  echo "示例:"
  echo "  $(basename "$0") 8.8.8.8        # 查询基本信息"
  echo "  $(basename "$0") -a 8.8.8.8     # 查询完整信息"
  echo "  $(basename "$0")                # 使用剪贴板中的 IP 地址查询基本信息"
}

# 验证 IP 地址格式
validate_ip() {
  local ip="$1"
  local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
  
  if echo "$ip" | grep -qE "$regex"; then
    # 验证每个段落的范围
    local IFS='.'
    set -- $ip
    for segment in "$@"; do
      if [ "$segment" -lt 0 ] || [ "$segment" -gt 255 ]; then
        return 1
      fi
    done
    return 0
  fi
  return 1
}

# 格式化基本输出
format_basic_output() {
  local json="$1"
  if command -v jq >/dev/null 2>&1; then
    echo "$json" | jq -r '
      "IP地址: \(.ip // "未知")",
      "国家/地区: \(.country // "未知")",
      "城市: \(.city // "未知")",
      "组织: \(.org // "未知")"
    ' 2>/dev/null
  else
    # 如果 jq 不可用，使用 grep 和 awk
    echo "$json" | grep -E '("ip"|"country"|"city"|"org")' | 
    awk -F"\"" '{print $2": "$4}' |
    sed 's/ip/IP地址/; s/country/国家\/地区/; s/city/城市/; s/org/组织/'
  fi
}

# 处理 IP 地址
ip() {
  local ip_address=""
  local show_all=false

  # 解析参数
  while [ $# -gt 0 ]; do
    case "$1" in
      -a|-all|all|a)
        show_all=true
        shift
        ;;
      -h|--help)
        show_help
        return 0
        ;;
      -*)
        echo "错误: 未知选项 $1" >&2
        show_help
        return 1
        ;;
      *)
        if [ -z "$ip_address" ]; then
          ip_address="$1"
        fi
        shift
        ;;
    esac
  done

  # 如果没有提供 IP 地址，从剪贴板获取
  if [ -z "$ip_address" ]; then
    ip_address=$(get_clipboard_content) || return 1
    # 额外的清理，确保内容简短
    ip_address=$(echo "$ip_address" | cut -c1-100)
  fi

  # 验证 IP 地址
  if ! validate_ip "$ip_address"; then
    echo "错误: 无效的 IP 地址格式。剪切板内容: $ip_address" >&2
    return 1
  fi

  # 使用 curl 请求并处理错误
  local response
  response=$(curl -s "ipinfo.io/$ip_address" || { echo "错误: 请求失败，请检查网络连接" >&2; return 1; })
  
  # 检查响应是否包含错误
  if echo "$response" | grep -q "error"; then
    echo "错误: $(echo "$response" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)" >&2
    return 1
  fi

  # 根据模式参数决定输出方式
  if $show_all; then
    # 尝试使用 jq 美化输出，如果不可用则直接输出
    if command -v jq >/dev/null 2>&1; then
      echo "$response" | jq .
    else
      echo "$response" | sed 's/,/,\n/g; s/{/{\n/g; s/}/\n}/g'
    fi
  else
    format_basic_output "$response"
  fi
}

# 如果不是作为安装脚本运行，则执行 IP 查询功能
if [ "$(basename "$0")" != "IPinfo-install.sh" ]; then
    ip "$@"
fi 