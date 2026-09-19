// A List of bytes to an open file, one byte a cell, the twin of Base's
// File.read_bytes: the pack gathers the cells on the loop's thread, the
// call writes them on a helper's.

static void bytes_write_call(IoWork* w) {
  ssize_t n = 0;
  for (u64 at = 0; n >= 0 && at < w->size; at += (u64)n) {
    n = write((int)w->hand, w->data + at, w->size - at);
  }
  io_sys_end(w, n);
}

static Term bytes_write_pack(Env e, IoWork* w) {
  Term r = w->code != 0 ? io_fail(e, w->code, NULL)
    : io_done(e, term_pak(CID_UNIT, 0));
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

Term bytes_write_run(Env e, Term* f, IoWork* w) {
  u64 cap = 64;
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->size = 0;
  w->data = io_mem(malloc(cap));
  Term xs = f[1];
  while (term_aux(xs) == CID_CON) {
    Term fb[2];
    spare_free(e, cls_fit(2), ctr_take(e, xs, 2, fb));
    if (w->size == cap) {
      cap *= 2;
      w->data = io_mem(realloc(w->data, cap));
    }
    w->data[w->size] = (char)fb[0];
    w->size += 1;
    xs = fb[1];
  }
  return io_work(w, bytes_write_call, bytes_write_pack);
}

static void __attribute__((constructor)) bytes_write_use(void) {
  io_eff(CID_BYTES_WRITE, bytes_write_run, 0);
}
