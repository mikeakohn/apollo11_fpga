#!/usr/bin/env python3

import sys

def float_to_bin(f):
  minus = False

  if f < 0:
    minus = True
    f = -f

  b = int(0x4000 * f)

  if minus: b ^= 0x3fff; b |= 0x4000

  return b

def bin_to_float(b):
  minus = False

  if (b & 0x4000) == 0x4000:
    minus = True

  b = b & 0x3fff
  if minus: b ^= 0x3fff
  f = b / 0x4000

  if minus: f = -f

  return f

def show_bin(i):
  s = ""

  for n in range(0, 15):
    d = i & 1
    i = i >> 1

    if (n % 4) == 0 and n != 0: s = "_" + s

    if d == 0: s = "0" + s
    else:      s = "1" + s

  print(s)

# --------------------------- fold here -------------------------

if len(sys.argv) != 2:
  print("Usage: python3 add.py <num1>")
  sys.exit(0)

if "." in sys.argv[1]:
  a = float(sys.argv[1])

  if a >= 1.0: print("value is above 0"); sys.exit(1)

  h0 = float_to_bin(a)
else:
  h0 = int(sys.argv[1], 0)

  a = bin_to_float(h0)

print("%04x is %f" % (h0, a))

show_bin(h0)

print(" ------")

c = -a;
h3 = float_to_bin(c)

print("%04x is %f" % (h3, c))
show_bin(h3)

