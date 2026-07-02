# Stardew Mod Manager

一个用 SwiftUI 写的 macOS SMAPI 模组管理器。

它直接读取本地 `Mods` 文件夹，用来查看模组状态、排查常见依赖问题、安装模组、检查更新，并通过 SMAPI 启动游戏。项目目前还是 beta，但日常使用需要的扫描、安装、启停和更新检查已经可以工作。

<img width="2308" height="1692" alt="Stardew Mod Manager 主界面" src="https://github.com/user-attachments/assets/7bab5d3e-b179-4132-97c5-9b3c563b64e3" />

## 目前支持

- 自动定位 Steam 版 Stardew Valley 的 `Mods` 文件夹，也可以手动选择其他目录
- 递归读取 `manifest.json`，区分代码模组和内容包
- 按名称、UniqueID 或路径搜索，并按启用、异常、可更新和停用状态筛选
- 检查缺失的必需依赖、重复 UniqueID 和无法读取的清单文件
- 显示版本、作者、依赖、更新源、最低 SMAPI / 游戏版本等信息
- 直接安装模组文件夹或 `.zip` 压缩包；同一 UniqueID 的旧版本会在安装时替换
- 安装单个翻译文件、翻译文件夹或 `.zip` 翻译包
- 从详情页、工具栏或右键菜单启用和停用模组
- 通过 SMAPI 接口检查模组更新，并打开对应的下载页面
- 通过 `StardewModdingAPI` 在 macOS 自带终端中启动游戏并查看 SMAPI 输出
- 简体中文和英文界面

## 系统要求

- macOS 14 或更高版本
- Stardew Valley macOS 版
- [SMAPI](https://smapi.io/)（扫描和管理模组不强制需要；从应用内启动游戏时需要）

发布包是通用二进制，同时支持 Apple Silicon 和 Intel Mac。

## 安装

从 [Releases](https://github.com/HaydenTtttya/StardewModManager/releases) 下载 `StardewModManager-macos-universal.zip`，解压后把应用拖进“应用程序”文件夹。

当前发布包使用 ad-hoc 签名，没有经过 Apple 公证。首次打开时如果 macOS 提示无法验证开发者，请在 Finder 中右键应用并选择“打开”，或前往“系统设置 → 隐私与安全性”允许打开。

每个 Release 还会附带 `.sha256` 文件。需要校验下载内容时可以运行：

```bash
shasum -a 256 StardewModManager-macos-universal.zip
```

把输出的哈希值和 `.sha256` 文件中的值对照即可。

## 还没做的事

- 删除模组和可恢复备份
- 通过 Sparkle 提供应用内更新

如果你准备让它管理唯一一份模组目录，建议仍然保留自己的备份。这个项目还在 beta 阶段，文件操作相关的边界情况会继续补。

## License

[MIT](LICENSE)
