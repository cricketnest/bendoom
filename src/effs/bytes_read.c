// A whole file as one Array<U32>, one byte per slot: the call reads it
// on a helper thread, the pack lays the block on the loop's. Sized to
// the next power of two, zero past the end; over 2^31 bytes Fails.

#include <fcntl.h>
#include <sys/stat.h>

static void bytes_read_call(IoWork* w) {
  int fd = open(w->data, O_RDONLY);
  free(w->data);
  w->data = NULL;
  if (fd < 0) {
    w->code = (u32)errno;
    return;
  }
  struct stat st;
  if (fstat(fd, &st) < 0 || st.st_size > INT32_MAX) {
    w->code = st.st_size > INT32_MAX ? EFBIG : (u32)errno;
    close(fd);
    return;
  }
  w->size = (u64)st.st_size;
  w->data = io_mem(malloc(w->size + 1));
  u64 got = 0;
  while (got < w->size) {
    ssize_t n = read(fd, w->data + got, w->size - got);
    if (n < 0) {
      w->code = (u32)errno;
      break;
    }
    if (n == 0) {
      w->size = got;
      break;
    }
    got += (u64)n;
  }
  close(fd);
}

static Term bytes_read_pack(Env e, IoWork* w) {
  if (w->code != 0) {
    free(w->data);
    return io_fail(e, w->code, NULL);
  }
  Nat d = 0;
  while ((1ull << d) < w->size) {
    d += 1;
  }
  Term zero = 0;
  Term arr  = blk_new(e, false, d, 0, 1, &zero);
  if (err_seen(e.mem)) {
    free(w->data);
    return arr;
  }
  Loc l = term_loc(arr);
  for (u64 i = 0; i < w->size; i += 1) {
    blk_write(e.mem, false, l, (u32)i, ((uint8_t*)w->data)[i]);
  }
  free(w->data);
  return io_done(e, arr);
}

Term bytes_read_run(Env e, Term* f, IoWork* w) {
  w->data = io_cstr(e, f[0], &w->size);
  if (io_nul(w->data, w->size)) {
    w->code = EILSEQ;
    return bytes_read_pack(e, w);
  }
  w->code = 0;
  return io_work(w, bytes_read_call, bytes_read_pack);
}

static void __attribute__((constructor)) bytes_read_use(void) {
  io_eff(CID_BYTES_READ, bytes_read_run, 0);
}
