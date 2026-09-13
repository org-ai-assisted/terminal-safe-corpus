#!/usr/bin/python3 -Bsu

## Copyright (C) 2026 - 2026 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file LICENSE for copying conditions.

## AI-Assisted

"""Decode a read-safe hex board to raw bytes on stdout.

Strips inline `#` comments + whitespace, then unhexlifies. Pure stdlib,
deterministic. Argv 1 is the .hex path. Used by the cross-repo drift gate."""

import binascii
import sys

src = open(sys.argv[1]).read()
hexed = ''.join(''.join(line.split('#', 1)[0].split()) for line in src.splitlines())
sys.stdout.buffer.write(binascii.unhexlify(hexed))
