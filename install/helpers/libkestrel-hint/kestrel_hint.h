/* libkestrel-hint - userspace side of the Kestrel per-task hint.
 *
 * The kernel patch (kestrel-distro/linux-cachyos, section 4 of the
 * kernel-bridge plan) appends a 32-bit hint to struct sched_attr and adds a
 * flag to set it through sched_setattr(2). This header mirrors that uapi so
 * the library and the apps can be built before the kernel patch lands; keep it
 * byte-for-byte in sync with include/uapi/linux/sched/types.h and
 * include/uapi/linux/sched.h in the patched kernel.
 *
 * On a stock kernel the flag is unknown, sched_setattr returns EINVAL, and
 * every entry point here reports "unsupported" without changing anything.
 */
#ifndef KESTREL_HINT_H
#define KESTREL_HINT_H

#include <stdint.h>
#include <sys/types.h>

/* Must equal the kernel's SCHED_FLAG_KESTREL_HINT. Bits 0..12 are taken by
 * upstream SCHED_FLAG_*; a high bit keeps a distro-local flag clear of them. */
#define KESTREL_HINT_FLAG (1ULL << 40)

/* Upstream sched_flags bits used to keep a hint-only update from resetting the
 * task's policy or parameters. */
#define KESTREL_SCHED_FLAG_KEEP_POLICY 0x08ULL
#define KESTREL_SCHED_FLAG_KEEP_PARAMS 0x10ULL

/* Valid hint range. Values above this are ignored by scx_kestrel (a bad or
 * stale hint is treated as "no hint", never as a match). */
#define KESTREL_HINT_MAX 1024u

/* struct sched_attr with the Kestrel extension appended. size must always be
 * set to sizeof(struct kestrel_sched_attr) by callers. */
struct kestrel_sched_attr {
	uint32_t size;
	uint32_t sched_policy;
	uint64_t sched_flags;
	int32_t sched_nice;
	uint32_t sched_priority;
	uint64_t sched_runtime;
	uint64_t sched_deadline;
	uint64_t sched_period;
	uint32_t sched_util_min;
	uint32_t sched_util_max;
	uint32_t sched_ext_hint;
};

/* 1 when the running kernel accepts hints, 0 otherwise. */
int kestrel_hint_supported(void);

/* Set the hint on pid (0 means the calling task). Returns 0, or -1 with errno
 * set. EINVAL/ENOSYS mean the kernel has no hint support. */
int kestrel_hint_set(pid_t pid, uint32_t hint);

/* Read the hint of pid into *hint. Returns 0, or -1 with errno set. */
int kestrel_hint_get(pid_t pid, uint32_t *hint);

#endif /* KESTREL_HINT_H */
