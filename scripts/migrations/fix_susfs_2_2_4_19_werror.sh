#!/usr/bin/env bash
set -euo pipefail

python3 <<'PY'
from pathlib import Path

path = Path('fs/proc/task_mmu.c')
text = path.read_text()
needle = '''#ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT
	char *spoofed_redirected_name = NULL;
#endif // #ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT

	if (file) {
'''
replacement = '''	if (file) {
'''
if needle not in text:
    raise SystemExit('expected outer open_redirect variable was not found')
path.write_text(text.replace(needle, replacement, 1))
PY
