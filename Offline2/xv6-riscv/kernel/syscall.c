#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "syscall.h"
#include "defs.h"

// Fetch the uint64 at addr from the current process.
int
fetchaddr(uint64 addr, uint64 *ip)
{
  struct proc *p = myproc();
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    return -1;
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    return -1;
  return 0;
}

// Fetch the nul-terminated string at addr from the current process.
// Returns length of string, not including nul, or -1 for error.
int
fetchstr(uint64 addr, char *buf, int max)
{
  struct proc *p = myproc();
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    return -1;
  return strlen(buf);
}

static uint64
argraw(int n)
{
  struct proc *p = myproc();
  switch (n) {
  case 0:
    return p->trapframe->a0;
  case 1:
    return p->trapframe->a1;
  case 2:
    return p->trapframe->a2;
  case 3:
    return p->trapframe->a3;
  case 4:
    return p->trapframe->a4;
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
  *ip = argraw(n);
}

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
  *ip = argraw(n);
}

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
  uint64 addr;
  argaddr(n, &addr);
  return fetchstr(addr, buf, max);
}

// Prototypes for the functions that handle system calls.
extern uint64 sys_fork(void);
extern uint64 sys_exit(void);
extern uint64 sys_wait(void);
extern uint64 sys_pipe(void);
extern uint64 sys_read(void);
extern uint64 sys_kill(void);
extern uint64 sys_exec(void);
extern uint64 sys_fstat(void);
extern uint64 sys_chdir(void);
extern uint64 sys_dup(void);
extern uint64 sys_getpid(void);
extern uint64 sys_sbrk(void);
extern uint64 sys_sleep(void);
extern uint64 sys_uptime(void);
extern uint64 sys_open(void);
extern uint64 sys_write(void);
extern uint64 sys_mknod(void);
extern uint64 sys_unlink(void);
extern uint64 sys_link(void);
extern uint64 sys_mkdir(void);
extern uint64 sys_close(void);

extern uint64 sys_trace(void);//new
extern uint64 sys_history(void);
extern uint   ticks;
extern struct spinlock tickslock;

static char *syscall_names[] = {
  [SYS_fork]    = "fork",
  [SYS_exit]    = "exit",
  [SYS_wait]    = "wait",
  [SYS_pipe]    = "pipe",
  [SYS_read]    = "read",
  [SYS_kill]    = "kill",
  [SYS_exec]    = "exec",
  [SYS_fstat]   = "fstat",
  [SYS_chdir]   = "chdir",
  [SYS_dup]     = "dup",
  [SYS_getpid]  = "getpid",
  [SYS_sbrk]    = "sbrk",
  [SYS_sleep]   = "sleep",
  [SYS_uptime]  = "uptime",
  [SYS_open]    = "open",
  [SYS_write]   = "write",
  [SYS_mknod]   = "mknod",
  [SYS_unlink]  = "unlink",
  [SYS_link]    = "link",
  [SYS_mkdir]   = "mkdir",
  [SYS_close]   = "close",
  [SYS_trace]   = "trace",
  [SYS_history] = "history",
};


// An array mapping syscall numbers from syscall.h
// to the function that handles the system call.
static uint64 (*syscalls[])(void) = {
[SYS_fork]    sys_fork,
[SYS_exit]    sys_exit,
[SYS_wait]    sys_wait,
[SYS_pipe]    sys_pipe,
[SYS_read]    sys_read,
[SYS_kill]    sys_kill,
[SYS_exec]    sys_exec,
[SYS_fstat]   sys_fstat,
[SYS_chdir]   sys_chdir,
[SYS_dup]     sys_dup,
[SYS_getpid]  sys_getpid,
[SYS_sbrk]    sys_sbrk,
[SYS_sleep]   sys_sleep,
[SYS_uptime]  sys_uptime,
[SYS_open]    sys_open,
[SYS_write]   sys_write,
[SYS_mknod]   sys_mknod,
[SYS_unlink]  sys_unlink,
[SYS_link]    sys_link,
[SYS_mkdir]   sys_mkdir,
[SYS_close]   sys_close,
[SYS_trace]   sys_trace,
[SYS_history] sys_history,
};

struct syscall_stat history_stats[NELEM(syscalls)];
struct spinlock history_locks[NELEM(syscalls)];

void historyinit(void){
  int i;

  for(i=0; i< NELEM(history_stats);i++){
    history_stats[i].count=0;
    history_stats[i].accum_time=0;

    if(syscall_names[i]){
      safestrcpy(history_stats[i].syscall_name,
                      syscall_names[i], sizeof(history_stats[i].syscall_name));

    }
    initlock(&history_locks[i], "history");
  }
}

