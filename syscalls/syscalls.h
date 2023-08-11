/* SPDX-License-Identifier: GPL-2.0-only */
/*
 * syscalls.h - Linux syscall interfaces (non-arch-specific)
 *
 * Copyright (c) 2004 Randy Dunlap
 * Copyright (c) 2004 Open Source Development Labs
 */

#ifndef _LINUX_SYSCALLS_H
#define _LINUX_SYSCALLS_H

struct __aio_sigset;
struct epoll_event;
struct iattr;
struct inode;
struct iocb;
struct io_event;
struct iovec;
struct __kernel_old_itimerval;
struct kexec_segment;
struct linux_dirent;
struct linux_dirent64;
struct list_head;
struct mmap_arg_struct;
struct msgbuf;
struct user_msghdr;
struct mmsghdr;
struct msqid_ds;
struct new_utsname;
struct nfsctl_arg;
struct __old_kernel_stat;
struct oldold_utsname;
struct old_utsname;
struct pollfd;
struct rlimit;
struct rlimit64;
struct rusage;
struct sched_param;
struct sched_attr;
struct sel_arg_struct;
struct semaphore;
struct sembuf;
struct shmid_ds;
struct sockaddr;
struct stat;
struct stat64;
struct statfs;
struct statfs64;
struct statx;
struct sysinfo;
struct timespec;
struct __kernel_old_timeval;
struct __kernel_timex;
struct timezone;
struct tms;
struct utimbuf;
struct mq_attr;
struct compat_stat;
struct old_timeval32;
struct robust_list_head;
struct futex_waitv;
struct getcpu_cache;
struct old_linux_dirent;
struct perf_event_attr;
struct file_handle;
struct sigaltstack;
struct rseq;
union bpf_attr;
struct io_uring_params;
struct clone_args;
struct open_how;
struct mount_attr;
struct landlock_ruleset_attr;
enum landlock_rule_type;
struct cachestat_range;
struct cachestat;

#include <linux/types.h>
#include <linux/aio_abi.h>
#include <linux/capability.h>
#include <linux/signal.h>
#include <linux/list.h>
#include <linux/bug.h>
#include <linux/sem.h>
#include <asm/siginfo.h>
#include <linux/unistd.h>
#include <linux/quota.h>
#include <linux/key.h>
#include <linux/personality.h>
#include <trace/syscall.h>

#ifdef CONFIG_ARCH_HAS_SYSCALL_WRAPPER
/*
 * It may be useful for an architecture to override the definitions of the
 * SYSCALL_DEFINE0() and __SYSCALL_DEFINEx() macros, in particular to use a
 * different calling convention for syscalls. To allow for that, the prototypes
 * for the sys_*() functions below will *not* be included if
 * CONFIG_ARCH_HAS_SYSCALL_WRAPPER is enabled.
 */
#include <asm/syscall_wrapper.h>
#endif /* CONFIG_ARCH_HAS_SYSCALL_WRAPPER */

/*
 * __MAP - apply a macro to syscall arguments
 * __MAP(n, m, t1, a1, t2, a2, ..., tn, an) will expand to
 *    m(t1, a1), m(t2, a2), ..., m(tn, an)
 * The first argument must be equal to the amount of type/name
 * pairs given.  Note that this list of pairs (i.e. the arguments
 * of __MAP starting at the third one) is in the same format as
 * for SYSCALL_DEFINE<n>/COMPAT_SYSCALL_DEFINE<n>
 */
#define __MAP0(m,...)
#define __MAP1(m,t,a,...) m(t,a)
#define __MAP2(m,t,a,...) m(t,a), __MAP1(m,__VA_ARGS__)
#define __MAP3(m,t,a,...) m(t,a), __MAP2(m,__VA_ARGS__)
#define __MAP4(m,t,a,...) m(t,a), __MAP3(m,__VA_ARGS__)
#define __MAP5(m,t,a,...) m(t,a), __MAP4(m,__VA_ARGS__)
#define __MAP6(m,t,a,...) m(t,a), __MAP5(m,__VA_ARGS__)
#define __MAP(n,...) __MAP##n(__VA_ARGS__)

#define __SC_DECL(t, a)	t a
#define __TYPE_AS(t, v)	__same_type((__force t)0, v)
#define __TYPE_IS_L(t)	(__TYPE_AS(t, 0L))
#define __TYPE_IS_UL(t)	(__TYPE_AS(t, 0UL))
#define __TYPE_IS_LL(t) (__TYPE_AS(t, 0LL) || __TYPE_AS(t, 0ULL))
#define __SC_LONG(t, a) __typeof(__builtin_choose_expr(__TYPE_IS_LL(t), 0LL, 0L)) a
#define __SC_CAST(t, a)	(__force t) a
#define __SC_ARGS(t, a)	a
#define __SC_TEST(t, a) (void)BUILD_BUG_ON_ZERO(!__TYPE_IS_LL(t) && sizeof(t) > sizeof(long))

#ifdef CONFIG_FTRACE_SYSCALLS
#define __SC_STR_ADECL(t, a)	#a
#define __SC_STR_TDECL(t, a)	#t

extern struct trace_event_class event_class_syscall_enter;
extern struct trace_event_class event_class_syscall_exit;
extern struct trace_event_functions enter_syscall_print_funcs;
extern struct trace_event_functions exit_syscall_print_funcs;

#define SYSCALL_TRACE_ENTER_EVENT(sname)				\
	static struct syscall_metadata __syscall_meta_##sname;		\
	static struct trace_event_call __used				\
	  event_enter_##sname = {					\
		.class			= &event_class_syscall_enter,	\
		{							\
			.name                   = "sys_enter"#sname,	\
		},							\
		.event.funcs            = &enter_syscall_print_funcs,	\
		.data			= (void *)&__syscall_meta_##sname,\
		.flags                  = TRACE_EVENT_FL_CAP_ANY,	\
	};								\
	static struct trace_event_call __used				\
	  __section("_ftrace_events")					\
	 *__event_enter_##sname = &event_enter_##sname;

#define SYSCALL_TRACE_EXIT_EVENT(sname)					\
	static struct syscall_metadata __syscall_meta_##sname;		\
	static struct trace_event_call __used				\
	  event_exit_##sname = {					\
		.class			= &event_class_syscall_exit,	\
		{							\
			.name                   = "sys_exit"#sname,	\
		},							\
		.event.funcs		= &exit_syscall_print_funcs,	\
		.data			= (void *)&__syscall_meta_##sname,\
		.flags                  = TRACE_EVENT_FL_CAP_ANY,	\
	};								\
	static struct trace_event_call __used				\
	  __section("_ftrace_events")					\
	*__event_exit_##sname = &event_exit_##sname;

