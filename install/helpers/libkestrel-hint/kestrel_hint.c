/* libkestrel-hint - see kestrel_hint.h. */

#define _GNU_SOURCE
#include "kestrel_hint.h"

#include <errno.h>
#include <stddef.h>
#include <string.h>
#include <sys/syscall.h>
#include <unistd.h>

static int getattr(pid_t pid, struct kestrel_sched_attr *attr)
{
	memset(attr, 0, sizeof(*attr));
	attr->size = sizeof(*attr);
	return (int)syscall(SYS_sched_getattr, pid, attr, sizeof(*attr), 0u);
}

int kestrel_hint_supported(void)
{
	struct kestrel_sched_attr attr;

	if (getattr(0, &attr) != 0)
		return 0;
	/* An older kernel copies its shorter struct and reports the shorter
	 * size; the hint field is only present when it is covered. */
	if (attr.size < offsetof(struct kestrel_sched_attr, sched_ext_hint) +
			     sizeof(attr.sched_ext_hint))
		return 0;
	return 1;
}

int kestrel_hint_set(pid_t pid, uint32_t hint)
{
	struct kestrel_sched_attr attr;

	if (hint > KESTREL_HINT_MAX) {
		errno = EINVAL;
		return -1;
	}
	memset(&attr, 0, sizeof(attr));
	attr.size = sizeof(attr);
	/* KEEP_POLICY|KEEP_PARAMS: only the hint changes; the task keeps its
	 * scheduling policy, priority and nice value. */
	attr.sched_flags = KESTREL_HINT_FLAG | KESTREL_SCHED_FLAG_KEEP_POLICY |
			   KESTREL_SCHED_FLAG_KEEP_PARAMS;
	attr.sched_ext_hint = hint;
	return (int)syscall(SYS_sched_setattr, pid, &attr, 0u);
}

int kestrel_hint_get(pid_t pid, uint32_t *hint)
{
	struct kestrel_sched_attr attr;

	if (getattr(pid, &attr) != 0)
		return -1;
	if (attr.size < offsetof(struct kestrel_sched_attr, sched_ext_hint) +
			     sizeof(attr.sched_ext_hint)) {
		errno = ENOTSUP;
		return -1;
	}
	*hint = attr.sched_ext_hint;
	return 0;
}
