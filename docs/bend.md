# Bend constraints

What the checker refuses or chokes on, learned while writing the game. The guide (`bend guide`) says none of it.

## Code

- **Helpers before callers.** A def may call only defs above it.
- **No mutual recursion, no forward declaration.** Base's trick (a `law` declared, called, then filled by a `def`) is Base-only: user code gets "an unfilled law is a dead claim". Two shapes stay legal: a self-call whose first changing argument is a pattern sub-part, and post-processing (`helper(recursive_call(..))`).
- **A decision inside a loop is a parameter.** The body cannot `match` a computed Bool and then recurse (that needs a helper, which is mutual recursion), so the caller computes the Bool for the next step and passes it first: `go(fuel, done: Bool, ..)` matched as `match fuel done`. A loop over a record does the same by carrying the flag in the record (`Xy{done, ..}`) and matching it in the pattern.
- **Scrutinees follow binder order.** Destructuring lets and matches must take parameters in declaration order, and a let may not precede a match on a parameter, so put the flags matched on first and the records opened after.
- **`[]` is a pattern only in a case's first position:** `case 1n+m []:` does not parse; write `Nil{}` there.
- **A call result is not a pattern.** `(a, b) = f(x)` and `match f(x)` are refused: pass the result to a def that destructures its parameter. A let-bound variable is refused the same way.
- **Templates take their function first,** with an affine parameter (`x: U32`, not `+x`).
- **Reuse needs `+` everywhere:** on parameters, on pattern fields (`Player{+x, ..}`, `case 1n++p`, `(+a, b) = p`), and in laws (`for +level`).
- **Linear arrays cannot be shared across nested calls.** A quadtree from an `Array` is an explicit stack (`Show.fold`); a copyable indexed structure is a `Vec` tree (`src/vec.bend`).
- **Literals have limits:** a Nat literal of a few thousand (`4096n` already) and a list literal past about four thousand entries overflow the checker's stack. Big tables are 1024-entry chunks; big counts are `U32.to_nat(n)`.
- **`Bool.pick` evaluates both branches.** It is a function, and calls are strict, so a pick between a costly value and a cheap one pays for the costly one every time; a branch that builds something is a `match`.
- **No def named `exit`.** The native runtime has one of its own, and a build that gives the def a function of its own fails with "two names mangle to FID_EXIT"; whether it does depends on what the compiler inlines, so the name can pass for a while.
- **Recursion depth on the JS lane** is about 20000 on bun and 5000 on node; native has no stack. Tests run the JS lane on bun.

## Proofs

- **A universal U32 law does not compute.** Every word operation on a symbolic word is stuck in the checker, and Base has only `Word.add_comm`; state arithmetic facts as closed sample laws unless you are writing the word library.
- **Normalization duplicates.** A def that uses its argument twice, nested n deep (`sar(sar(sar(x)))`), makes the checker's term 2^n large; write it linear.
- **Hypotheses are parameters.** A lemma takes the fact it needs (`e: {True{} == f(x) : Bool}`) and returns the fact it proves; the caller passes `{==}` or an earlier lemma. Rewriting a hypothesis in place is not the tool.
- **Orient equations value-first.** `%e : P` with `e : {a == b}` marks `b` in the goal with `_` and puts `a` there, so to replace a computed term by its answer the equation reads `{answer == computed}`.
- **Refute through a motive:** `%e : BD(_, Unit, goal)` then `Unit{}`, where `BD` picks `goal` for the impossible side (proof_numerics' pattern).
- **Match what the code opens.** A proof about `f(p)` matches `p` into its constructor first, or `f` stays stuck; a lemma is universally quantified over any flag the code computes and instantiated with that term at the call, so no equation is needed for flags the code already takes as parameters.
- **Wildcards block reduction in proofs:** a lemma's `case _ Try{True{}, p}` leaves the code's `slide.go(fuel, ..)` stuck on `fuel`; the lemma splits the fuel even where the code need not.
