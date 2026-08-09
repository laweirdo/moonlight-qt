---
name: Bug report
about: Something in Bulan is broken
---

<!--
Bulan is an unofficial, Steam Deck-focused fork of Moonlight Qt, currently in
private alpha. It is not an official Moonlight release.

Please do NOT report Bulan's bugs to the Moonlight project. If you can reproduce
the same problem in upstream Moonlight, it belongs there instead:
https://github.com/moonlight-stream/moonlight-qt/issues
-->

**What happened**
What you saw, and what you expected instead.

**Where**
Which screen, and how you got to it — first run, host list, game library,
settings, launching a game, in-stream, coming back out.

**How to reproduce**
Steps, if you can find them. "Only once, after X" is still worth reporting.

**Setup**
- Bulan version: [About shows it, e.g. Alpha v0.0.1]
- Device: [Steam Deck LCD, Steam Deck OLED, Windows PC, Mac]
- How it was installed: [Flatpak, built from source]
- Game Mode or Desktop Mode, if on a Deck:
- Host PC and its streaming software: [e.g. Windows 11, Sunshine]

**Input**
Bulan is controller-first. If the problem involves navigation or focus, say what
you were using: the Deck's built-in controls, a paired controller, keyboard.

**Logs**
- Flatpak on a Deck: `flatpak run io.github.laweirdo.MoonlightFork 2>&1 | tee ~/bulan.log`
- Windows: `Moonlight-###.log` in `%TEMP%`
- macOS: `Moonlight-###.log` in `/tmp`

**Screenshots**
Helpful for anything visual — a wrong colour, a broken layout, motion that looks
wrong, focus landing somewhere unexpected.
