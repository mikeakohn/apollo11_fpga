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

if len(sys.argv) != 3:
  print("Usage: python3 add.py <num1> <num2>")
  sys.exit(0)

if "." in sys.argv[1] and \
   "." in sys.argv[2]:

  a = float(sys.argv[1])
  b = float(sys.argv[2])

  if a >= 1.0: print("value is above 0"); sys.exit(1)
  if b >= 1.0: print("value is above 0"); sys.exit(1)

  h0 = float_to_bin(a)
  h1 = float_to_bin(b)
else:
  h0 = int(sys.argv[1], 0)
  h1 = int(sys.argv[2], 0)

  a = bin_to_float(h0)
  b = bin_to_float(h1)

print("%04x is %f" % (h0, a))
print("%04x is %f" % (h1, b))

show_bin(h0)
show_bin(h1)

print(" ------")

c = a - b;
h3 = float_to_bin(c)

print(c)
print("%04x" % (h3))
show_bin(h3)

