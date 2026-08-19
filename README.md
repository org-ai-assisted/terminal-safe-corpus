# terminal-safe-corpus

A small corpus of **display-only, safe-to-cat** terminal byte streams: a Unicode
risk-class gallery, a 24-bit-colour art piece, and one honest board that carries
every text-*display* attack class at once. Each file is shipped as **raw bytes on
purpose** -- it is meant to be run in a real terminal, not just read.

This is the safe sibling of
[`terminal-poc-corpus`](https://github.com/secure-terminal/terminal-poc-corpus),
which holds the genuinely dangerous payloads **hex-encoded at rest**. The split is
the point:

| repo | contents | at rest | you should |
|---|---|---|---|
| `terminal-poc-corpus` | clipboard / reflection / answerback / decoder-crash / RCE classes | **hex-encoded** | never `cat` -- run in a sandbox VM via the harness |
| `terminal-safe-corpus` (this) | display-only classes, colour, Unicode gallery | **raw bytes** | `cat` it anywhere -- that is what it is for |

> **Read [SAFETY.md](SAFETY.md).** It states exactly why raw bytes are safe here
> (display-only, no reach-outside, ground state at every newline) and how to inspect
> a file before rendering it if you would rather not trust it blindly.

## Layout

```
SAFETY.md   the safety contract (why these are safe to cat)
demos/
    unicode-gallery-safe-to-cat.txt                    Unicode risk-class gallery
    art-safe-to-cat.txt                                24-bit-colour terminal art
    terminal-attack-demo-WARNING-display-only-safe.txt display-attack showcase board
```

## The files

### `demos/unicode-gallery-safe-to-cat.txt`

A display-only gallery of the Unicode character space. `cat` it and it prints a
code-chart of every renderable block, then a labeled specimen of each risk class --
homoglyphs, bidi controls, zero-width and invisible bytes, non-ASCII spaces,
combining marks, raw C0/C1 control bytes -- with honest foreign text as the
non-attack contrast. Safe to cat in any terminal: every raw control byte is
terminated on its own line, the only side effect is one `BEL` beep, and nothing
persists (no `reset` needed).

### `demos/art-safe-to-cat.txt`

A 24-bit-colour scene drawn from SGR truecolour and the upper-half-block glyph
(which doubles the vertical resolution for smooth gradients). It emits only colour,
the half-block glyph and newlines, and ends every line with a reset -- no cursor
moves, no screen clear, no title change. The colour counterpart to the gallery: a
safe terminal is not a plain one.

### `demos/terminal-attack-demo-WARNING-display-only-safe.txt`

One safe, honest, self-labeling board that carries every terminal text-*display*
attack class at once: a hijacked window title, a DEC line-drawing frame, a homoglyph
domain, a bidi override, zero-width and invisible bytes, combining marks, fullwidth
look-alikes, a control-byte repaint, an SGR-hidden string, an OSC 8 link whose text
is not its target, and a `?1049h` alternate-screen switch -- with honest Greek text
as the non-attack contrast. It sets the window title and switches to the alternate
screen (both undone by `reset`); it copies nothing, types nothing, runs nothing. Its
first bytes are a plaintext warning, and it runs on the alternate screen so your real
scrollback is preserved. The genuinely dangerous classes (clipboard writes, input
reflection, notification and RCE) are **not** here -- they stay encoded in the
[poc corpus](https://github.com/secure-terminal/terminal-poc-corpus).

## Read one safely first

Feed any file to a tool that shows the bytes before your terminal renders them:
`unicode-show` / `stcat`, the
[analyze x-ray](https://output-lies.github.io/analyze/), or
[secure-terminal](https://secure-terminal.github.io), which neutralizes every class
in one frame.

## Regenerate

Every file is deterministic generator output -- the single source of truth, so the
committed bytes cannot drift from a hand edit. The generators live in the
derivative-maker `dist-ai` package; the showcase board is the `tui-showcase` PoC
from the poc corpus, decoded from its read-safe hex.

    # Unicode gallery (from a dist-ai checkout)
    python3 usr/share/secure-terminal-shots/unicode-gallery.py \
        > demos/unicode-gallery-safe-to-cat.txt

    # Truecolour art (from a dist-ai checkout)
    python3 usr/share/secure-terminal-shots/truecolor-art.py \
        > demos/art-safe-to-cat.txt

    # Showcase board (from a terminal-poc-corpus checkout: decode the read-safe hex)
    python3 - <<'EOF'
    import binascii
    hx = open('poc/tui-showcase/payload.hex').read()
    b = ''.join(''.join(l.split('#', 1)[0].split()) for l in hx.splitlines())
    open('terminal-attack-demo-WARNING-display-only-safe.txt', 'wb').write(
        binascii.unhexlify(b))
    EOF
