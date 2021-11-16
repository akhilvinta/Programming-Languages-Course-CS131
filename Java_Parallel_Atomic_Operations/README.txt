
Project 3 Implementation:

Basic Details:

1. Input read: I first read the input file from stdin sequentially: Because the input stream is sequential, there is no increase in program speed that could result from parallelizing this input read. I break the input file into a fixed size of bytes that I will call a block. I will then pass these blocks into different threads, to be compressed individually. 
 
2. Compression: I now compress each of my blocks individually, one in each thread as designated by which threads are open in the thread pool.I will create a number of threads in the threads pool such that it is equal to the number of processors on the running machine. In order to comply with pigz standards, I must send with each block a fixed number of bytes that came from the preceding block. To meet this regulation, I keep a concurrent hashmap data structure that will be shared amongst all threads. Each block will pass the appropriate fixed number of bytes to said data structure so that the following block can use it for deflation and compression. However, if each block requires the completion of the previous block's thread in order to run, then my program is still running sequentially, as each thread requires the previous thread's completion before initiating its own sequence. Therefore, I simply place a block in the dictionary everytime it is read from stdin. When thread x is running, it checks if block x-1 has been entered in the dictionary. If so, it simply uses that block for compression. Because of this, I no longer have a thread-to-thread dependency, and my program can achieve the desired parallelism. 

3. Output write: This process is simple. As soon as block 1 finishes, write block 1 return compressed bytes to stdout. As soon as block 2 finishes, check if block 1 has finished. If so, print block 2 output, etc. Essentially, every block can output its return value as soon as all of the blocks before it have outputted their value. Therefore, this cannot be parallelized, and this portion of the program control flow will be sequential. However, we can to an extent parallelize output write and compression, so that some runtime is saved there. 

Implementation Performance Assessment:

I used the given commands in the spec to compare the runtime of my pgizj implementation with that of the standard library pgiz and gzip. Because I am comparing the multicore version of the programs, I use real time to compare results. 


Input file size: 125942959 bytes

8 cores available. Average of 3 trials for each: 

gzip average: 

real	0m8.253s
user	0m7.481s
sys	0m0.067s

Compression ratio: 0.3435 -- output file size: 43261332 average

pigz average: 

real	0m2.841s
user	0m7.385s
sys	0m0.037s

Compression ratio: 0.3425 -- output file size: 43134815 average

pigzj average:

real	0m3.229s
user	0m7.731s
sys	0m0.377s

Compression ratio: 0.3425 -- output file size: 43136282


4 cores available. Average of 3 trials for each: 


gzip average: 

real	0m7.770s
user	0m7.470s
sys	0m0.053s

Compression ratio: 0.3435 -- output file size: 43261332 average

pigz average: 

real	0m2.776s
user	0m7.391s
sys	0m0.024s

Compression ratio: 0.3425 -- output file size: 43134815 average

pigzj average:

real	0m3.506s
user	0m7.671s
sys	0m0.446s

Compression ratio: 0.3425 -- output file size: 43136282 average 


2 cores available. Average of 3 trials for each: 

gzip average: 

real	0m7.770s
user	0m7.470s
sys	0m0.053s

Compression ratio: 0.3435 -- output file size: 43261332 average

pigz average: 

real	0m2.776s
user	0m7.391s
sys	0m0.024s

Compression ratio: 0.3425 -- output file size: 43134815 average

pigzj average:

real	0m4.757s
user	0m7.657s
sys	0m0.369s

Compression ratio: 0.3425 -- output file size: 43136282 average 


1 core available. Average of 3 trials for each: 

gzip average: 

real	0m7.814s
user	0m7.460s
sys	0m0.054s

Compression ratio: 0.3435 -- output file size: 43261332 average

pigz average: 

real	0m8.162s
user	0m7.245s
sys	0m0.062s

Compression ratio: 0.3425 -- output file size: 43134815 average


pigzj average:

real	0m8.232s
user	0m7.642s
sys	0m0.389s

Compression ratio: 0.3425 -- output file size: 43136282 average 


From the tests, there are a few trends that are immediately clear:

1. gzip is clearly not utilizing parallelization, as the program runtime is relatively similar regardless of the number of cores utilized. 

2. pgizj and pigz seem to scale relatively well with the number of cpu cores utilized in the program. This means that both executables are making good use of parallelization. 

3. With multiple cores enabled, both pigz and pigzj outperform gzip by a significant margin. This shows the benefits that can be encapsulated by utilizing parallelization. 

4. It seems as though the pigz standard library compression tool is simply faster than my pigzj implementation, regardless of the number of cpu cores involved with program execution. This is not unreasonable, as pigz is a library implementation, utilizing techniques and libraries that my program did not have access to. 

