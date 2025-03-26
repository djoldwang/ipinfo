#!/bin/bash

# 获取剪贴板内容
get_clipboard_content() {
  local clipboard_content=""
  if command -v pbpaste &> /dev/null; then
    clipboard_content=$(pbpaste)
  elif command -v xclip &> /dev/null; then
    clipboard_content=$(xclip -o)
  else
    echo "错误: 无法获取剪贴板内容，请手动输入 IP 地址。" >&2
    return 1
  fi
  
  # 尝试从剪贴板内容中提取IP地址
  local ip_regex='([0-9]{1,3}\.){3}[0-9]{1,3}'
  local extracted_ip=$(echo "$clipboard_content" | grep -o "$ip_regex" | head -1)
  
  if [ -n "$extracted_ip" ]; then
    # 如果找到IP地址，直接返回
    echo "$extracted_ip"
  else
    # 否则过滤掉一些明显不是IP地址的内容
    if echo "$clipboard_content" | grep -q "source\|exec\|zsh\|bash"; then
      echo "需要手动输入IP地址" # 返回一个明显无效的值，会触发错误但不显示命令文本
    else
      # 限制长度并清理格式
      echo "$clipboard_content" | tr -d '\n\r\t' | cut -c1-30 | xargs
    fi
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
  echo ""
  echo "使用别名 'a' 的快捷用法:"
  echo "  a 8.8.8.8                     # 查询基本信息"
  echo "  a                             # 使用剪贴板中的 IP 地址查询"
  echo ""
  echo "  查询完整信息的多种写法（效果相同）:"
  echo "  a -a 8.8.8.8                  # 使用 -a 参数"
  echo "  a 8.8.8.8 -a                  # 参数位置灵活"
  echo "  a 8.8.8.8 a                   # 简写形式"
  echo "  a 8.8.8.8 all                 # 使用 all 参数"
  echo "  a all 8.8.8.8                 # 使用 all 参数"
}

# 验证 IP 地址格式
validate_ip() {
  local ip=$1
  local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
  
  if [[ ! $ip =~ $regex ]]; then
    return 1
  fi
  
  # 验证每个段落的范围
  IFS='.' read -r -a segments <<< "$ip"
  for segment in "${segments[@]}"; do
    if [[ $segment -lt 0 || $segment -gt 255 ]]; then
      return 1
    fi
  done
  
  return 0
}

# 格式化基本输出
format_basic_output() {
  local json=$1
  echo "$json" | jq -r '
    "IP地址: \(.ip // "未知")",
    "国家/地区: \(.country // "未知")",
    "城市: \(.city // "未知")",
    "组织: \(.org // "未知")"
  ' 2>/dev/null || {
    # 如果 jq 不可用，使用 grep 和 awk
    echo "$json" | grep -E '("ip"|"country"|"city"|"org")' | 
    awk -F"\"" '{print $2": "$4}' |
    sed 's/ip/IP地址/; s/country/国家\/地区/; s/city/城市/; s/org/组织/'
  }
}

# 处理 IP 地址
ip() {
  local ip_address=""
  local show_all=false

  # 解析参数
  while [[ $# -gt 0 ]]; do
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
        if [[ -z "$ip_address" ]]; then
          ip_address="$1"
        fi
        shift
        ;;
    esac
  done

  # 如果没有提供 IP 地址，从剪贴板获取
  if [[ -z "$ip_address" ]]; then
    ip_address=$(get_clipboard_content) || return 1
    
    # 如果获取到的是提示文本，显示特定错误
    if [ "$ip_address" = "需要手动输入IP地址" ]; then
      echo "错误: 请提供有效的IP地址，剪贴板内容无效" >&2
      show_help
      return 1
    fi
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
    if command -v jq &> /dev/null; then
      echo "$response" | jq .
    else
      echo "$response" | sed 's/,/,\n/g; s/{/{\n/g; s/}/\n}/g'
    fi
  else
    format_basic_output "$response"
  fi
}

# 执行主函数
ip "$@"
