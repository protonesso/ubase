/* See LICENSE file for copyright and license details. */
#include <sys/syscall.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <libgen.h>
#include "util.h"

static void
usage(void)
{
	eprintf("usage: %s [-fw] module...\n", argv0);
}

int
main(int argc, char *argv[])
{
	char *mod, *p;
	int i;
	int flags = O_NONBLOCK;

	ARGBEGIN {
	case 'f':
		flags |= O_TRUNC;
		break;
	case 'w':
		flags &= ~O_NONBLOCK;
		break;
	default:
		usage();
	} ARGEND;

	if (argc < 1)
		usage();

	for (i = 0; i < argc; i++) {
		mod = argv[i];
		p = strrchr(mod, '.');
		if (strlen(p) == 3 && !strcmp(p, ".ko"))
			*p = '\0';
		if (syscall(__NR_delete_module, mod, flags) < 0)
			eprintf("delete_module:");
	}

	return 0;
}