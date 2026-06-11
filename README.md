# Stardew Mod Manager

## 一个使用 SwiftUI 制作的 macOS 星露谷物语模组管理器。
---
<img width="2308" height="1692" alt="CleanShot 2026-06-09 at 19 21 46@2x" src="https://github.com/user-attachments/assets/7bab5d3e-b179-4132-97c5-9b3c563b64e3" />


## 当前功能

- 自动定位 Steam 版 macOS 的 `Mods` 文件夹
- 递归扫描 `manifest.json`
- 展示模组名称、作者、版本、分类、UniqueID、路径
- 区分代码模组与内容包
- 检测缺失的必需依赖、可选依赖和重复 UniqueID
- 支持切换 Mods 文件夹、搜索、分类筛选、刷新和 Finder 定位
- 支持安装普通模组包，以及按 `i18n` 或同名文件覆盖规则安装模组翻译
- 支持通过模组详情开关或工具栏启用/禁用模组
- 支持通过 `StardewModdingAPI` 启动/停止游戏，并在 UI 内按级别显示彩色 SMAPI 加载日志
- 支持通过 SMAPI 更新检查接口标注有新版本的模组


当前雏形没有签名和公证。直接从 GitHub 下载时，macOS 可能会显示安全提示

## 后续路线

- 删除前自动备份
- 接入 Sparkle 做应用内更新

## 开源许可

MIT
