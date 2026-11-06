# Converts the APPLE 50 wozmon hex dump into one contiguous binary loaded at $0300.
# The dump puts its frame data at $E000, which is ROM (BASIC) on this board,
# so that segment is moved right after the code and the frame pointer table is patched.
# Usage: python3 apple50hex2bin.py software/apple50.hex software/APPLE50

import sys

segs = []
for line in open(sys.argv[1]):
    adrs, _, hexbytes = line.partition(':')
    data = bytes.fromhex(hexbytes)
    if not data:
        continue
    # A new segment starts only when an explicit address does not follow the previous bytes
    if adrs.strip() and (not segs or int(adrs, 16) != segs[-1][0] + len(segs[-1][1])):
        segs.append([int(adrs, 16), bytearray()])
    segs[-1][1].extend(data)

assert [s[0] for s in segs] == [0x0300, 0xE000], f"unexpected segments {[hex(s[0]) for s in segs]}"
code, frames = segs[0][1], segs[1][1]
new_base = 0x0300 + len(code)

# Frame pointer table is read by "LDA table,X" at $0310
assert code[0x10] == 0xBD, "expected LDA abs,X at $0310"
table = code[0x11] | code[0x12] << 8
i = table - 0x0300
while code[i] | code[i+1]:
    ptr = code[i] | code[i+1] << 8
    if 0xE000 <= ptr < 0xE000 + len(frames):
        ptr = ptr - 0xE000 + new_base
        code[i], code[i+1] = ptr & 0xFF, ptr >> 8
    i += 2

out = code + frames
assert 0x0300 + len(out) <= 0x2000, "does not fit in 8K RAM"
open(sys.argv[2], 'wb').write(out)
print(f"{sys.argv[2]}: $0300-${0x0300+len(out)-1:04X} ({len(out)} bytes), frames moved $E000 -> ${new_base:04X}")
