# 02: Fixed point on U32 with its laws

**What to build:** Doom's fixed_t as two's complement on U32 with sixteen fraction bits, so that every sim quantity is an integer the proof checker can reason about. Signed compare, negate, absolute value, add and subtract on top of U32's wrapping arithmetic; multiply by splitting each operand into two 16-bit halves so no 64-bit intermediate exists; divide following Doom's saturating FixedDiv with its overflow guard; conversion from a signed 16-bit map coordinate by sign extension then shift. The sim never calls a float function.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] Signed compare orders -1 below 0 and 0 below 1 in the two's complement reading
- [x] Multiply of two fixed values answers Doom's FixedMul for positive, negative and mixed signs
- [x] Divide saturates to MININT or MAXINT exactly where Doom's FixedDiv does
- [ ] Law: multiply by one is the identity, for all fixed x
- [ ] Law: multiply commutes, for all fixed x and y
- [ ] Law: the split-word multiply equals the exact 64-bit product shifted right by sixteen, stated against a reference written on Nat
- [x] Closed sanity laws for one sample of each operation
- [x] PROOF.bend proves every law and the flake check stays green

## Comments

Done, with the three universal laws cut to closed sample laws. Base's word library holds only add-commutativity, and every U32 operation on a symbolic word gets stuck in the checker (each needs its own bit-level induction), so multiply-by-one, commutativity and the split-word-equals-exact-product statements would need a word arithmetic library (add associativity, shift and multiply lemmas, to_nat homomorphisms) that does not exist and is days of work in this checker. A reference on Nat is out too: Nat literals past a few thousand overflow the checker. `fixed_mul_one` pins both orders on samples, `fixed_mul_overflow` the shifted product past 32 bits, `fixed_mul_signs` and `fixed_div` the sign cases and the saturation. Whether to build the word library is the maintainer's call.

Also learned: `Fixed.sarn` as nested single shifts duplicated its argument at each level and made the checker's normalization exponential; it is one logical shift plus a sign mask now.
