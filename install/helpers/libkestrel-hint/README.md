# libkestrel-hint

Userspace side of the Kestrel per-task scheduling hint. A hint is a small
integer (0..1024) attached to a task; `scx_kestrel` maps it to a scheduling
layer, so the compositor, shell, terminal, browser and games can tell the
scheduler what they are without sharing any state with it.

This is the smallest piece of the kernel bridge to build and the only one that
touches every app: the four forks and `kestrel-broker` all link it, so the
calling convention is defined once.

## The ABI it wraps

The kernel patch (`kestrel-distro/linux-cachyos`, section 4 of the plan)
appends `__u32 sched_ext_hint` to `struct sched_attr` and adds
`SCHED_FLAG_KESTREL_HINT`. Setting a hint is one `sched_setattr(2)` with that
flag plus `SCHED_FLAG_KEEP_POLICY|SCHED_FLAG_KEEP_PARAMS`, so a hint never
disturbs the task's policy, priority or nice value.

`kestrel_hint.h` mirrors that uapi so the library and the apps build before the
patch lands. Keep it byte-for-byte in sync with the patched kernel's
`include/uapi/linux/sched/types.h` and `include/uapi/linux/sched.h`, including
the flag bit (`1ULL << 40`).

## Feature detection

On a stock kernel the flag is unknown and `sched_setattr` returns `EINVAL`;
`sched_getattr` returns a shorter `sched_attr` without the hint field. Both are
treated as "unsupported": the library reports it, the CLI exits non-zero, and
callers are expected to fall back to cgroup-only placement. No app should fail
to start because the kernel is stock.

## API

```c
int kestrel_hint_supported(void);
int kestrel_hint_set(pid_t pid, uint32_t hint);   /* pid 0 = self */
int kestrel_hint_get(pid_t pid, uint32_t *hint);
```

## Build

```
make
make install PREFIX=/usr
```

Produces `libkestrel-hint.a`, `libkestrel-hint.so` and the `kestrel-hint` CLI
(`kestrel-hint supported | set <pid|self> <n> | get <pid|self>`). The package
build in `kestrel-distro/packages` runs this Makefile.
