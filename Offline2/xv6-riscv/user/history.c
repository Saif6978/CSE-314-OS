#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/history.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
    struct syscall_stat st;

    if(argc == 2){
        int num = atoi(argv[1]);

        if(history(num, &st) < 0){
            fprintf(2, "history failed\n");
            exit(1);
        }

        printf("%d: syscall: %s, #: %d, time: %d\n",
               num,
               st.syscall_name,
               st.count,
               st.accum_time);
    }
    else{
        for(int i = 1; ; i++){
            if(history(i,&st)<0)break;
            printf("%d: syscall: %s, #: %d, time: %d\n",
                i,
                st.syscall_name,
                st.count,
                st.accum_time);
        }
    }

    exit(0);
}