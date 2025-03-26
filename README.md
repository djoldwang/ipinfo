# IPinfo - 简单高效的IP信息查询工具

IPinfo是一个轻量级的命令行工具，使用curl请求ipinfo.io API来快速查询IP地址的详细信息。本工具对ipinfo.io的数据进行格式化处理，以简洁易读的方式呈现，支持macOS和Linux系统。

一键部署请移步：https://github.com/wanglinkaik/easyipinfo

## 功能特点

- 基于curl ipinfo.io API进行IP信息查询
- 快速查询任意IP地址的基本信息或完整信息
- 支持从剪贴板自动获取IP地址
- 安装简便，使用别名`a`快速访问
- 全面支持macOS和Linux系统
- 支持bash和zsh等不同shell环境

## 安装方法

### 自动安装

使用提供的安装脚本，一键完成安装：

```bash
sh install.sh
```

### 手动安装

1. 将`IPInfoQuery.sh`复制到您想要的位置（推荐`~/.ipinfo/`目录）
2. 确保脚本有执行权限：`chmod +x ~/.ipinfo/IPInfoQuery.sh`
3. 在您的shell配置文件（`.bashrc`或`.zshrc`）中添加别名：
   ```bash
   alias a='~/.ipinfo/IPInfoQuery.sh'
   ```
4. 重启终端或执行`source ~/.bashrc`（或`source ~/.zshrc`）

## 使用方法

### 基本用法

```bash
# 查询特定IP地址的基本信息
a 8.8.8.8

# 查询剪贴板中IP地址的基本信息
a

# 查询特定IP地址的完整信息
a -a 8.8.8.8
```

### 参数选项

| 参数 | 说明 |
|------|------|
| `-a`, `--all`, `all`, `a` | 显示完整的IP信息 |
| `-h`, `--help` | 显示帮助信息 |

### 使用示例

```bash
# 基本查询
a 8.8.8.8        # 查询基本信息

# 完整信息查询（多种等效写法）
a -a 8.8.8.8     # 使用-a参数
a 8.8.8.8 -a     # 参数位置灵活
a 8.8.8.8 a      # 简写形式
a all 8.8.8.8    # 使用all参数
a 8.8.8.8 all    # all参数位置可调

# 剪贴板查询
a                # 使用剪贴板中的IP地址
```

## 卸载方法

使用提供的卸载脚本，一键完成卸载：

```bash
sh uninstall.sh
```

## 系统要求

- macOS或Linux系统
- bash或zsh shell
- 基本命令行工具：curl, grep, sed等
- 可选：jq (提供更美观的JSON输出)

## 注意事项

- 该工具使用`ipinfo.io`API获取IP信息，请遵守其使用条款
- 未提供IP时，会尝试从剪贴板获取，请确保剪贴板中包含有效IP地址
- 如需查看帮助信息，请使用`a -h`或`a --help`命令

## 贡献

欢迎提交 Issue 和 Pull Request！

## 更新日志

### v1.0.0
- 初始版本发布
- 支持基本的 IP 信息查询
- 支持完整信息查询
- 支持剪贴板功能
- 支持 root 用户和普通用户
- 支持 bash 和 zsh shell
