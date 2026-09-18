# 05: A literal that is too big stops the checker, and the error does not say where

**What is wrong:** A large number written as a `Nat` (`9000n`), or a long list written out in full, overflows the checker. The error is one line with no file, no line and no def name:

```
Error: the machine stack overflowed (a deep recursion, or a literal too large to expand)
```

It also comes before any ordinary type error in the same file. In two sessions the agent lost several rounds hunting for the cause, and once blamed the wrong thing (a list, when it was a number).

**Where:** Bend's checker, commit e6676b0. `docs/bend.md` already lists the limit ("Literals have limits"); this ticket is about the missing location.

**Status:** ready-for-human (report upstream: ask for the file and line in this error)

## What I measured

18 Sep 2026, `bend file.bend`, bun 1.3.13, 8 MB stack. The exact limit moves with the code around the literal, so take these as rough.

| literal | result |
| --- | --- |
| `Nat.add(4096n, 1n)` | works |
| `Nat.add(9000n, 1n)` | the error above |
| a list of 2048 numbers | works |
| a list of 3000 numbers | checks, then the run dies: `bend: memory fault (machine stack overflow?)` |
| a list of 4096 numbers | the error above |

One session saw `4096n` fail inside `src/level.bend`, where more code surrounds it.

## What we do about it

Big counts are `U32.to_nat(n)`, and big tables are cut into defs of 1024 entries (`tools/gen_tables.nu`).