#define SYSCALL_METADATA(sname, nb, ...)			\
	static const char *types_##sname[] = {			\
		__MAP(nb,__SC_STR_TDECL,__VA_ARGS__)		\
	};							\
	static const char *args_##sname[] = {			\
		__MAP(nb,__SC_STR_ADECL,__VA_ARGS__)		\
	};							\
	SYSCALL_TRACE_ENTER_EVENT(sname);			\
	SYSCALL_TRACE_EXIT_EVENT(sname);			\
	static struct syscall_metadata __used			\
	  __syscall_meta_##sname = {				\
		.name 		= "sys"#sname,			\
		.syscall_nr	= -1,	/* Filled in at boot */	\
		.nb_args 	= nb,				\
		.types		= nb ? types_##sname : NULL,	\
		.args		= nb ? args_##sname : NULL,	\
		.enter_event	= &event_enter_##sname,		\
		.exit_event	= &event_exit_##sname,		\
		.enter_fields	= LIST_HEAD_INIT(__syscall_meta_##sname.enter_fields), \
	};							\
	static struct syscall_metadata __used			\
	  __section("__syscalls_metadata")			\
	 *__p_syscall_meta_##sname = &__syscall_meta_##sname;

static inline int is_syscall_trace_event(struct trace_event_call *tp_event)
{
	return tp_event->class == &event_class_syscall_enter ||
	       tp_event->class == &event_class_syscall_exit;
}

#else
#define SYSCALL_METADATA(sname, nb, ...)

static inline int is_syscall_trace_event(struct trace_event_call *tp_event)
{
	return 0;
}
#endif

