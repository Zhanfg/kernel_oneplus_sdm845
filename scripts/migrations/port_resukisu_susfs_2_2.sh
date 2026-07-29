#!/usr/bin/env bash
set -euo pipefail

: "${RESUKISU_REPOSITORY:=ReSukiSU/ReSukiSU}"
: "${RESUKISU_COMMIT:=d5ba3d2d51a4c5b41a182112faa13c02b98e31a1}"
: "${SUSFS_PATCH_REPOSITORY:=JackA1ltman/NonGKI_Kernel_Build_2nd}"
: "${SUSFS_OLD_COMMIT:=5404a6864ba87efcb15d528c0d68f201d993dac2}"
: "${SUSFS_NEW_COMMIT:=7caf07c44806c1086ba28236c60722fb5699d2b6}"
: "${DEFCONFIG:=vendor/enchilada_defconfig}"

rm -rf /tmp/resukisu /tmp/susfs-old.patch /tmp/susfs-new.patch /tmp/susfs-delta.patch
git clone --filter=blob:none "https://github.com/${RESUKISU_REPOSITORY}.git" /tmp/resukisu
git -C /tmp/resukisu checkout --detach "${RESUKISU_COMMIT}"
test "$(git -C /tmp/resukisu rev-parse HEAD)" = "${RESUKISU_COMMIT}"

RESUKISU_COUNT="$(git -C /tmp/resukisu rev-list --count HEAD)"
RESUKISU_VERSION_CODE="$((30000 + RESUKISU_COUNT + 700))"
RESUKISU_TAG="$(git -C /tmp/resukisu describe --abbrev=0 --tags 2>/dev/null || echo v4.1.0)"
export RESUKISU_COUNT RESUKISU_VERSION_CODE RESUKISU_TAG RESUKISU_COMMIT

rm -rf KernelSU drivers/kernelsu
mkdir -p KernelSU drivers/kernelsu
rsync -a --delete --exclude='.git' /tmp/resukisu/ KernelSU/
rsync -a --delete --exclude='.git' /tmp/resukisu/kernel/ drivers/kernelsu/

python3 <<'PY'
import os
from pathlib import Path

path = Path('drivers/kernelsu/Kbuild')
text = path.read_text()
fatal_start = text.index('ifeq ($(LOCAL_GIT_EXISTS),0)')
fatal_end = text.index('ifdef KBUILD_EXTMOD', fatal_start)
text = text[:fatal_start] + '''ifeq ($(LOCAL_GIT_EXISTS),0)\n$(warning -- ReSukiSU embedded source; using pinned provenance metadata)\nendif\n\n''' + text[fatal_end:]
version_start = text.index('$(shell cd $(KSU_SRC); [ -f ../.git/shallow ]')
version_end = text.index('ifdef CONFIG_KSU_MULTI_MANAGER_SUPPORT', version_start)
original = text[version_start:version_end]
count = os.environ['RESUKISU_COUNT']
code = os.environ['RESUKISU_VERSION_CODE']
tag = os.environ['RESUKISU_TAG']
sha = os.environ['RESUKISU_COMMIT'][:8]
fallback = f'''ifeq ($(LOCAL_GIT_EXISTS),1)\n{original}else\nKSU_LOCAL_VERSION := {count}\nKSU_VERSION := {code}\nKSU_TAG_NAME := {tag}\nKSU_COMMIT_SHA := {sha}\nKSU_BRANCH_NAME := main\nKSU_VERSION_FULL := $(subst ",,$(CONFIG_KSU_FULL_NAME_FORMAT))\nKSU_VERSION_FULL := $(subst %TAG_NAME%,$(KSU_TAG_NAME),$(KSU_VERSION_FULL))\nKSU_VERSION_FULL := $(subst %COMMIT_SHA%,$(KSU_COMMIT_SHA),$(KSU_VERSION_FULL))\nKSU_VERSION_FULL := $(subst %REPO_NAME%,$(REPO_NAME),$(KSU_VERSION_FULL))\nKSU_VERSION_FULL := $(subst %BRANCH_NAME%,$(KSU_BRANCH_NAME),$(KSU_VERSION_FULL))\nKSU_VERSION_FULL := $(subst %KSU_VERSION%,$(KSU_VERSION),$(KSU_VERSION_FULL))\n$(info -- $(REPO_NAME) embedded version code: $(KSU_VERSION))\n$(info -- $(REPO_NAME) embedded version name: $(KSU_VERSION_FULL))\nccflags-y += -DKSU_VERSION=$(KSU_VERSION)\nccflags-y += -DKSU_VERSION_FULL=\\"$(KSU_VERSION_FULL)\\"\nendif\n\n'''
text = text[:version_start] + fallback + text[version_end:]
path.write_text(text)
Path('KernelSU/kernel/Kbuild').write_text(text)
PY

