#include <stdio.h>
#include <errno.h>
#include <syslog.h>
#include <string.h>
int main(int argc, char* argv[])
{
    if(argc != 3)
    {
        exit(1);
    }
    FILE* f1 = fopen(argv[1],"w+");
    if(f1==NULL)
    {
        syslog(LOG_ERR,strerror(errno));
        exit(1);
    }
    fprintf(f1,argv[2]);
    fclose(f1);
    openlog(NULL,0,LOG_USER);
    syslog(LOG_DEBUG,"Writing %s to file %s",argv[2],argv[1]);
    syslog(LOG_ERR,strerror(errno));
    
}