5. Additionally, pigz is written in C and is therefore compiled, so there will always be a speed barrier in that regard. I am certain that pigz also makes better use of parallelization, as its thread management protocols are probably more sound. 




As commanded by the spec, I then measured the number of system calls made by each executable. 

Pigzj: strace -fc java Pigzj <$input > output.txt


% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 98.36   10.919830        1198      9111       888 futex
  0.39    0.043366          44       974           write
  0.33    0.036875          14      2598           mprotect
  0.30    0.033270           7      4352           getrusage
  0.24    0.027161          22      1211           read
  0.13    0.014756          21       679           gettid
  0.06    0.007198          26       268        55 openat
  0.05    0.006023           4      1256           mmap
  0.05    0.005043          22       221           close
  0.03    0.002903          13       213           fstat
  0.01    0.000757           6       126           sysinfo
  0.01    0.000738          15        49           sched_yield
  0.01    0.000688           4       148           rt_sigprocmask
  0.00    0.000539          16        32           madvise
  0.00    0.000528          12        42           lstat
  0.00    0.000408           7        53        33 stat
  0.00    0.000239           3        70           sched_getaffinity
  0.00    0.000237           8        27           munmap
  0.00    0.000222           8        26           clone
  0.00    0.000209           4        51           nanosleep
  0.00    0.000176           3        49           lseek
  0.00    0.000155           6        25           prctl
  0.00    0.000108           2        37           getpid
  0.00    0.000090           3        27           set_robust_list
  0.00    0.000086           3        26           pread64
  0.00    0.000057          14         4           getdents64
  0.00    0.000046          11         4           sendto
  0.00    0.000036           1        25           rt_sigaction
  0.00    0.000023          11         2           ftruncate
  0.00    0.000020           2         8           socket
  0.00    0.000020           5         4           fcntl
  0.00    0.000017           1        12           getsockname
  0.00    0.000016           4         4           fchdir
  0.00    0.000016           4         4           geteuid
  0.00    0.000015           3         4         4 connect
  0.00    0.000014           3         4           brk
  0.00    0.000012           1         8           getsockopt
  0.00    0.000012           6         2           readlink
  0.00    0.000012           1         7           prlimit64
  0.00    0.000011           2         4           recvfrom
  0.00    0.000010           2         4           poll
  0.00    0.000010           2         4           setsockopt
  0.00    0.000009           2         4         2 access
  0.00    0.000008           2         4           ioctl
  0.00    0.000006           6         1           getcwd
  0.00    0.000006           6         1         1 mkdir
  0.00    0.000005           5         1           rt_sigreturn
  0.00    0.000005           1         4         4 bind
  0.00    0.000005           2         2           clock_getres
  0.00    0.000004           2         2           uname
  0.00    0.000004           2         2         1 arch_prctl
  0.00    0.000004           4         1           set_tid_address
  0.00    0.000003           3         1           unlink
  0.00    0.000000           0         1           execve
  0.00    0.000000           0         1           getuid
  0.00    0.000000           0         2         2 statfs
------ ----------- ----------- --------- --------- ----------------
100.00   11.102011                 21802       990 total


The majority of system calls seem to be going through kernel, memory management and thread locking mechanisms such as futex, mprotect, and mmap.



Pigz: strace -fc java Pigz <$input > output.txt


% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 93.49    0.171777         459       374        63 futex
  1.08    0.001977           6       285           mmap
  1.02    0.001873           7       255           mprotect
  0.77    0.001414          10       140           read
  0.75    0.001379           8       171        70 openat
  0.49    0.000892           8       110           gettid
  0.29    0.000534           8        64        49 stat
  0.25    0.000461           4       115           rt_sigprocmask
  0.23    0.000430           3       109           close
  0.21    0.000384           3       102           fstat
  0.18    0.000324          18        18           pread64
  0.13    0.000231           5        42           lstat
  0.10    0.000185           3        50           lseek
  0.10    0.000182           8        22           munmap
  0.09    0.000173           4        39           sched_getaffinity
  0.09    0.000169           9        18           clone
  0.08    0.000146          13        11           write
  0.07    0.000131          26         5           madvise
  0.06    0.000112           3        29           getpid
  0.06    0.000111           6        17           prctl
  0.06    0.000102           3        26           rt_sigaction
  0.05    0.000095           5        19           set_robust_list
  0.04    0.000082           3        27           sysinfo
  0.03    0.000064          10         6           getrusage
  0.03    0.000059          14         4           sendto
  0.02    0.000042           3        12           getsockname
  0.02    0.000037           4         8           socket
  0.02    0.000037           4         8           prlimit64
  0.02    0.000028           3         8           getsockopt
  0.01    0.000022           5         4           poll
  0.01    0.000021          21         1           nanosleep
  0.01    0.000021           5         4           getdents64
  0.01    0.000020           5         4         4 connect
  0.01    0.000020           5         4           recvfrom
  0.01    0.000019           4         4           fcntl
  0.01    0.000017           4         4           setsockopt
  0.01    0.000016           8         2           ftruncate
  0.01    0.000015           3         4           ioctl
  0.01    0.000015          15         1           unlink
  0.01    0.000014           3         4           brk
  0.01    0.000014           3         4           geteuid
  0.01    0.000013           4         3           sched_yield
  0.01    0.000013           3         4           fchdir
  0.01    0.000012           3         4         4 bind
  0.01    0.000012           6         2           readlink
  0.01    0.000010           5         2           getcwd
  0.00    0.000009           2         4         2 access
  0.00    0.000008           4         2           clock_getres
  0.00    0.000005           5         1           rt_sigreturn
  0.00    0.000005           2         2           uname
  0.00    0.000004           4         1         1 mkdir
  0.00    0.000004           4         1           getuid
  0.00    0.000004           2         2         1 arch_prctl
  0.00    0.000004           4         1           set_tid_address
  0.00    0.000000           0         1           execve
  0.00    0.000000           0         2         2 statfs