#ifndef SYSCALL_DEFINE0
#define SYSCALL_DEFINE0(sname)					\
	SYSCALL_METADATA(_##sname, 0);				\
	long sys_##sname(void);			\
	ALLOW_ERROR_INJECTION(sys_##sname, ERRNO);		\
	long sys_##sname(void)
#endif /* SYSCALL_DEFINE0 */

#define SYSCALL_DEFINE1(name, ...) SYSCALL_DEFINEx(1, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE2(name, ...) SYSCALL_DEFINEx(2, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE3(name, ...) SYSCALL_DEFINEx(3, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE4(name, ...) SYSCALL_DEFINEx(4, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE5(name, ...) SYSCALL_DEFINEx(5, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE6(name, ...) SYSCALL_DEFINEx(6, _##name, __VA_ARGS__)

#define SYSCALL_DEFINE_MAXARGS	6

#define SYSCALL_DEFINEx(x, sname, ...)				\
	SYSCALL_METADATA(sname, x, __VA_ARGS__)			\
	__SYSCALL_DEFINEx(x, sname, __VA_ARGS__)

#define __PROTECT(...) asmlinkage_protect(__VA_ARGS__)

/*
 * The stub is aliased to a function named __se_sys_*() which
 * sign-extends 32-bit ints to longs whenever needed. The actual work is
 * done within __do_sys_*().
 */
#ifndef __SYSCALL_DEFINEx
#define __SYSCALL_DEFINEx(x, name, ...)					\
	__diag_push();							\
	__diag_ignore(GCC, 8, "-Wattribute-alias",			\
		      "Type aliasing is used to sanitize syscall arguments");\
	long sys##name(__MAP(x,__SC_DECL,__VA_ARGS__))	\
		__attribute__((alias(__stringify(__se_sys##name))));	\
	ALLOW_ERROR_INJECTION(sys##name, ERRNO);			\
	static inline long __do_sys##name(__MAP(x,__SC_DECL,__VA_ARGS__));\
	long __se_sys##name(__MAP(x,__SC_LONG,__VA_ARGS__));	\
	long __se_sys##name(__MAP(x,__SC_LONG,__VA_ARGS__))	\
	{								\
		long ret = __do_sys##name(__MAP(x,__SC_CAST,__VA_ARGS__));\
		__MAP(x,__SC_TEST,__VA_ARGS__);				\
		__PROTECT(x, ret,__MAP(x,__SC_ARGS,__VA_ARGS__));	\
		return ret;						\
	}								\
	__diag_pop();							\
	static inline long __do_sys##name(__MAP(x,__SC_DECL,__VA_ARGS__))
#endif /* __SYSCALL_DEFINEx */

/* For split 64-bit arguments on 32-bit architectures */
#ifdef __LITTLE_ENDIAN
#define SC_ARG64(name) u32, name##_lo, u32, name##_hi
#else
#define SC_ARG64(name) u32, name##_hi, u32, name##_lo
#endif
#define SC_VAL64(type, name) ((type) name##_hi << 32 | name##_lo)

#ifdef CONFIG_COMPAT
#define SYSCALL32_DEFINE0 COMPAT_SYSCALL_DEFINE0
#define SYSCALL32_DEFINE1 COMPAT_SYSCALL_DEFINE1
#define SYSCALL32_DEFINE2 COMPAT_SYSCALL_DEFINE2
#define SYSCALL32_DEFINE3 COMPAT_SYSCALL_DEFINE3
#define SYSCALL32_DEFINE4 COMPAT_SYSCALL_DEFINE4
#define SYSCALL32_DEFINE5 COMPAT_SYSCALL_DEFINE5
#define SYSCALL32_DEFINE6 COMPAT_SYSCALL_DEFINE6
#else
#define SYSCALL32_DEFINE0 SYSCALL_DEFINE0
#define SYSCALL32_DEFINE1 SYSCALL_DEFINE1
#define SYSCALL32_DEFINE2 SYSCALL_DEFINE2
#define SYSCALL32_DEFINE3 SYSCALL_DEFINE3
#define SYSCALL32_DEFINE4 SYSCALL_DEFINE4
#define SYSCALL32_DEFINE5 SYSCALL_DEFINE5
#define SYSCALL32_DEFINE6 SYSCALL_DEFINE6
#endif

/*
 * Called before coming back to user-mode. Returning to user-mode with an
 * address limit different than USER_DS can allow to overwrite kernel memory.
 */
static inline void addr_limit_user_check(void)
{
#ifdef TIF_FSCHECK
	if (!test_thread_flag(TIF_FSCHECK))
		return;
#endif

#ifdef TIF_FSCHECK
	clear_thread_flag(TIF_FSCHECK);
#endif
}

/*
 * These syscall function prototypes are kept in the same order as
 * include/uapi/asm-generic/unistd.h. Architecture specific entries go below,
 * followed by deprecated or obsolete system calls.
 *
 * Please note that these prototypes here are only provided for information
 * purposes, for static analysis, and for linking from the syscall table.
 * These functions should not be called elsewhere from kernel code.
 *
 * As the syscall calling convention may be different from the default
 * for architectures overriding the syscall calling convention, do not
 * include the prototypes if CONFIG_ARCH_HAS_SYSCALL_WRAPPER is enabled.
 */
#ifndef CONFIG_ARCH_HAS_SYSCALL_WRAPPER
long sys_io_setup(unsigned nr_reqs, aio_context_t *ctx);
long sys_io_destroy(aio_context_t ctx);
long sys_io_submit(aio_context_t, long,
			struct iocb * *);
long sys_io_cancel(aio_context_t ctx_id, struct iocb *iocb,
			      struct io_event *result);
long sys_io_getevents(aio_context_t ctx_id,
				long min_nr,
				long nr,
				struct io_event *events,
				struct __kernel_timespec *timeout);
long sys_io_getevents_time32(__u32 ctx_id,
				__s32 min_nr,
				__s32 nr,
				struct io_event *events,
				struct old_timespec32 *timeout);
long sys_io_pgetevents(aio_context_t ctx_id,
				long min_nr,
				long nr,
				struct io_event *events,
				struct __kernel_timespec *timeout,
				const struct __aio_sigset *sig);
long sys_io_pgetevents_time32(aio_context_t ctx_id,
				long min_nr,
				long nr,
				struct io_event *events,
				struct old_timespec32 *timeout,
				const struct __aio_sigset *sig);
long sys_io_uring_setup(u32 entries,
				struct io_uring_params *p);
long sys_io_uring_enter(unsigned int fd, u32 to_submit,
				u32 min_complete, u32 flags,
				const void *argp, size_t argsz);
long sys_io_uring_register(unsigned int fd, unsigned int op,
				void *arg, unsigned int nr_args);
long sys_setxattr(const char *path, const char *name,
			     const void *value, size_t size, int flags);
long sys_lsetxattr(const char *path, const char *name,
			      const void *value, size_t size, int flags);
long sys_fsetxattr(int fd, const char *name,
			      const void *value, size_t size, int flags);
long sys_getxattr(const char *path, const char *name,
			     void *value, size_t size);
long sys_lgetxattr(const char *path, const char *name,
			      void *value, size_t size);
long sys_fgetxattr(int fd, const char *name,
			      void *value, size_t size);
long sys_listxattr(const char *path, char *list,
			      size_t size);
long sys_llistxattr(const char *path, char *list,
			       size_t size);
long sys_flistxattr(int fd, char *list, size_t size);
long sys_removexattr(const char *path,
				const char *name);
long sys_lremovexattr(const char *path,
				 const char *name);
long sys_fremovexattr(int fd, const char *name);
long sys_getcwd(char *buf, unsigned long size);
long sys_lookup_dcookie(u64 cookie64, char *buf, size_t len);
long sys_eventfd2(unsigned int count, int flags);
long sys_epoll_create1(int flags);
long sys_epoll_ctl(int epfd, int op, int fd,
				struct epoll_event *event);
long sys_epoll_pwait(int epfd, struct epoll_event *events,
				int maxevents, int timeout,
				const sigset_t *sigmask,
				size_t sigsetsize);
long sys_epoll_pwait2(int epfd, struct epoll_event *events,
				 int maxevents,
				 const struct __kernel_timespec *timeout,
				 const sigset_t *sigmask,
				 size_t sigsetsize);
long sys_dup(unsigned int fildes);
long sys_dup3(unsigned int oldfd, unsigned int newfd, int flags);
long sys_fcntl(unsigned int fd, unsigned int cmd, unsigned long arg);
#if BITS_PER_LONG == 32
long sys_fcntl64(unsigned int fd,
				unsigned int cmd, unsigned long arg);
#endif
long sys_inotify_init1(int flags);
long sys_inotify_add_watch(int fd, const char *path,
					u32 mask);
long sys_inotify_rm_watch(int fd, __s32 wd);
long sys_ioctl(unsigned int fd, unsigned int cmd,
				unsigned long arg);
long sys_ioprio_set(int which, int who, int ioprio);
long sys_ioprio_get(int which, int who);
long sys_flock(unsigned int fd, unsigned int cmd);
long sys_mknodat(int dfd, const char * filename, umode_t mode,
			    unsigned dev);
long sys_mkdirat(int dfd, const char * pathname, umode_t mode);
long sys_unlinkat(int dfd, const char * pathname, int flag);
long sys_symlinkat(const char * oldname,
			      int newdfd, const char * newname);
long sys_linkat(int olddfd, const char *oldname,
			   int newdfd, const char *newname, int flags);
long sys_renameat(int olddfd, const char * oldname,
			     int newdfd, const char * newname);
long sys_umount(char *name, int flags);
long sys_mount(char *dev_name, char *dir_name,
				char *type, unsigned long flags,
				void *data);
long sys_pivot_root(const char *new_root,
				const char *put_old);
long sys_statfs(const char * path,
				struct statfs *buf);
long sys_statfs64(const char *path, size_t sz,
				struct statfs64 *buf);
long sys_fstatfs(unsigned int fd, struct statfs *buf);
long sys_fstatfs64(unsigned int fd, size_t sz,
				struct statfs64 *buf);
long sys_truncate(const char *path, long length);
long sys_ftruncate(unsigned int fd, unsigned long length);
#if BITS_PER_LONG == 32
long sys_truncate64(const char *path, loff_t length);
long sys_ftruncate64(unsigned int fd, loff_t length);
#endif
long sys_fallocate(int fd, int mode, loff_t offset, loff_t len);
long sys_faccessat(int dfd, const char *filename, int mode);
long sys_faccessat2(int dfd, const char *filename, int mode,
			       int flags);
long sys_chdir(const char *filename);
long sys_fchdir(unsigned int fd);
long sys_chroot(const char *filename);
long sys_fchmod(unsigned int fd, umode_t mode);
long sys_fchmodat(int dfd, const char * filename,
			     umode_t mode);
long sys_fchownat(int dfd, const char *filename, uid_t user,
			     gid_t group, int flag);
long sys_fchown(unsigned int fd, uid_t user, gid_t group);
long sys_openat(int dfd, const char *filename, int flags,
			   umode_t mode);
long sys_openat2(int dfd, const char *filename,
			    struct open_how *how, size_t size);
long sys_close(unsigned int fd);
long sys_close_range(unsigned int fd, unsigned int max_fd,
				unsigned int flags);
long sys_vhangup(void);
long sys_pipe2(int *fildes, int flags);
long sys_quotactl(unsigned int cmd, const char *special,
				qid_t id, void *addr);
long sys_quotactl_fd(unsigned int fd, unsigned int cmd, qid_t id,
				void *addr);
long sys_getdents64(unsigned int fd,
				struct linux_dirent64 *dirent,
				unsigned int count);
long sys_llseek(unsigned int fd, unsigned long offset_high,
			unsigned long offset_low, loff_t *result,
			unsigned int whence);
long sys_lseek(unsigned int fd, off_t offset,
			  unsigned int whence);
long sys_read(unsigned int fd, char *buf, size_t count);
long sys_write(unsigned int fd, const char *buf,
			  size_t count);
long sys_readv(unsigned long fd,
			  const struct iovec *vec,
			  unsigned long vlen);
long sys_writev(unsigned long fd,
			   const struct iovec *vec,
			   unsigned long vlen);
long sys_pread64(unsigned int fd, char *buf,
			    size_t count, loff_t pos);
long sys_pwrite64(unsigned int fd, const char *buf,
			     size_t count, loff_t pos);
long sys_preadv(unsigned long fd, const struct iovec *vec,
			   unsigned long vlen, unsigned long pos_l, unsigned long pos_h);
long sys_pwritev(unsigned long fd, const struct iovec *vec,
			    unsigned long vlen, unsigned long pos_l, unsigned long pos_h);
long sys_sendfile64(int out_fd, int in_fd,
			       loff_t *offset, size_t count);
long sys_pselect6(int, fd_set *, fd_set *,
			     fd_set *, struct __kernel_timespec *,
			     void *);
long sys_pselect6_time32(int, fd_set *, fd_set *,
			     fd_set *, struct old_timespec32 *,
			     void *);
long sys_ppoll(struct pollfd *, unsigned int,
			  struct __kernel_timespec *, const sigset_t *,
			  size_t);
long sys_ppoll_time32(struct pollfd *, unsigned int,
			  struct old_timespec32 *, const sigset_t *,
			  size_t);
long sys_signalfd4(int ufd, sigset_t *user_mask, size_t sizemask, int flags);
long sys_vmsplice(int fd, const struct iovec *iov,
			     unsigned long nr_segs, unsigned int flags);
long sys_splice(int fd_in, loff_t *off_in,
			   int fd_out, loff_t *off_out,
			   size_t len, unsigned int flags);
long sys_tee(int fdin, int fdout, size_t len, unsigned int flags);
long sys_readlinkat(int dfd, const char *path, char *buf,
			       int bufsiz);
long sys_newfstatat(int dfd, const char *filename,
			       struct stat *statbuf, int flag);
long sys_newfstat(unsigned int fd, struct stat *statbuf);
#if defined(__ARCH_WANT_STAT64) || defined(__ARCH_WANT_COMPAT_STAT64)
long sys_fstat64(unsigned long fd, struct stat64 *statbuf);
long sys_fstatat64(int dfd, const char *filename,
			       struct stat64 *statbuf, int flag);
#endif
long sys_sync(void);
long sys_fsync(unsigned int fd);
long sys_fdatasync(unsigned int fd);
long sys_sync_file_range2(int fd, unsigned int flags,
				     loff_t offset, loff_t nbytes);
long sys_sync_file_range(int fd, loff_t offset, loff_t nbytes,
					unsigned int flags);
long sys_timerfd_create(int clockid, int flags);
long sys_timerfd_settime(int ufd, int flags,
				    const struct __kernel_itimerspec *utmr,
				    struct __kernel_itimerspec *otmr);
long sys_timerfd_gettime(int ufd, struct __kernel_itimerspec *otmr);
long sys_timerfd_gettime32(int ufd,
				   struct old_itimerspec32 *otmr);
long sys_timerfd_settime32(int ufd, int flags,
				   const struct old_itimerspec32 *utmr,
				   struct old_itimerspec32 *otmr);
long sys_utimensat(int dfd, const char *filename,
				struct __kernel_timespec *utimes,
				int flags);
long sys_utimensat_time32(unsigned int dfd,
				const char *filename,
				struct old_timespec32 *t, int flags);
long sys_acct(const char *name);
long sys_capget(cap_user_header_t header,
				cap_user_data_t dataptr);
long sys_capset(cap_user_header_t header,
				const cap_user_data_t data);
long sys_personality(unsigned int personality);
long sys_exit(int error_code);
long sys_exit_group(int error_code);
long sys_waitid(int which, pid_t pid,
			   struct siginfo *infop,
			   int options, struct rusage *ru);
long sys_set_tid_address(int *tidptr);
long sys_unshare(unsigned long unshare_flags);
long sys_futex(u32 *uaddr, int op, u32 val,
			  const struct __kernel_timespec *utime,
			  u32 *uaddr2, u32 val3);
long sys_futex_time32(u32 *uaddr, int op, u32 val,
				 const struct old_timespec32 *utime,
				 u32 *uaddr2, u32 val3);
long sys_get_robust_list(int pid,
				    struct robust_list_head * *head_ptr,
				    size_t *len_ptr);
long sys_set_robust_list(struct robust_list_head *head,
				    size_t len);

long sys_futex_waitv(struct futex_waitv *waiters,
				unsigned int nr_futexes, unsigned int flags,
				struct __kernel_timespec *timeout, clockid_t clockid);
long sys_nanosleep(struct __kernel_timespec *rqtp,
			      struct __kernel_timespec *rmtp);
long sys_nanosleep_time32(struct old_timespec32 *rqtp,
				     struct old_timespec32 *rmtp);
long sys_getitimer(int which, struct __kernel_old_itimerval *value);
long sys_setitimer(int which,
				struct __kernel_old_itimerval *value,
				struct __kernel_old_itimerval *ovalue);
long sys_kexec_load(unsigned long entry, unsigned long nr_segments,
				struct kexec_segment *segments,
				unsigned long flags);
long sys_init_module(void *umod, unsigned long len,
				const char *uargs);
long sys_delete_module(const char *name_user,
				unsigned int flags);
long sys_timer_create(clockid_t which_clock,
				 struct sigevent *timer_event_spec,
				 timer_t * created_timer_id);
long sys_timer_gettime(timer_t timer_id,
				struct __kernel_itimerspec *setting);
long sys_timer_getoverrun(timer_t timer_id);
long sys_timer_settime(timer_t timer_id, int flags,
				const struct __kernel_itimerspec *new_setting,
				struct __kernel_itimerspec *old_setting);
long sys_timer_delete(timer_t timer_id);
long sys_clock_settime(clockid_t which_clock,
				const struct __kernel_timespec *tp);
long sys_clock_gettime(clockid_t which_clock,
				struct __kernel_timespec *tp);
long sys_clock_getres(clockid_t which_clock,
				struct __kernel_timespec *tp);
long sys_clock_nanosleep(clockid_t which_clock, int flags,
				const struct __kernel_timespec *rqtp,
				struct __kernel_timespec *rmtp);
long sys_timer_gettime32(timer_t timer_id,
				 struct old_itimerspec32 *setting);
long sys_timer_settime32(timer_t timer_id, int flags,
					 struct old_itimerspec32 *new,
					 struct old_itimerspec32 *old);
long sys_clock_settime32(clockid_t which_clock,
				struct old_timespec32 *tp);
long sys_clock_gettime32(clockid_t which_clock,
				struct old_timespec32 *tp);
long sys_clock_getres_time32(clockid_t which_clock,
				struct old_timespec32 *tp);
long sys_clock_nanosleep_time32(clockid_t which_clock, int flags,
				struct old_timespec32 *rqtp,
				struct old_timespec32 *rmtp);
long sys_syslog(int type, char *buf, int len);
long sys_ptrace(long request, long pid, unsigned long addr,
			   unsigned long data);
long sys_sched_setparam(pid_t pid,
					struct sched_param *param);
long sys_sched_setscheduler(pid_t pid, int policy,
					struct sched_param *param);
long sys_sched_getscheduler(pid_t pid);
long sys_sched_getparam(pid_t pid,
					struct sched_param *param);
long sys_sched_setaffinity(pid_t pid, unsigned int len,
					unsigned long *user_mask_ptr);
long sys_sched_getaffinity(pid_t pid, unsigned int len,
					unsigned long *user_mask_ptr);
long sys_sched_yield(void);
long sys_sched_get_priority_max(int policy);
long sys_sched_get_priority_min(int policy);
long sys_sched_rr_get_interval(pid_t pid,
				struct __kernel_timespec *interval);
long sys_sched_rr_get_interval_time32(pid_t pid,
						 struct old_timespec32 *interval);
long sys_restart_syscall(void);
long sys_kill(pid_t pid, int sig);
long sys_tkill(pid_t pid, int sig);
long sys_tgkill(pid_t tgid, pid_t pid, int sig);
long sys_sigaltstack(const struct sigaltstack *uss,
				struct sigaltstack *uoss);
long sys_rt_sigsuspend(sigset_t *unewset, size_t sigsetsize);
#ifndef CONFIG_ODD_RT_SIGACTION
long sys_rt_sigaction(int,
				 const struct sigaction *,
				 struct sigaction *,
				 size_t);
#endif
long sys_rt_sigprocmask(int how, sigset_t *set,
				sigset_t *oset, size_t sigsetsize);
long sys_rt_sigpending(sigset_t *set, size_t sigsetsize);
long sys_rt_sigtimedwait(const sigset_t *uthese,
				siginfo_t *uinfo,
				const struct __kernel_timespec *uts,
				size_t sigsetsize);
long sys_rt_sigtimedwait_time32(const sigset_t *uthese,
				siginfo_t *uinfo,
				const struct old_timespec32 *uts,
				size_t sigsetsize);
long sys_rt_sigqueueinfo(pid_t pid, int sig, siginfo_t *uinfo);
long sys_setpriority(int which, int who, int niceval);
long sys_getpriority(int which, int who);
long sys_reboot(int magic1, int magic2, unsigned int cmd,
				void *arg);
long sys_setregid(gid_t rgid, gid_t egid);
long sys_setgid(gid_t gid);
long sys_setreuid(uid_t ruid, uid_t euid);
long sys_setuid(uid_t uid);
long sys_setresuid(uid_t ruid, uid_t euid, uid_t suid);
long sys_getresuid(uid_t *ruid, uid_t *euid, uid_t *suid);
long sys_setresgid(gid_t rgid, gid_t egid, gid_t sgid);
long sys_getresgid(gid_t *rgid, gid_t *egid, gid_t *sgid);
long sys_setfsuid(uid_t uid);
long sys_setfsgid(gid_t gid);
long sys_times(struct tms *tbuf);
long sys_setpgid(pid_t pid, pid_t pgid);
long sys_getpgid(pid_t pid);
long sys_getsid(pid_t pid);
long sys_setsid(void);
long sys_getgroups(int gidsetsize, gid_t *grouplist);
long sys_setgroups(int gidsetsize, gid_t *grouplist);
long sys_newuname(struct new_utsname *name);
long sys_sethostname(char *name, int len);
long sys_setdomainname(char *name, int len);
long sys_getrlimit(unsigned int resource,
				struct rlimit *rlim);
long sys_setrlimit(unsigned int resource,
				struct rlimit *rlim);
long sys_getrusage(int who, struct rusage *ru);
long sys_umask(int mask);
long sys_prctl(int option, unsigned long arg2, unsigned long arg3,
			unsigned long arg4, unsigned long arg5);
long sys_getcpu(unsigned *cpu, unsigned *node, struct getcpu_cache *cache);
long sys_gettimeofday(struct __kernel_old_timeval *tv,
				struct timezone *tz);
long sys_settimeofday(struct __kernel_old_timeval *tv,
				struct timezone *tz);
long sys_adjtimex(struct __kernel_timex *txc_p);
long sys_adjtimex_time32(struct old_timex32 *txc_p);
long sys_getpid(void);
long sys_getppid(void);
long sys_getuid(void);
long sys_geteuid(void);
long sys_getgid(void);
long sys_getegid(void);
long sys_gettid(void);
long sys_sysinfo(struct sysinfo *info);
long sys_mq_open(const char *name, int oflag, umode_t mode, struct mq_attr *attr);
long sys_mq_unlink(const char *name);
long sys_mq_timedsend(mqd_t mqdes, const char *msg_ptr, size_t msg_len, unsigned int msg_prio, const struct __kernel_timespec *abs_timeout);
long sys_mq_timedreceive(mqd_t mqdes, char *msg_ptr, size_t msg_len, unsigned int *msg_prio, const struct __kernel_timespec *abs_timeout);
long sys_mq_notify(mqd_t mqdes, const struct sigevent *notification);
long sys_mq_getsetattr(mqd_t mqdes, const struct mq_attr *mqstat, struct mq_attr *omqstat);
long sys_mq_timedreceive_time32(mqd_t mqdes,
			char *u_msg_ptr,
			unsigned int msg_len, unsigned int *u_msg_prio,
			const struct old_timespec32 *u_abs_timeout);
long sys_mq_timedsend_time32(mqd_t mqdes,
			const char *u_msg_ptr,
			unsigned int msg_len, unsigned int msg_prio,
			const struct old_timespec32 *u_abs_timeout);
long sys_msgget(key_t key, int msgflg);
long sys_old_msgctl(int msqid, int cmd, struct msqid_ds *buf);
long sys_msgctl(int msqid, int cmd, struct msqid_ds *buf);
long sys_msgrcv(int msqid, struct msgbuf *msgp,
				size_t msgsz, long msgtyp, int msgflg);
long sys_msgsnd(int msqid, struct msgbuf *msgp,
				size_t msgsz, int msgflg);
long sys_semget(key_t key, int nsems, int semflg);
long sys_semctl(int semid, int semnum, int cmd, unsigned long arg);
long sys_old_semctl(int semid, int semnum, int cmd, unsigned long arg);
long sys_semtimedop(int semid, struct sembuf *sops,
				unsigned nsops,
				const struct __kernel_timespec *timeout);
long sys_semtimedop_time32(int semid, struct sembuf *sops,
				unsigned nsops,
				const struct old_timespec32 *timeout);
long sys_semop(int semid, struct sembuf *sops,
				unsigned nsops);
long sys_shmget(key_t key, size_t size, int flag);
long sys_old_shmctl(int shmid, int cmd, struct shmid_ds *buf);
long sys_shmctl(int shmid, int cmd, struct shmid_ds *buf);
long sys_shmat(int shmid, char *shmaddr, int shmflg);
long sys_shmdt(char *shmaddr);
long sys_socket(int, int, int);
long sys_socketpair(int, int, int, int *);
long sys_bind(int, struct sockaddr *, int);
long sys_listen(int, int);
long sys_accept(int, struct sockaddr *, int *);
long sys_connect(int, struct sockaddr *, int);
long sys_getsockname(int, struct sockaddr *, int *);
long sys_getpeername(int, struct sockaddr *, int *);
long sys_sendto(int, void *, size_t, unsigned,
				struct sockaddr *, int);
long sys_recvfrom(int, void *, size_t, unsigned,
				struct sockaddr *, int *);
long sys_setsockopt(int fd, int level, int optname,
				char *optval, int optlen);
long sys_getsockopt(int fd, int level, int optname,
				char *optval, int *optlen);
long sys_shutdown(int, int);
long sys_sendmsg(int fd, struct user_msghdr *msg, unsigned flags);
long sys_recvmsg(int fd, struct user_msghdr *msg, unsigned flags);
long sys_readahead(int fd, loff_t offset, size_t count);
long sys_brk(unsigned long brk);
long sys_munmap(unsigned long addr, size_t len);
long sys_mremap(unsigned long addr,
			   unsigned long old_len, unsigned long new_len,
			   unsigned long flags, unsigned long new_addr);
long sys_add_key(const char *_type,
			    const char *_description,
			    const void *_payload,
			    size_t plen,
			    key_serial_t destringid);
long sys_request_key(const char *_type,
				const char *_description,
				const char *_callout_info,
				key_serial_t destringid);
long sys_keyctl(int cmd, unsigned long arg2, unsigned long arg3,
			   unsigned long arg4, unsigned long arg5);
#ifdef CONFIG_CLONE_BACKWARDS
long sys_clone(unsigned long, unsigned long, int *, unsigned long,
	       int *);
#else
#ifdef CONFIG_CLONE_BACKWARDS3
long sys_clone(unsigned long, unsigned long, int, int *,
			  int *, unsigned long);
#else
long sys_clone(unsigned long, unsigned long, int *,
	       int *, unsigned long);
#endif
#endif

long sys_clone3(struct clone_args *uargs, size_t size);

long sys_execve(const char *filename,
		const char *const *argv,
		const char *const *envp);
long sys_fadvise64_64(int fd, loff_t offset, loff_t len, int advice);

/* CONFIG_MMU only */
long sys_swapon(const char *specialfile, int swap_flags);
long sys_swapoff(const char *specialfile);
long sys_mprotect(unsigned long start, size_t len,
				unsigned long prot);
long sys_msync(unsigned long start, size_t len, int flags);
long sys_mlock(unsigned long start, size_t len);
long sys_munlock(unsigned long start, size_t len);
long sys_mlockall(int flags);
long sys_munlockall(void);
long sys_mincore(unsigned long start, size_t len,
				unsigned char * vec);
long sys_madvise(unsigned long start, size_t len, int behavior);
long sys_process_madvise(int pidfd, const struct iovec *vec,
			size_t vlen, int behavior, unsigned int flags);
long sys_process_mrelease(int pidfd, unsigned int flags);
long sys_remap_file_pages(unsigned long start, unsigned long size,
			unsigned long prot, unsigned long pgoff,
			unsigned long flags);
long sys_mbind(unsigned long start, unsigned long len,
				unsigned long mode,
				const unsigned long *nmask,
				unsigned long maxnode,
				unsigned flags);
long sys_get_mempolicy(int *policy,
				unsigned long *nmask,
				unsigned long maxnode,
				unsigned long addr, unsigned long flags);
long sys_set_mempolicy(int mode, const unsigned long *nmask,
				unsigned long maxnode);
long sys_migrate_pages(pid_t pid, unsigned long maxnode,
				const unsigned long *from,
				const unsigned long *to);
long sys_move_pages(pid_t pid, unsigned long nr_pages,
				const void * *pages,
				const int *nodes,
				int *status,
				int flags);
long sys_rt_tgsigqueueinfo(pid_t tgid, pid_t  pid, int sig,
		siginfo_t *uinfo);
long sys_perf_event_open(
		struct perf_event_attr *attr_uptr,
		pid_t pid, int cpu, int group_fd, unsigned long flags);
long sys_accept4(int, struct sockaddr *, int *, int);
long sys_recvmmsg(int fd, struct mmsghdr *msg,
			     unsigned int vlen, unsigned flags,
			     struct __kernel_timespec *timeout);
long sys_recvmmsg_time32(int fd, struct mmsghdr *msg,
			     unsigned int vlen, unsigned flags,
			     struct old_timespec32 *timeout);
long sys_wait4(pid_t pid, int *stat_addr,
				int options, struct rusage *ru);
long sys_prlimit64(pid_t pid, unsigned int resource,
				const struct rlimit64 *new_rlim,
				struct rlimit64 *old_rlim);
long sys_fanotify_init(unsigned int flags, unsigned int event_f_flags);
long sys_fanotify_mark(int fanotify_fd, unsigned int flags,
				  u64 mask, int fd,
				  const char  *pathname);
long sys_name_to_handle_at(int dfd, const char *name,
				      struct file_handle *handle,
				      int *mnt_id, int flag);
long sys_open_by_handle_at(int mountdirfd,
				      struct file_handle *handle,
				      int flags);
long sys_clock_adjtime(clockid_t which_clock,
				struct __kernel_timex *tx);
long sys_clock_adjtime32(clockid_t which_clock,
				struct old_timex32 *tx);
long sys_syncfs(int fd);
long sys_setns(int fd, int nstype);
long sys_pidfd_open(pid_t pid, unsigned int flags);
long sys_sendmmsg(int fd, struct mmsghdr *msg,
			     unsigned int vlen, unsigned flags);
long sys_process_vm_readv(pid_t pid,
				     const struct iovec *lvec,
				     unsigned long liovcnt,
				     const struct iovec *rvec,
				     unsigned long riovcnt,
				     unsigned long flags);
long sys_process_vm_writev(pid_t pid,
				      const struct iovec *lvec,
				      unsigned long liovcnt,
				      const struct iovec *rvec,
				      unsigned long riovcnt,
				      unsigned long flags);
long sys_kcmp(pid_t pid1, pid_t pid2, int type,
			 unsigned long idx1, unsigned long idx2);
long sys_finit_module(int fd, const char *uargs, int flags);
long sys_sched_setattr(pid_t pid,
					struct sched_attr *attr,
					unsigned int flags);
long sys_sched_getattr(pid_t pid,
					struct sched_attr *attr,
					unsigned int size,
					unsigned int flags);
long sys_renameat2(int olddfd, const char *oldname,
			      int newdfd, const char *newname,
			      unsigned int flags);
long sys_seccomp(unsigned int op, unsigned int flags,
			    void *uargs);
long sys_getrandom(char *buf, size_t count,
			      unsigned int flags);
long sys_memfd_create(const char *uname_ptr, unsigned int flags);
long sys_bpf(int cmd, union bpf_attr *attr, unsigned int size);
long sys_execveat(int dfd, const char *filename,
			const char *const *argv,
			const char *const *envp, int flags);
long sys_userfaultfd(int flags);
long sys_membarrier(int cmd, unsigned int flags, int cpu_id);
long sys_mlock2(unsigned long start, size_t len, int flags);
long sys_copy_file_range(int fd_in, loff_t *off_in,
				    int fd_out, loff_t *off_out,
				    size_t len, unsigned int flags);
long sys_preadv2(unsigned long fd, const struct iovec *vec,
			    unsigned long vlen, unsigned long pos_l, unsigned long pos_h,
			    rwf_t flags);
long sys_pwritev2(unsigned long fd, const struct iovec *vec,
			    unsigned long vlen, unsigned long pos_l, unsigned long pos_h,
			    rwf_t flags);
long sys_pkey_mprotect(unsigned long start, size_t len,
				  unsigned long prot, int pkey);
long sys_pkey_alloc(unsigned long flags, unsigned long init_val);
long sys_pkey_free(int pkey);
long sys_statx(int dfd, const char *path, unsigned flags,
			  unsigned mask, struct statx *buffer);
long sys_rseq(struct rseq *rseq, uint32_t rseq_len,
			 int flags, uint32_t sig);
long sys_open_tree(int dfd, const char *path, unsigned flags);
long sys_move_mount(int from_dfd, const char *from_path,
			       int to_dfd, const char *to_path,
			       unsigned int ms_flags);
long sys_mount_setattr(int dfd, const char *path,
				  unsigned int flags,
				  struct mount_attr *uattr, size_t usize);
long sys_fsopen(const char *fs_name, unsigned int flags);
long sys_fsconfig(int fs_fd, unsigned int cmd, const char *key,
			     const void *value, int aux);
long sys_fsmount(int fs_fd, unsigned int flags, unsigned int ms_flags);
long sys_fspick(int dfd, const char *path, unsigned int flags);
long sys_pidfd_send_signal(int pidfd, int sig,
				       siginfo_t *info,
				       unsigned int flags);
long sys_pidfd_getfd(int pidfd, int fd, unsigned int flags);
long sys_landlock_create_ruleset(const struct landlock_ruleset_attr *attr,
		size_t size, __u32 flags);
long sys_landlock_add_rule(int ruleset_fd, enum landlock_rule_type rule_type,
		const void *rule_attr, __u32 flags);
long sys_landlock_restrict_self(int ruleset_fd, __u32 flags);
long sys_memfd_secret(unsigned int flags);
long sys_set_mempolicy_home_node(unsigned long start, unsigned long len,
					    unsigned long home_node,
					    unsigned long flags);
long sys_cachestat(unsigned int fd,
		struct cachestat_range *cstat_range,
		struct cachestat *cstat, unsigned int flags);

/*
 * Architecture-specific system calls
 */

/* x86 */
long sys_ioperm(unsigned long from, unsigned long num, int on);

/* pciconfig: alpha, arm, arm64, ia64, sparc */
long sys_pciconfig_read(unsigned long bus, unsigned long dfn,
				unsigned long off, unsigned long len,
				void *buf);
long sys_pciconfig_write(unsigned long bus, unsigned long dfn,
				unsigned long off, unsigned long len,
				void *buf);
long sys_pciconfig_iobase(long which, unsigned long bus, unsigned long devfn);

/* powerpc */
long sys_spu_run(int fd, __u32 *unpc,
				 __u32 *ustatus);
long sys_spu_create(const char *name,
		unsigned int flags, umode_t mode, int fd);


/*
 * Deprecated system calls which are still defined in
 * include/uapi/asm-generic/unistd.h and wanted by >= 1 arch
 */

/* __ARCH_WANT_SYSCALL_NO_AT */
long sys_open(const char *filename,
				int flags, umode_t mode);
long sys_link(const char *oldname,
				const char *newname);
long sys_unlink(const char *pathname);
long sys_mknod(const char *filename, umode_t mode,
				unsigned dev);
long sys_chmod(const char *filename, umode_t mode);
long sys_chown(const char *filename,
				uid_t user, gid_t group);
long sys_mkdir(const char *pathname, umode_t mode);
long sys_rmdir(const char *pathname);
long sys_lchown(const char *filename,
				uid_t user, gid_t group);
long sys_access(const char *filename, int mode);
long sys_rename(const char *oldname,
				const char *newname);
long sys_symlink(const char *old, const char *new);
#if defined(__ARCH_WANT_STAT64) || defined(__ARCH_WANT_COMPAT_STAT64)
long sys_stat64(const char *filename,
				struct stat64 *statbuf);
long sys_lstat64(const char *filename,
				struct stat64 *statbuf);
#endif

/* __ARCH_WANT_SYSCALL_NO_FLAGS */
long sys_pipe(int *fildes);
long sys_dup2(unsigned int oldfd, unsigned int newfd);
long sys_epoll_create(int size);
long sys_inotify_init(void);
long sys_eventfd(unsigned int count);
long sys_signalfd(int ufd, sigset_t *user_mask, size_t sizemask);

/* __ARCH_WANT_SYSCALL_OFF_T */
long sys_sendfile(int out_fd, int in_fd,
			     off_t *offset, size_t count);
long sys_newstat(const char *filename,
				struct stat *statbuf);
long sys_newlstat(const char *filename,
				struct stat *statbuf);
long sys_fadvise64(int fd, loff_t offset, size_t len, int advice);

/* __ARCH_WANT_SYSCALL_DEPRECATED */
long sys_alarm(unsigned int seconds);
long sys_getpgrp(void);
long sys_pause(void);
long sys_time(__kernel_old_time_t *tloc);
long sys_time32(old_time32_t *tloc);
#ifdef __ARCH_WANT_SYS_UTIME
long sys_utime(char *filename,
				struct utimbuf *times);
long sys_utimes(char *filename,
				struct __kernel_old_timeval *utimes);
long sys_futimesat(int dfd, const char *filename,
			      struct __kernel_old_timeval *utimes);
#endif
long sys_futimesat_time32(unsigned int dfd,
				     const char *filename,
				     struct old_timeval32 *t);
long sys_utime32(const char *filename,
				 struct old_utimbuf32 *t);
long sys_utimes_time32(const char *filename,
				  struct old_timeval32 *t);
long sys_creat(const char *pathname, umode_t mode);
long sys_getdents(unsigned int fd,
				struct linux_dirent *dirent,
				unsigned int count);
long sys_select(int n, fd_set *inp, fd_set *outp,
			fd_set *exp, struct __kernel_old_timeval *tvp);
long sys_poll(struct pollfd *ufds, unsigned int nfds,
				int timeout);
long sys_epoll_wait(int epfd, struct epoll_event *events,
				int maxevents, int timeout);
long sys_ustat(unsigned dev, struct ustat *ubuf);
long sys_vfork(void);
long sys_recv(int, void *, size_t, unsigned);
long sys_send(int, void *, size_t, unsigned);
long sys_oldumount(char *name);
long sys_uselib(const char *library);
long sys_sysfs(int option,
				unsigned long arg1, unsigned long arg2);
long sys_fork(void);

/* obsolete */
long sys_stime(__kernel_old_time_t *tptr);
long sys_stime32(old_time32_t *tptr);

/* obsolete */
long sys_sigpending(old_sigset_t *uset);
long sys_sigprocmask(int how, old_sigset_t *set,
				old_sigset_t *oset);
#ifdef CONFIG_OLD_SIGSUSPEND
long sys_sigsuspend(old_sigset_t mask);
#endif

#ifdef CONFIG_OLD_SIGSUSPEND3
long sys_sigsuspend(int unused1, int unused2, old_sigset_t mask);
#endif

#ifdef CONFIG_OLD_SIGACTION
long sys_sigaction(int, const struct old_sigaction *,
				struct old_sigaction *);
#endif
long sys_sgetmask(void);
long sys_ssetmask(int newmask);
long sys_signal(int sig, __sighandler_t handler);

/* obsolete */
long sys_nice(int increment);

/* obsolete */
long sys_kexec_file_load(int kernel_fd, int initrd_fd,
				    unsigned long cmdline_len,
				    const char *cmdline_ptr,
				    unsigned long flags);

/* obsolete */
long sys_waitpid(pid_t pid, int *stat_addr, int options);

/* obsolete */
#ifdef CONFIG_HAVE_UID16
long sys_chown16(const char *filename,
				old_uid_t user, old_gid_t group);
long sys_lchown16(const char *filename,
				old_uid_t user, old_gid_t group);
long sys_fchown16(unsigned int fd, old_uid_t user, old_gid_t group);
long sys_setregid16(old_gid_t rgid, old_gid_t egid);
long sys_setgid16(old_gid_t gid);
long sys_setreuid16(old_uid_t ruid, old_uid_t euid);
long sys_setuid16(old_uid_t uid);
long sys_setresuid16(old_uid_t ruid, old_uid_t euid, old_uid_t suid);
long sys_getresuid16(old_uid_t *ruid,
				old_uid_t *euid, old_uid_t *suid);
long sys_setresgid16(old_gid_t rgid, old_gid_t egid, old_gid_t sgid);
long sys_getresgid16(old_gid_t *rgid,
				old_gid_t *egid, old_gid_t *sgid);
long sys_setfsuid16(old_uid_t uid);
long sys_setfsgid16(old_gid_t gid);
long sys_getgroups16(int gidsetsize, old_gid_t *grouplist);
long sys_setgroups16(int gidsetsize, old_gid_t *grouplist);
long sys_getuid16(void);
long sys_geteuid16(void);
long sys_getgid16(void);
long sys_getegid16(void);
#endif

/* obsolete */
long sys_socketcall(int call, unsigned long *args);

/* obsolete */
long sys_stat(const char *filename,
			struct __old_kernel_stat *statbuf);
long sys_lstat(const char *filename,
			struct __old_kernel_stat *statbuf);
long sys_fstat(unsigned int fd,
			struct __old_kernel_stat *statbuf);
long sys_readlink(const char *path,
				char *buf, int bufsiz);

/* obsolete */
long sys_old_select(struct sel_arg_struct *arg);

/* obsolete */
long sys_old_readdir(unsigned int, struct old_linux_dirent *, unsigned int);

/* obsolete */
long sys_gethostname(char *name, int len);
long sys_uname(struct old_utsname *);
long sys_olduname(struct oldold_utsname *);
#ifdef __ARCH_WANT_SYS_OLD_GETRLIMIT
long sys_old_getrlimit(unsigned int resource, struct rlimit *rlim);
#endif

/* obsolete */
long sys_ipc(unsigned int call, int first, unsigned long second,
		unsigned long third, void *ptr, long fifth);

/* obsolete */
long sys_mmap_pgoff(unsigned long addr, unsigned long len,
			unsigned long prot, unsigned long flags,
			unsigned long fd, unsigned long pgoff);
long sys_old_mmap(struct mmap_arg_struct *arg);


/*
 * Not a real system call, but a placeholder for syscalls which are
 * not implemented -- see kernel/sys_ni.c
 */
long sys_ni_syscall(void);

#endif /* CONFIG_ARCH_HAS_SYSCALL_WRAPPER */

long sys_ni_posix_timers(void);

/*
 * Kernel code should not call syscalls (i.e., sys_xyzyyz()) directly.
 * Instead, use one of the functions which work equivalently, such as
 * the ksys_xyzyyz() functions prototyped below.
 */
ssize_t ksys_write(unsigned int fd, const char *buf, size_t count);
int ksys_fchown(unsigned int fd, uid_t user, gid_t group);
ssize_t ksys_read(unsigned int fd, char *buf, size_t count);
void ksys_sync(void);
int ksys_unshare(unsigned long unshare_flags);
int ksys_setsid(void);
int ksys_sync_file_range(int fd, loff_t offset, loff_t nbytes,
			 unsigned int flags);
ssize_t ksys_pread64(unsigned int fd, char *buf, size_t count,
		     loff_t pos);
ssize_t ksys_pwrite64(unsigned int fd, const char *buf,
		      size_t count, loff_t pos);
int ksys_fallocate(int fd, int mode, loff_t offset, loff_t len);
#ifdef CONFIG_ADVISE_SYSCALLS
int ksys_fadvise64_64(int fd, loff_t offset, loff_t len, int advice);
#else
static inline int ksys_fadvise64_64(int fd, loff_t offset, loff_t len,
				    int advice)
{
	return -EINVAL;
}
#endif
unsigned long ksys_mmap_pgoff(unsigned long addr, unsigned long len,
			      unsigned long prot, unsigned long flags,
			      unsigned long fd, unsigned long pgoff);
ssize_t ksys_readahead(int fd, loff_t offset, size_t count);
int ksys_ipc(unsigned int call, int first, unsigned long second,
	unsigned long third, void * ptr, long fifth);
int compat_ksys_ipc(u32 call, int first, int second,
	u32 third, u32 ptr, u32 fifth);

/*
 * The following kernel syscall equivalents are just wrappers to fs-internal
 * functions. Therefore, provide stubs to be inlined at the callsites.
 */
extern int do_fchownat(int dfd, const char *filename, uid_t user,
		       gid_t group, int flag);

static inline long ksys_chown(const char *filename, uid_t user,
			      gid_t group)
{
	return do_fchownat(AT_FDCWD, filename, user, group, 0);
}

static inline long ksys_lchown(const char *filename, uid_t user,
			       gid_t group)
{
	return do_fchownat(AT_FDCWD, filename, user, group,
			     AT_SYMLINK_NOFOLLOW);
}

extern long do_sys_ftruncate(unsigned int fd, loff_t length, int small);

static inline long ksys_ftruncate(unsigned int fd, loff_t length)
{
	return do_sys_ftruncate(fd, length, 1);
}

extern long do_sys_truncate(const char *pathname, loff_t length);

static inline long ksys_truncate(const char *pathname, loff_t length)
{
	return do_sys_truncate(pathname, length);
}

static inline unsigned int ksys_personality(unsigned int personality)
{
	unsigned int old = current->personality;

	if (personality != 0xffffffff)
		set_personality(personality);

	return old;
}

/* for __ARCH_WANT_SYS_IPC */
long ksys_semtimedop(int semid, struct sembuf *tsops,
		     unsigned int nsops,
		     const struct __kernel_timespec *timeout);
long ksys_semget(key_t key, int nsems, int semflg);
long ksys_old_semctl(int semid, int semnum, int cmd, unsigned long arg);
long ksys_msgget(key_t key, int msgflg);
long ksys_old_msgctl(int msqid, int cmd, struct msqid_ds *buf);
long ksys_msgrcv(int msqid, struct msgbuf *msgp, size_t msgsz,
		 long msgtyp, int msgflg);
long ksys_msgsnd(int msqid, struct msgbuf *msgp, size_t msgsz,
		 int msgflg);
long ksys_shmget(key_t key, size_t size, int shmflg);
long ksys_shmdt(char *shmaddr);
long ksys_old_shmctl(int shmid, int cmd, struct shmid_ds *buf);
long compat_ksys_semtimedop(int semid, struct sembuf *tsems,
			    unsigned int nsops,
			    const struct old_timespec32 *timeout);
long __do_semtimedop(int semid, struct sembuf *tsems, unsigned int nsops,
		     const struct timespec64 *timeout,
		     struct ipc_namespace *ns);

int __sys_getsockopt(int fd, int level, int optname, char *optval,
		int *optlen);
int __sys_setsockopt(int fd, int level, int optname, char *optval,
		int optlen);
#endif
