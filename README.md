# OnePlus 6 / 6T SDM845 Linux 4.19 Kernel Source

这是 `ABK OnePlus 6 Kernel` 项目的源码仓库，保存 OnePlus 6（`enchilada`）/ OnePlus 6T（`fajita`）SDM845 Linux 4.19 内核树及自定义补丁。

> 本仓库是社区维护的 Linux 4.19 移植与功能集成树，不是 OnePlus 官方发布的 4.19 内核源码。OnePlusOSS 的 SDM845 官方公开内核基线为 Linux 4.9。

## 仓库职责

| 仓库 | 职责 |
|---|---|
| `Zhanfg/kernel_oneplus_sdm845` | 内核源码、补丁、defconfig、设备树和上游同步 |
| `Zhanfg/abk-op6-kernel` | GitHub Actions、Standard / PowerSave 变体、AnyKernel3 打包和发布 |

发布仓库默认从本仓库 `master` 分支构建。

## 当前基线

| 项目 | 值 |
|---|---|
| 主设备 | OnePlus 6 (`enchilada`) |
| 兼容资产 | OnePlus 6T (`fajita`) 部分设备树与 DTBO |
| SoC | Qualcomm SDM845 |
| 内核 | Linux 4.19.325 |
| 默认分支 | `master` |
| 默认 defconfig | `vendor/enchilada_defconfig` |
| 默认构建定位 | Standard；PowerSave 由发布仓库构建时应用补丁 |

包含 `fajita` 文件不代表 OnePlus 6T 已完成真机验证。当前主目标仍是 OnePlus 6。

## 已集成内容

以下内容表示源码或配置中已经合入，运行时状态仍需通过发布仓库的构建和真机验收确认：

- ReSukiSU
- SuSFS
- BBR v1、FQ_CODEL、ipset 与 Netfilter 扩展
- Baseband Guard
- LZ4KD
- NTSYNC
- Docker 相关 namespace、cgroup、overlayfs 支持
- Unicode 零宽字符绕过修复
- GPU 频率与调度参数调整

BBRv2 当前保持禁用。现有 4.19 TCP API 与已尝试实现不兼容，不能只修改 defconfig 强行开启。

## 构建

推荐通过发布仓库构建：

```text
https://github.com/Zhanfg/abk-op6-kernel
```

发布仓库提供：

- `Build Standard`
- `Build PowerSave`
- `Image.gz-dtb`
- `dtbo.img`
- AnyKernel3 ZIP

本仓库只维护源码，不应直接把 `Image.gz-dtb` 写入 Android `boot` 分区。裸内核镜像不包含完整 boot ramdisk。

## 上游

当前 Linux 4.19 主要社区上游：

```text
repository: EdwinMoq/android_kernel_oneplus_sdm845
branch: lineage-23.2-4.19
```

官方与主流 4.9 参考：

```text
OnePlusOSS/android_kernel_oneplus_sdm845
LineageOS/android_kernel_oneplus_sdm845
```

由于本仓库不是上述仓库的 GitHub Fork，不能使用 GitHub 的原生 `Sync fork`。仓库通过 `.github/workflows/sync-upstream.yml` 获取上游、检查共同祖先，并在无冲突时建立独立同步 PR。

详细规则见 [`UPSTREAM.md`](UPSTREAM.md)。

## 分支策略

| 分支 | 用途 |
|---|---|
| `master` | 当前可构建源码基线 |
| `sync/upstream-*` | 自动生成的上游同步候选 |
| `fix/*` | 构建或运行时修复 |
| `feature/*` | 新功能或较大改动 |

上游同步 PR 不自动合并。合并前至少需要：

1. 无未解决冲突。
2. Standard 构建通过。
3. PowerSave 构建通过。
4. 核对 ReSukiSU、SuSFS、BBG、网络与设备配置未被覆盖。
5. 记录上游提交 SHA。
6. 完成必要的真机启动与运行时验证。

## 验证等级

- **Build verified**：能完成编译和打包。
- **Boot verified**：指定设备与 ROM 可以启动。
- **Runtime verified**：蜂窝、Wi-Fi、相机、指纹、充电、休眠、Root 等通过测试。

只完成构建不能标记为 Stable。

## 安全与贡献

- 不提交 Token、密钥、账号、设备序列号或本机隐私路径。
- 不使用 `ours` 合并策略伪造上游同步。
- 不以删除冲突代码的方式强行通过编译。
- 涉及启动、基带、充电、温控、文件系统或 Root 的改动必须单独说明风险。
- 提交应尽量保持单一目的，并注明来源和测试结果。

## 许可证

Linux 内核源码遵循 GPL-2.0。第三方补丁和组件遵循各自上游许可证。