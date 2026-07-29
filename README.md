# OnePlus 6 SDM845 Linux 4.19 Kernel Source

这是 `ABK OnePlus 6 Kernel` 项目的源码仓库，保存 OnePlus 6（`enchilada`）SDM845 Linux 4.19 内核树及自定义功能。

> 本仓库是社区维护的 Linux 4.19 移植与功能集成树，不是 OnePlus 官方发布的 4.19 内核源码。OnePlusOSS 的 SDM845 官方公开基线为 Linux 4.9。

## 仓库职责

| 仓库 | 职责 |
|---|---|
| `Zhanfg/kernel_oneplus_sdm845` | 内核源码、defconfig、设备树、自定义功能和上游基线记录 |
| `Zhanfg/abk-op6-kernel` | GitHub Actions、Standard / PowerSave 构建、AnyKernel3 打包和发布 |

发布仓库默认从本仓库 `master` 分支构建。

## 当前基线

| 项目 | 值 |
|---|---|
| 主设备 | OnePlus 6 (`enchilada`) |
| 附带资产 | OnePlus 6T (`fajita`) 部分设备树与 DTBO |
| SoC | Qualcomm SDM845 |
| 内核 | Linux 4.19.325 |
| 默认分支 | `master` |
| 默认 defconfig | `vendor/enchilada_defconfig` |
| 默认构建 | Standard；PowerSave 由发布仓库构建时应用补丁 |

包含 `fajita` 文件不代表 OnePlus 6T 已完成真机验证。当前项目只声明 OnePlus 6 为主目标。

## 已集成内容

以下内容表示源码或配置中已经合入，仍需通过构建和真机验收确认运行状态：

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

推荐通过 `Zhanfg/abk-op6-kernel` 的 GitHub Actions 构建：

- `Build Standard`
- `Build PowerSave`
- 产物：`Image.gz-dtb`、`dtbo.img`、AnyKernel3 ZIP

`Image.gz-dtb` 是裸内核镜像，不是完整 Android `boot.img`，不得直接写入 `boot` 分区。

## 上游关系

### 原始基线上游

```text
repository: shinichi-c/android_kernel_oneplus_sdm845
branch: lineage-23.0-4.19
baseline: 3019ce6cc4e9aab75da46761a3a9d03cee8937a3
```

本仓库根提交将完整 ABK 功能直接压入一个源码快照，因此没有保留与原始上游的 Git 祖先关系。原始上游截至 2026-07-29 仍停留在上述提交，当前没有新增提交需要拉取。

### 后续迁移参考

```text
repository: EdwinMoq/android_kernel_oneplus_sdm845
branch: lineage-23.2-4.19
observed: 91178f0c7899a2d9a3ccedfec9074c3648e4e78f
```

该分支与原始 `lineage-23.0-4.19` 已大幅分叉，不能当作普通上游直接 merge。迁移必须重新整理 ABK 补丁集，在新基线上逐项移植、构建和真机验证。

### 其他参考

- `OnePlusOSS/android_kernel_oneplus_sdm845`：官方 Linux 4.9 源码参考。
- `LineageOS/android_kernel_oneplus_sdm845`：主流 Linux 4.9 设备维护参考。

详细状态见 [`UPSTREAM.md`](UPSTREAM.md) 和 [`UPSTREAM_BASELINE.env`](UPSTREAM_BASELINE.env)。

## 自动上游检查

`.github/workflows/sync-upstream.yml` 只检查原始上游分支是否出现新提交：

- 不自动合并源码；
- 不生成整树覆盖；
- 不修改 `master`；
- 基线变化时使工作流失败，并输出新旧 SHA 供人工审核。

## 分支策略

| 分支 | 用途 |
|---|---|
| `master` | 当前可构建源码基线 |
| `migration/*` | 新 4.19 社区基线迁移 |
| `fix/*` | 构建或运行时修复 |
| `feature/*` | 新功能或较大改动 |

迁移分支合入前至少需要：

1. Standard 与 PowerSave 均构建成功。
2. ReSukiSU、SuSFS、BBG、网络与设备配置完成审查。
3. OnePlus 6 正常启动。
4. 蜂窝、Wi-Fi、蓝牙、相机、指纹、充电和休眠通过测试。
5. 记录源码、工具链、产物校验值和回滚方式。

## 验证等级

- **Build verified**：完成编译和打包。
- **Boot verified**：指定设备与 ROM 可以启动。
- **Runtime verified**：主要硬件和自定义功能通过测试。

只完成构建不能标记为 Stable。

## 安全与贡献

- 不提交 Token、密钥、账号、设备序列号或本机隐私路径。
- 不使用 `ours` 策略或整树覆盖伪造上游同步。
- 不以删除冲突代码的方式强行通过编译。
- 涉及启动、基带、充电、温控、文件系统或 Root 的改动必须单独说明风险。
- 提交应保持单一目的，并注明来源和测试结果。

## 许可证

Linux 内核源码遵循 GPL-2.0。第三方补丁和组件遵循各自上游许可证。