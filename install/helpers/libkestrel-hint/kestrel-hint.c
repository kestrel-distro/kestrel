/* kestrel-hint - set, read or probe the Kestrel per-task hint.
 *
 * Debug and test tool for libkestrel-hint; the session itself sets hints
 * through kestrel-broker. Installed to /usr/bin by the libkestrel-hint package.
 */
#define _GNU_SOURCE
#include "kestrel_hint.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int parse_pid(const char *arg, pid_t *pid)
{
	if (strcmp(arg, "self") == 0) {
		*pid = 0;
		return 0;
	}
	char *end = NULL;
	long v = strtol(arg, &end, 10);
	if (end == arg || *end != '\0' || v < 0 || v > INT32_MAX) {
		fprintf(stderr, "kestrel-hint: invalid pid '%s'\n", arg);
		return -1;
	}
	*pid = (pid_t)v;
	return 0;
}

static void usage(void)
{
	fputs("usage: kestrel-hint supported\n"
	      "       kestrel-hint set <pid|self> <0..1024>\n"
	      "       kestrel-hint get <pid|self>\n",
	      stderr);
}

int main(int argc, char **argv)
{
	if (argc < 2) {
		usage();
		return 2;
	}

	if (strcmp(argv[1], "supported") == 0) {
		int ok = kestrel_hint_supported();
		puts(ok ? "yes" : "no");
		return ok ? 0 : 1;
	}

	if (strcmp(argv[1], "set") == 0 && argc == 4) {
		pid_t pid;
		char *end = NULL;
		long hint;
		if (parse_pid(argv[2], &pid) != 0)
			return 2;
		hint = strtol(argv[3], &end, 10);
		if (end == argv[3] || *end != '\0' || hint < 0 ||
		    hint > (long)KESTREL_HINT_MAX) {
			fprintf(stderr,
				"kestrel-hint: hint must be 0..%u\n",
				KESTREL_HINT_MAX);
			return 2;
		}
		if (kestrel_hint_set(pid, (uint32_t)hint) != 0) {
			if (errno == EINVAL || errno == ENOSYS)
				fprintf(stderr,
					"kestrel-hint: kernel has no hint support\n");
			else
				fprintf(stderr, "kestrel-hint: set failed: %s\n",
					strerror(errno));
			return 1;
		}
		return 0;
	}

	if (strcmp(argv[1], "get") == 0 && argc == 3) {
		pid_t pid;
		uint32_t hint = 0;
		if (parse_pid(argv[2], &pid) != 0)
			return 2;
		if (kestrel_hint_get(pid, &hint) != 0) {
			fprintf(stderr, "kestrel-hint: get failed: %s\n",
				strerror(errno));
			return 1;
		}
		printf("%u\n", hint);
		return 0;
	}

	usage();
	return 2;
}