python3 <<'PY'
from pathlib import Path

path = Path('fs/open.c')
text = path.read_text()
old = '''#ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT\n#include <linux/susfs_def.h>\nextern struct filename *susfs_open_redirect_spoof_do_sys_openat(struct inode *inode);\n#endif // #ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT\n'''
new = '''#ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT\nextern struct filename *susfs_open_redirect_spoof_do_sys_openat(struct inode *inode);\n#endif // #ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT\n'''
if old not in text:
    raise SystemExit('unexpected fs/open.c 2.1 layout')
path.write_text(text.replace(old, new, 1))

path = Path('fs/proc_namespace.c')
text = path.read_text()
old = '''#ifdef CONFIG_KSU_SUSFS_SUS_MOUNT\n#include <linux/susfs_def.h>\nextern bool susfs_hide_sus_mnts_for_non_su_procs;\nextern bool susfs_is_current_ksu_domain(void);\n#endif\n\n#include "proc/internal.h" /* only for get_proc_task() in ->open() */\n\n#include "pnode.h"\n#include "internal.h"\n'''
new = '''#ifdef CONFIG_KSU_SUSFS_SUS_MOUNT\n#include <linux/susfs_def.h>\n#endif\n\n#include "proc/internal.h" /* only for get_proc_task() in ->open() */\n\n#include "pnode.h"\n#include "internal.h"\n\n#ifdef CONFIG_KSU_SUSFS_SUS_MOUNT\nextern bool susfs_hide_sus_mnts_for_non_su_procs;\nextern bool susfs_is_current_ksu_domain(void);\n#endif\n'''
if old not in text:
    raise SystemExit('unexpected fs/proc_namespace.c 2.1 layout')
path.write_text(text.replace(old, new, 1))

path = Path('fs/proc/task_mmu.c')
text = path.read_text()
start = text.index('#ifdef CONFIG_KSU_SUSFS_SUS_KSTAT\nextern void susfs_sus_ino_for_show_map_vma')
end = text.index('\n\tif (vma->vm_ops && vma->vm_ops->name) {', start)
canonical = r'''#ifdef CONFIG_KSU_SUSFS_SUS_KSTAT
extern void susfs_sus_kstat_spoof_show_map_vma(struct inode *inode, dev_t *out_dev, unsigned long *out_ino);
#endif // #ifdef CONFIG_KSU_SUSFS_SUS_KSTAT
#ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT
extern int susfs_open_redirect_spoof_show_map_vma(struct inode *inode, unsigned long *out_ino, dev_t *out_dev, char *spoofed_name);
#endif // #ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT

static void
show_map_vma(struct seq_file *m, struct vm_area_struct *vma)
{
	struct mm_struct *mm = vma->vm_mm;
	struct file *file = vma->vm_file;
	vm_flags_t flags = vma->vm_flags;
	unsigned long ino = 0;
	unsigned long long pgoff = 0;
	unsigned long start, end;
	dev_t dev = 0;
	const char *name = NULL;
#ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT
	char *spoofed_redirected_name = NULL;
#endif // #ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT

	if (file) {
		struct inode *inode = file_inode(vma->vm_file);
#ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT
		if (SUSFS_IS_INODE_OPEN_REDIRECT(inode)) {
			if (!susfs_open_redirect_spoof_show_map_vma(inode, &ino, &dev, spoofed_redirected_name)) {
				pgoff = ((loff_t)vma->vm_pgoff) << PAGE_SHIFT;
				goto orig_flow;
			}
		}
#endif // #ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT
#ifdef CONFIG_KSU_SUSFS_SUS_MAP
		if (SUSFS_IS_INODE_SUS_MAP(inode))
			return;
#endif // #ifdef CONFIG_KSU_SUSFS_SUS_MAP
		dev = inode->i_sb->s_dev;
		ino = inode->i_ino;
		pgoff = ((loff_t)vma->vm_pgoff) << PAGE_SHIFT;
#ifdef CONFIG_KSU_SUSFS_SUS_KSTAT
		susfs_sus_kstat_spoof_show_map_vma(inode, &dev, &ino);
#endif // #ifdef CONFIG_KSU_SUSFS_SUS_KSTAT
	}

#ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT
orig_flow:
#endif // #ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT
	start = vma->vm_start;
	end = vma->vm_end;
	show_vma_header_prefix(m, start, end, flags, pgoff, dev, ino);

	/*
	 * Print the dentry name for named mappings, and a
	 * special [heap] marker for the heap:
	 */

#ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT
	if (spoofed_redirected_name) {
		seq_pad(m, ' ');
		seq_puts(m, spoofed_redirected_name);
		seq_putc(m, '\n');
		kfree(spoofed_redirected_name);
		return;
	}
#endif // #ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT

	if (file) {
		seq_pad(m, ' ');
		seq_file_path(m, file, "\n");
		goto done;
	}
'''
path.write_text(text[:start] + canonical + text[end:])
PY

