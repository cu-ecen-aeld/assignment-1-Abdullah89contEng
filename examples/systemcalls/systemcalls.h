#include <stdio.h>
#include <stdbool.h>
#include <stdarg.h>
#include<stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/wait.h>
bool do_system(const char *command);

bool do_exec(int count, ...);

bool do_exec_redirect(const char *outputfile, int count, ...);
