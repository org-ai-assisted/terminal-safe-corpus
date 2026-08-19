# SAFETY

This repository is the **safe, cat-able** sibling of
[`terminal-poc-corpus`](https://github.com/secure-terminal/terminal-poc-corpus).
Where that corpus stores genuinely dangerous payloads **hex-encoded at rest** so
that reading the repo never fires them, everything here is the opposite by design:
the files are shipped as **raw bytes** precisely because each one is provably safe
to feed to a real terminal.

## Why raw bytes are safe here

A terminal attack IS a stream of bytes that does something when a terminal renders
it. The poc corpus never ships those bytes raw, because `cat`, `grep`, or a GitHub
file view would feed the attack to your terminal. This corpus carries a different,
deliberately narrow class:

- **Display-only.** The only state a file changes is the display -- colour, the
  window title, the alternate screen -- and every such change is undone by `reset`.
- **No reach-outside.** Nothing here writes your clipboard, types at your prompt,
  reflects input, queries the terminal for a report, or runs a command. The
  clipboard / reflection / answerback / RCE classes stay in the poc corpus, encoded.
- **Ground state at every newline.** Each raw control byte is followed by its own
  terminator on the same line, so the terminal returns to ground state at every
  `\n`: no unterminated control string, nothing that persists past the file.

A file that meets this contract is safe to `cat` in **any** terminal. That is the
whole point: a safe terminal is not a plain one, and these files let you see the
difference for yourself.

## The one board that changes display state

`demos/terminal-attack-demo-WARNING-display-only-safe.txt` sets the window title
and switches to the alternate screen (both undone by `reset`). It carries every
text-*display* attack class at once as an honest, self-labeling board -- its first
bytes are a plaintext warning, and it runs on the alternate screen so your real
scrollback is preserved. It changes only the display; it still copies nothing, types
nothing, and runs nothing.

## Read it safely first, if you like

You never have to trust this file blindly. Feed any of them to a tool that shows you
what the bytes are before your terminal renders them:

- [secure-terminal](https://secure-terminal.github.io) -- tints each character by
  risk and neutralizes every class in one frame.
- `unicode-show` / `stcat` -- annotate each control byte and confusable glyph.
- the [analyze x-ray](https://output-lies.github.io/analyze/) -- paste and label.

## In one line

Raw on purpose: display-only, no reach-outside, ground state at every newline --
safe to cat in any terminal. The dangerous classes live encoded in the poc corpus.
