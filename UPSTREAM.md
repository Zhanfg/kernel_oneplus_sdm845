# OnePlus 6 上游与迁移策略

更新时间：2026-07-29

## 1. 已确认的源码来源

本仓库根提交：

```text
a2e9cf90f6c759cb21eec0416aa1cbad93042ab4
```

根提交说明明确记录本项目基于：

```text
shinichi-c/android_kernel_oneplus_sdm845
branch: lineage-23.0-4.19
```

同时，根提交已经一次性集成 ReSukiSU、SuSFS、BBG、网络栈、LZ4KD、NTSYNC、Docker 和设备调优。因此本仓库是“带完整功能的源码快照导入”，没有保留原始上游提交历史。

## 2. 原始基线上游

```text
Repository: shinichi-c/android_kernel_oneplus_sdm845
Branch: lineage-23.0-4.19
Recorded baseline SHA: 3019ce6cc4e9aab75da46761a3a9d03cee8937a3
Kernel: 4.19.325
```

截至 2026-07-29，该分支最新提交仍是记录的基线 SHA，当前没有新增提交需要同步。

这意味着当前 `master` 在“原始基线上游”层面已经没有落后提交，但由于历史被压成快照，不能使用 GitHub `Sync fork` 或普通 `git merge` 来证明继承关系。

## 3. 后续社区迁移目标

```text
Repository: EdwinMoq/android_kernel_oneplus_sdm845
Branch: lineage-23.2-4.19
Observed SHA: 91178f0c7899a2d9a3ccedfec9074c3648e4e78f
Kernel: 4.19.325
```

该分支不是原始上游的简单快进更新。核查时，两条分支相对共同祖先已经出现数千个新增提交和数百个反向差异，属于完整版本迁移，而不是日常上游同步。

禁止直接执行：

- `git merge` 后大量选择 ours；
- 整树覆盖当前 `master`；
- 用根提交到当前 master 的整树 diff 直接重放；
- 只要能编译就宣称迁移完成。

## 4. 为什么自动重放不可用

已完成两轮只读诊断：

1. 本地与 EdwinMoq 分支没有共同 Git 祖先。
2. 两者均为 Linux 4.19.325。
3. 本地根提交只有一个，但根 tree 已包含完整 ABK 功能，不等于任何干净上游提交。
4. 把根提交之后的整树差异重放到新上游会混入：
   - 新增的 ReSukiSU、SuSFS、BBG 等目录；
   - 已删除或改名的上游文件；
   - 大量文件模式变化；
   - defconfig、文件系统和 Netfilter 冲突。
5. 在上游完整历史中没有找到与本地根 tree hash 完全一致的提交。

因此，安全迁移必须从干净新上游开始，重新建立可追踪的 ABK 补丁集。

## 5. 当前自动检查行为

`.github/workflows/sync-upstream.yml` 只负责检查原始基线上游：

1. 读取 `UPSTREAM_BASELINE.env`。
2. 获取 `shinichi-c/...:lineage-23.0-4.19` 当前 HEAD。
3. 与记录的基线 SHA 比较。
4. 一致时报告“当前无新增上游提交”。
5. 不一致时失败并输出新旧 SHA，要求人工审核。

工作流权限为只读，不会：

- 修改 `master`；
- 推送同步分支；
- 自动创建或合并 PR；
- 覆盖内核源码。

## 6. 正确的迁移方法

对 `lineage-23.2-4.19` 或其他新基线，应建立独立 `migration/*` 分支，并按以下顺序重新移植：

1. 固定干净上游 SHA 和工具链。
2. 先完成原生 OnePlus 6 构建与启动验证。
3. 逐项加入基础网络和容器配置。
4. 移植 ReSukiSU。
5. 移植 SuSFS，并逐个检查文件系统 hook。
6. 移植 BBG。
7. 移植 LZ4KD、NTSYNC、Unicode 修复。
8. 移植 GPU、WALT、CFS 和 PowerSave 调优。
9. 每一阶段单独构建，并保留可回退提交。
10. 最后重新打包 AK3，完成真机验收。

## 7. 合并前检查

### 构建

- [ ] Standard 构建成功
- [ ] PowerSave 构建成功
- [ ] `Image.gz-dtb` 生成
- [ ] `dtbo.img` 生成
- [ ] AK3 ZIP 生成
- [ ] SHA256 与源码 SHA 已记录

### 功能

- [ ] ReSukiSU
- [ ] SuSFS
- [ ] BBR v1 / FQ_CODEL / ipset
- [ ] BBG
- [ ] NTSYNC
- [ ] Docker 相关配置
- [ ] Enchilada DTS / DTBO
- [ ] BBRv2 未被错误启用

### 真机

- [ ] 正常启动
- [ ] 蜂窝与移动数据
- [ ] Wi-Fi / 蓝牙
- [ ] 相机
- [ ] 指纹
- [ ] 充电与电池状态
- [ ] 灭屏与深度休眠
- [ ] Root 管理器
- [ ] SuSFS 功能
- [ ] Recovery 刷入与回滚

## 8. 回退

迁移必须保持阶段性提交。若某阶段构建或真机验证失败，回退该功能提交，不在一个超大提交中同时修复上游、Root、文件系统、网络和设备树问题。