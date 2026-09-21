# 03: Bend's README mentions shared arrays that do not exist

**What is wrong:** Bend's README says: "Sharing arrays with atomics across threads is experimental and needs `@unsafe`." Nothing in Bend commit e6676b0 does this. There is no such function in `base.bend`, nothing in the compiler, and no test.

**Status:** resolved (Bend 2.0.22 supplies `Array.fork`, `Array.join` and `Array.atomic.*` under `@unsafe`)

## Why it matters to us

An array in Bend has one owner. Two pieces of parallel work cannot both read our graphics array, and the compiler never lends an array the way it lends other values (`brw_of` in `comp.ts` leaves arrays out by name). Cutting an array in two copies both halves, and joining them copies again (`blk_half`, `blk_node`).

The feature now exists, so there is no documentation error to report. Bendoom does not use the unsafe array operations.
