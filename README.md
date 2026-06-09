# Stardew Mod Manager

一个使用 SwiftUI 制作的 macOS 星露谷物语模组管理器雏形。当前版本专注于本地扫描 SMAPI 模组目录，并展示 `manifest.json` 中的基础信息。
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
- 支持通过 `StardewModdingAPI` 启动/停止游戏，并在 UI 内按级别显示彩色 SMAPI 加载日志
- 支持通过 SMAPI 更新检查接口标注有新版本的模组

## 本地运行

```bash
swift run StardewModManager
```

也可以在 Xcode 中打开项目目录：

```bash
open Package.swift
```

## 测试

```bash
swift test
```

## 打包 `.app`

```bash
./scripts/package_app.sh
open dist/StardewModManager.app
```

当前雏形没有签名和公证。直接从 GitHub 下载时，macOS 可能会显示安全提示；后续可以选择 Developer ID 签名，或者在 README 中给出开源应用的手动打开说明。

## 后续路线

- 启用/禁用模组
- 删除前自动备份
- 解析 `UpdateKeys` 并检查 Nexus/GitHub 更新
- 生成 `.app`、`.dmg` 和 GitHub Release
- 接入 Sparkle 做应用内更新

## 开源许可

MIT