BASE="https://raw.githubusercontent.com/${SUSFS_PATCH_REPOSITORY}"
PATCH_PATH="Patches/Patch/susfs_patch_to_4.19.patch"
curl --fail --location --retry 3 "${BASE}/${SUSFS_OLD_COMMIT}/${PATCH_PATH}" -o /tmp/susfs-old.patch
curl --fail --location --retry 3 "${BASE}/${SUSFS_NEW_COMMIT}/${PATCH_PATH}" -o /tmp/susfs-new.patch
grep -q '#define SUSFS_VERSION "v2.1.0"' /tmp/susfs-old.patch
grep -q '#define SUSFS_VERSION "v2.2.0"' /tmp/susfs-new.patch
interdiff /tmp/susfs-old.patch /tmp/susfs-new.patch > /tmp/susfs-delta.patch
test -s /tmp/susfs-delta.patch
mkdir -p patches/susfs
cp /tmp/susfs-delta.patch patches/susfs/susfs-v2.1.0-to-v2.2.0-4.19.patch
set +e
patch --batch --forward -p1 < /tmp/susfs-delta.patch
PATCH_STATUS=$?
set -e
if find . -type f -name '*.rej' -print -quit | grep -q .; then
  find . -type f -name '*.rej' -print -exec cat {} \;
  exit 1
fi
test "${PATCH_STATUS}" -eq 0
grep -q '#define SUSFS_VERSION "v2.2.0"' include/linux/susfs.h

python3 <<'PY'
from pathlib import Path
path = Path('arch/arm64/configs/vendor/enchilada_defconfig')
text = path.read_text()
start = text.index('# -- ReSukiSU + SuSFS v2.1.00 --')
end = text.index('# -- BBR TCP Congestion Control --', start)
block = '''# -- ReSukiSU main + SuSFS v2.2.0 (4.19 Inline Hook) --\nCONFIG_KPROBES=y\nCONFIG_KRETPROBES=y\nCONFIG_THREAD_INFO_IN_TASK=y\nCONFIG_KSU=y\nCONFIG_KSU_FULL_NAME_FORMAT="%TAG_NAME%-%COMMIT_SHA%@%REPO_NAME%"\nCONFIG_KSU_MULTI_MANAGER_SUPPORT=y\n# CONFIG_KSU_TRACEPOINT_HOOK is not set\n# CONFIG_KSU_MANUAL_HOOK is not set\nCONFIG_KSU_SUSFS=y\nCONFIG_KSU_SUSFS_SUS_PATH=y\nCONFIG_KSU_SUSFS_SUS_MOUNT=y\nCONFIG_KSU_SUSFS_SUS_KSTAT=y\nCONFIG_KSU_SUSFS_SPOOF_UNAME=y\nCONFIG_KSU_SUSFS_ENABLE_LOG=y\nCONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y\nCONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y\nCONFIG_KSU_SUSFS_OPEN_REDIRECT=y\nCONFIG_KSU_SUSFS_SUS_MAP=y\n'''
path.write_text(text[:start] + block + text[end:])
PY

cat > RESUKISU_SUSFS_BASELINE.env <<EOF
RESUKISU_REPOSITORY=${RESUKISU_REPOSITORY}
RESUKISU_COMMIT=${RESUKISU_COMMIT}
RESUKISU_TAG=${RESUKISU_TAG}
RESUKISU_VERSION_CODE=${RESUKISU_VERSION_CODE}
SUSFS_VERSION=v2.2.0
SUSFS_PATCH_REPOSITORY=${SUSFS_PATCH_REPOSITORY}
SUSFS_OLD_4_19_PATCH_COMMIT=${SUSFS_OLD_COMMIT}
SUSFS_NEW_4_19_PATCH_COMMIT=${SUSFS_NEW_COMMIT}
PORT_METHOD=interdiff-v2.1.0-to-v2.2.0-plus-pinned-resukisu
CHECKED_AT_UTC=2026-07-29
EOF

cat > patches/susfs/README.md <<EOF
# SuSFS 4.19 migration record

- ReSukiSU: \`${RESUKISU_REPOSITORY}@${RESUKISU_COMMIT}\`
- Old 4.19 patch: \`${SUSFS_PATCH_REPOSITORY}@${SUSFS_OLD_COMMIT}\`
- New 4.19 patch: \`${SUSFS_PATCH_REPOSITORY}@${SUSFS_NEW_COMMIT}\`

The retained delta upgrades the existing tree from SuSFS v2.1.0 to v2.2.0 and must not be applied twice.
EOF
