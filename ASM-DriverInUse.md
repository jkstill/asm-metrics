
## AFD is in use


$ asmcmd afd_state
ASMCMD-9526: The AFD state is 'LOADED' and filtering is 'ENABLED' on host 'ora192rac02.jks.com'

## AFD is NOT in use

```text
[grid@ora12102b ~]$ asmcmd afd_state
ASMCMD-9526: The AFD state is 'NOT INSTALLED' and filtering is 'DEFAULT' on host 'ora12102b.jks.com'
```

or

```text
$ asmcmd afd_state
ASMCMD-9530: The AFD state is 'NOT SUPPORTED'
```

## ASMLib not used

It is possible to just use udev

AFD is not installed

```text
[grid@ora12102b ~]$ asmcmd afd_state
ASMCMD-9526: The AFD state is 'NOT INSTALLED' and filtering is 'DEFAULT' on host 'ora12102b.jks.com'
```

oracleasm does not know about disks - there is no output

```text
[grid@ora12102b ~]$
[grid@ora12102b ~]$ oracleasm listdisks
```

Just use asm lsdsk

```text
$ asmcmd lsdsk  --suppressheader
/dev/asm01
```






