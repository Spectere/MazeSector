#!/usr/bin/env python3

import os
import sys

if len(sys.argv) != 2:
    print("usage: {} [boot sector binary]".format(sys.argv[0]))
    sys.exit(1)

filename = sys.argv[1]
if not os.path.exists(filename):
    print("File '{}' not found.".format(filename))
    sys.exit(1)

if os.path.getsize(filename) != 512:
    print("File '{}' must be exactly 512 bytes in length.".format(filename))
    sys.exit(1)

data = None
with open(filename, "rb") as file:
    data = file.read(512)

# Check file magic.
if not (data[510] == 0x55 and data[511] == 0xAA):
    print("File '{}' has an invalid magic.".format(filename))
    sys.exit(1)

# Count backwards and see how many bytes we have left!
pos = 509
while data[pos] == 0:
    pos -= 1

remaining = 510 - pos
print("{}: {} bytes used; {} bytes remaining".format(filename, pos, remaining))
