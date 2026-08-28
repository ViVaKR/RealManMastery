# lldb

```bash

# file and line
(lldb) breakpoint set --file foo.c --line 12
(lldb) breakpoint set -f foo.c -l 12

# function name
(lldb) breakpoint set --name foo
(lldb) breakpoint set -n foo

# 중단점 확인
(lldb) breakpoint list
```