# Upstream Sync Policy

更新时间：2026-07-29

## 1. 上游定义

### 主要 4.19 上游

```text
Repository: EdwinMoq/android_kernel_oneplus_sdm845
Branch: lineage-23.2-4.19
```

选择该分支的原因：

- 与当前源码树同为 Linux 4.19.325。
- 面向 OnePlus 6 / 6T SDM845。
- 仍包含设备、安全、相机、电池和编译兼容性更新。

### 4.9 参考仓库

```text
OnePlusOSS/android_kernel_oneplus_sdm845
LineageOS/android_kernel_oneplus_sdm845
```

这些仓库用于核对原始厂商实现和主流设备修复，不作为当前 4.19 树的直接合并目标。

## 2. 同步原则

1. 上游变更只进入 `sync/upstream-*` 分支。
2. 同步 PR 永不自动合并。
3. 不使用 `git merge -s ours`、整树覆盖或删除冲突文件来伪造同步。
4. 必须保留 ReSukiSU、SuSFS、BBG、网络栈和项目调优的本地改动。
5. 每次同步记录：
   - 上游仓库
   - 上游分支
   - 上游提交 SHA
   - 本地合并基线 SHA
   - 冲突文件
   - 构建结果
   - 真机验证结果

## 3. 自动工作流行为

`.github/workflows/sync-upstream.yml` 会：

1. 完整检出 `master` 历史。
2. 获取主要 4.19 上游分支。
3. 检查共同祖先。
4. 判断本地是否已包含上游提交。
5. 创建独立同步分支。
6. 尝试普通 `--no-ff` 合并。
7. 无冲突时推送分支并创建 Draft PR。
8. 有冲突时终止合并，在 Actions Summary 和 Artifact 中保存冲突报告。

工作流不会直接修改 `master`。

## 4. 合并前检查

### 源码检查

- [ ] `Makefile` 内核版本符合预期
- [ ] `vendor/enchilada_defconfig` 未丢失项目配置
- [ ] ReSukiSU 可编译
- [ ] SuSFS 可编译
- [ ] BBR v1 / FQ_CODEL / ipset 配置存在
- [ ] BBRv2 未被误开启
- [ ] BBG 配置与源码存在
- [ ] NTSYNC 与 Docker 相关配置未被覆盖
- [ ] Enchilada DTS / DTBO 正常
- [ ] Fajita 文件未被错误声明为已验证支持

### 构建检查

- [ ] Standard 构建成功
- [ ] PowerSave 构建成功
- [ ] `Image.gz-dtb` 生成
- [ ] `dtbo.img` 生成
- [ ] AK3 ZIP 生成
- [ ] SHA256 生成并记录

### 真机检查

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

## 5. 冲突处理顺序

1. 先判断冲突是否来自本地功能补丁或上游设备修复。
2. 设备驱动和安全修复优先理解上游意图，不直接保留旧代码。
3. Root、隐藏和网络功能优先保持现有接口兼容，再移植上游修改。
4. Defconfig 冲突逐项核对，不整段覆盖。
5. DTS 冲突必须检查硬件节点、regulator、时钟、GPIO 和 reserved-memory。
6. 解决后重新生成完整构建，不使用旧 Artifact。

## 6. 回退

上游同步应使用 squash 或普通 merge 保留明确边界。若真机验证失败，优先整体回退该同步 PR，再拆分定位问题，不在 `master` 上连续追加无法追踪的临时修补。