#!/usr/bin/env python3

import sys

count = 0

fp = open(sys.argv[1], "rb")

while True:
  b = fp.read(2)
  if not b: break
  print("%02x%02x" % (b[1], b[0]))

  count += 1

  # This is to move data at 04000 to 06000.
  # If that memory range is needed, something else needs to be done.
  if count == 1024:
    for i in range(0, 1024):
      print("%02x%02x" % (0, 0))

fp.close()

