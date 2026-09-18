# 03: Bend's README mentions shared arrays that do not exist

**What is wrong:** Bend's README says: "Sharing arrays with atomics across threads is experimental and needs `@unsafe`." Nothing in Bend commit e6676b0 does this. There is no such function in `base.bend`, nothing in the compiler, and no test.

**Status:** ready-for-human (a small documentation report upstream)

## Why it matters to us

An array in Bend has one owner. Two pieces of parallel work cannot both read our graphics array, and the compiler never lends an array the way it lends other values (`brw_of` in `comp.ts` leaves arrays out by name). Cutting an array in two copies both halves, and joining them copies again (`blk_half`, `blk_node`).

So today parallel work can only read textures if they are stored as trees, not in the array. If upstream ever ships shared read-only arrays, drawing in parallel gets much cheaper: the walk through the level would stay in order, and the pixels could be drawn by many workers reading the one array.

## What to do

Ask upstream whether the feature exists on some branch, or whether the README line should go.