int
get_history(int num, struct syscall_stat *dst)
{
    if(num <= 0 || num >= NELEM(syscalls))
        return -1;

    acquire(&history_locks[num]);

    *dst = history_stats[num];

    release(&history_locks[num]);

    return 0;
}


void
syscall(void)
{
  int num;
  struct proc *p = myproc();

  uint start , end;

  char path[MAXPATH];
  char path2[MAXPATH];
  uint64 addr;
  uint64 argv;

  int fd;
  int n;
  int flags;

  int pid;
  int incr;
  int major;
  int minor;

  num = p->trapframe->a7;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    switch(num){
      case SYS_exec:
        argstr(0,path,sizeof(path));
        argaddr(1, &argv);
        break;

      case SYS_open:
        argstr(0,path,sizeof(path));
        argint(1,&flags);
        break;

      case SYS_read:
        argint(0,&fd);
        argaddr(1, &addr);
        argint(2, &n);
        break;

      case SYS_write:
        argint(0,&fd);
        argaddr(1, &addr);
        argint(2, &n);
        break;

      case SYS_close:
        argint(0, &fd);
        break;

      case SYS_kill:
        argint(0, &pid);
        break;

      case SYS_wait:
        argaddr(0, &addr);
        break;

      case SYS_dup:
        argint(0, &fd);
        break;

      case SYS_chdir:
        argstr(0, path, sizeof(path));
        break;

      case SYS_mkdir:
        argstr(0, path, sizeof(path));
        break;

      case SYS_unlink:
        argstr(0, path, sizeof(path));
        break;

      case SYS_link:
        argstr(0, path, sizeof(path));
        argstr(1, path2, sizeof(path2));
        break; // see note below

      case SYS_mknod:
        argstr(0, path, sizeof(path));
        argint(1, &major);
        argint(2, &minor);
        break;

      case SYS_sbrk:
        argint(0, &incr);
        break;

      case SYS_trace:
        argint(0, &n);
        break;

      case SYS_history:
        argint(0, &n);
        argaddr(1, &addr);
        break;

      case SYS_exit:                                                                                       
        argint(0, &n);                                                                                     
        break;

      case SYS_pipe:                                                                                       
        argaddr(0, &addr);                                                                                 
        break; 

      case SYS_fstat:                                                                                      
        argint(0, &fd);                                                                                    
        argaddr(1, &addr);                                                                                 
        break;

      case SYS_sleep:                                                                                      
        argint(0, &n);                                                                                     
        break;  
    }
    acquire(&tickslock);
    start = ticks;
    release(&tickslock);
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    uint64 ret = syscalls[num]();
    //p->trapframe->a0 = syscalls[num]();
    acquire(&tickslock);  
    end = ticks;
    release(&tickslock);


    p->trapframe->a0 = ret;
    acquire(&history_locks[num]);

    history_stats[num].count++;
    history_stats[num].accum_time += (end-start);

    release(&history_locks[num]);
    if(p->traced_syscall == num){
      printf("pid: %d, syscall: %s, args: (",p->pid,syscall_names[num]);
      switch(num){
        case SYS_exec:
          printf("%s, %p",path,(void *)argv);
          break;

        case SYS_open:
            printf("%s, %d", path, flags);
            break;

        case SYS_read:
            printf("%d, %p, %d", fd, (void *)addr, n);
            break;

        case SYS_close:
            printf("%d", fd);
            break;

        case SYS_write:
            printf("%d, %p, %d", fd, (void *)addr, n);
            break;

        case SYS_kill:
            printf("%d", pid);
            break;

        case SYS_wait:
            printf("%p", (void *)addr);
            break;

        case SYS_dup:
            printf("%d", fd);
            break;

        case SYS_chdir:
            printf("%s", path);
            break;

        case SYS_mkdir:
            printf("%s", path);
            break;

        case SYS_unlink:
            printf("%s", path);
            break;

        case SYS_link:
            printf("%s, %s", path, path2);
            break;

        case SYS_mknod:
            printf("%s, %d, %d", path, major, minor);
            break;

        case SYS_sbrk:
            printf("%d", incr);
            break;

        case SYS_trace:
            printf("%d", n);
            break;

        case SYS_history:
            printf("%d, %p", n, (void *)addr);
            break;

        case SYS_exit:
            printf("%d",n);
            break;

        case SYS_pipe:
            printf("%p",(void *)addr);
            break;

        case SYS_fstat:
            printf("%d, %p",fd ,(void *)addr);
            break;

        case SYS_sleep:
            printf("%d",n);
            break;

        default:
          break;
      }
      printf("), return: %ld\n", ret);
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
  }
}
