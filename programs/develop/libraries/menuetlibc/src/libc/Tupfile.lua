if tup.getconfig("NO_GCC") ~= "" then return end
FOLDERS = {
  "ansi/assert",
  "ansi/ctype",
  "ansi/errno",
  "ansi/locale",
  "ansi/math",
  "ansi/setjmp",
  "ansi/stdio",
  "ansi/stdlib",
  "ansi/string",
  "ansi/time",
  "ansif",
  "compat/bsd",
  "compat/io",
  "compat/math",
  "compat/mman",
  "compat/mntent",
  "compat/search",
  "compat/signal",
  "compat/stdio",
  "compat/stdlib",
  "compat/string",
  "compat/sys/resource",
  "compat/sys/stat",
  "compat/sys/vfs",
  "compat/termios",
  "compat/time",
  "compat/unistd",
  "compat/v1",
  "crt0",
  "dos/compat",
  "dos/dir",
  "dos/dos",
  "dos/dos_emu",
  "dos/errno",
  "dos/io",
  "dos/process",
  "dos/sys/timeb",
  "fsext",
  "menuetos",
  "net",
  "pc_hw/cpu",
  "pc_hw/endian",
  "pc_hw/farptr",
  "pc_hw/fpu",
  "pc_hw/hwint",
  "pc_hw/kb",
  "pc_hw/mem",
  "pc_hw/sound",
  "pc_hw/timer",
  "posix/dirent",
  "posix/fcntl",
  "posix/fnmatch",
  "posix/glob",
  "posix/grp",
-- "posix/regex", -- not compilable
  "posix/pwd",
  "posix/setjmp",
  "posix/signal",
  "posix/stdio",
  "posix/sys/stat",
  "posix/sys/times",
  "posix/sys/wait",
  "posix/unistd",
  "posix/utime",
  "posix/utsname",
  "termios",
}

CFLAGS="-Os -fno-stack-check -fno-stack-protector -mno-stack-arg-probe -fno-ident -fomit-frame-pointer -fno-asynchronous-unwind-tables -mpreferred-stack-boundary=2 -march=pentium-mmx -fgnu89-inline"
OBJS={}
for i,v in ipairs(FOLDERS) do
  tup.append_table(OBJS,
    tup.foreach_rule({v .. "/*.c", extra_inputs = {"../../config.h"}},
      'kos32-gcc -c -I../../include -D__DEV_CONFIG_H=\\"../../config.h\\" ' .. CFLAGS .. " -o %o %f",
      v .. "/%B.o")
  )
  tup.append_table(OBJS,
    tup.foreach_rule({v .. "/*.s", extra_inputs = {"../../config.h"}},
      'kos32-cpp -I../../include -D__DEV_CONFIG_H=\\"../../config.h\\" %f | kos32-as -o %o',
      v .. "/%B.o")
  )
end
tup.rule(OBJS, "kos32-ar rcs %o %f", {"../../lib/libc.a", "../../<libc>"})
