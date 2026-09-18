// The JS twin: a plain Array, sized to the next power of two, zero past
// the end.
function bytes_read(path) {
  const name = io_bytes(path);
  if (name.includes(0)) {
    return io_fail(process.platform === "darwin" ? 92 : 84);
  }
  let buf;
  try {
    buf = require("fs").readFileSync(name.length > 0 ? Buffer.from(name) : "");
  } catch (e) {
    return io_fail(-e.errno);
  }
  if (buf.length > 2147483647) {
    return io_fail(27);
  }
  let size = 1;
  while (size < buf.length) {
    size *= 2;
  }
  const out = Array(size).fill(0);
  for (let i = 0; i < buf.length; i += 1) {
    out[i] = buf[i];
  }
  return io_done(out);
}