------ ----------- ----------- --------- --------- ----------------
100.00    0.183748                  2166       196 total

As expected, the majority of system calls made through this program are related to kernel, thread, memory, and file management. Additionally, this executable makes far less system calls than my implementation, as expected. As a library function ,this executable will be significantly more efficient. 


gzip: strace -fc java gzip <$input > output.txt

% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 92.72    0.127091         335       379        69 futex
  1.28    0.001755           6       286           mmap
  0.90    0.001228           4       255           mprotect
  0.83    0.001134           6       171        70 openat
  0.79    0.001087           7       140           read
  0.46    0.000624           5       109           gettid
  0.45    0.000614           5       114           rt_sigprocmask
  0.35    0.000484           7        64        49 stat
  0.28    0.000388           9        42           lstat
  0.28    0.000379           3       109           close
  0.24    0.000334           3       102           fstat
  0.14    0.000187           3        50           lseek
  0.12    0.000161           5        27           sysinfo
  0.12    0.000159           6        25           munmap
  0.11    0.000146           8        18           pread64
  0.11    0.000145           3        39           sched_getaffinity
  0.08    0.000113           6        18           clone
  0.07    0.000091           4        19           set_robust_list
  0.07    0.000090           3        29           getpid
  0.06    0.000076           6        11           write
  0.05    0.000075          18         4           sendto
  0.04    0.000056           3        17           prctl
  0.04    0.000051           4        12           getsockname
  0.04    0.000050           8         6           getrusage
  0.03    0.000046           5         8           socket
  0.03    0.000045           1        26           rt_sigaction
  0.03    0.000041          10         4           getdents64
  0.03    0.000040          13         3           sched_yield
  0.02    0.000032           8         4         4 connect
  0.02    0.000031           3         8           getsockopt
  0.02    0.000029           7         4         2 access
  0.02    0.000023           5         4           poll
  0.02    0.000023          11         2           ftruncate
  0.02    0.000021           5         4           recvfrom
  0.02    0.000021          10         2           uname
  0.02    0.000021          10         2         2 statfs
  0.01    0.000019           4         4         4 bind
  0.01    0.000018           9         2           readlink
  0.01    0.000018           2         8           prlimit64
  0.01    0.000017           4         4           setsockopt
  0.01    0.000017           4         4           fchdir
  0.01    0.000016           4         4           ioctl
  0.01    0.000014           3         4           fcntl
  0.01    0.000014           3         4           geteuid
  0.01    0.000010           5         2           getcwd
  0.01    0.000008           4         2         1 arch_prctl
  0.00    0.000006           6         1           rt_sigreturn
  0.00    0.000006           6         1         1 mkdir
  0.00    0.000006           3         2           clock_getres
  0.00    0.000005           5         1           execve
  0.00    0.000004           1         4           brk
  0.00    0.000003           3         1           getuid
  0.00    0.000000           0         4           madvise
  0.00    0.000000           0         2           nanosleep
  0.00    0.000000           0         1           unlink
  0.00    0.000000           0         1           set_tid_address
------ ----------- ----------- --------- --------- ----------------
100.00    0.137072                  2173       202 total


Even in gzip, the vast majority of time is spent in futex, but there are far fewer system calls made in total, most likely as a byproduct of the program being single-threaded. 


Potential problems as the file size grows extremely large: As the file grows extremely large and the number of active processors is equal to the number of processors on the machine, it is likely that other applications on the machine will run slower, and there is notable delay, as all cores of the CPU are constantly running the given executable. As as result, the overhead of context switches will get notably large. 

