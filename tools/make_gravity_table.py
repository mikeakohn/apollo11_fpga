#!/usr/bin/env python3

# Acceleration of gravity is 1.62 m/s^2
# Actual Lunar Lander is 7m tall
# Simulated Lunar Lander is 8 pixels.
# 7 / 8 = 0.875 meters per pixel.

# Create a table of 200ms increments.

# v = a * t

def float_to_fixed(f):
  # Use 11.4 fixed point.

  minus = False

  if f < 0:
    f = -f
    minus = True

  i = int(f)
  f = f - float(i)

  #print(str(i) + " "  + str(f) + " " + str(int(16 * f)))
  i = i << 4
  i |= int(16 * f)

  if minus: i = ~i

  return i & 0x7fff

# --------------------- fold here -----------------------


velocities = [ ]

for i in range(0, 64):
  t = i * 0.200
  v = t * 1.62

  # Divide by 5 since this will run at 5 frames a second. This should
  # give velocity in pixels per 0.200s.
  v = v / 5

  # Distance is number of pixels moved at this velocity.
  d = 0.875 * v

  velocities.append(d)

table = [ ]

#print(velocities)

for i in range(len(velocities) - 1, 0, -1):
  f = float_to_fixed(-velocities[i])
  table.append(f)

for v in velocities:
  f = float_to_fixed(v)
  table.append(f)

count = 0

for i in table:
  if (count % 8) == 0: print("\n  .dc16", end='')

  print(" 0x%04x" % (i), end='')
  count += 1

print()

