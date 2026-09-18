// The JS twin: the cells' bytes written whole.
function bytes_write(file, xs) {
  const bytes = [];
  for (let at = xs; at.$ === "Con"; at = at.tail) {
    bytes.push(at.head & 255);
  }
  const b = Uint8Array.from(bytes);
  let at = 0;
  try {
    while (at < b.length) {
      at += require("fs").writeSync(file, b, at, b.length - at, null);
    }
    return io_tup(file, io_done({ $: "Unit" }));
  } catch (e) {
    return io_tup(file, io_fail(Math.abs(e.errno ?? 5)));
  }
}
