# Bug — A is dead after dismissing the pairing PIN panel

**Found** 28 July 2026, on a Steam Deck OLED ("Galileo"), Desktop Mode, by the
client, during the Deck review session. **Still open.** Two fix attempts failed.

This is **not** a regression of defect 1. Defect 1's fix is present and working,
and the related failure it shares a symptom with — check 1.2, the Client Settings
dropdown — was fixed in `be874bf8` and confirmed by hand. This is a third
mechanism behind the same symptom.

---

## Reproducing it

1. Host carousel, on a host that is **online but not yet paired**.
2. Press **A**. Pairing starts and the PIN panel appears — it displays a PIN to
   type *on the host PC*. It is not a text entry field in the app.
3. Press **B** to dismiss the panel.
4. Press **A** on any host.

**Expected:** A acts on the host.
**Actual:** A does nothing at all, permanently, until the app is restarted.
Every other button continues to work normally.

Confirmed reproducible across three builds, including two containing fix
attempts.

---

## Why this symptom is worth recognising

**Exactly one button dead, everything else fine.** That signature has now
appeared three times on this project from three different causes. It happens
because **A is the only button with no window-level shortcut standing behind
it** — X and START also reach the app through `Shortcut` elements in `main.qml`,
which fire regardless of what holds focus. A is handled only by the screen. So
any fault that stops the carousel being the thing listening takes out A alone
and leaves everything else looking healthy.

Do not read "only A is broken" as evidence of a binding or pairing problem. It
is the expected shape of a focus or key-routing fault on this screen.

---

## Leading hypothesis — unconfirmed

**The dismissed PIN panel still holds focus and swallows A.**

`HostPanel` handles `Keys.onReturnPressed` and `onEnterPressed` by calling
`accept()`. A sends Return (or Space, if the settings tab-chain mode is armed).
If a panel retains active focus after being hidden, then:

- **A** is consumed by the invisible panel — `accept()` on a non-editable panel
  just calls `close()`, which does nothing visible. The press is swallowed.
- **Every other button** is not handled by `HostPanel`, so it bubbles up to the
  carousel and works normally.

That accounts for the symptom exactly, including which buttons survive. It is
consistent with every observation, but it has **not been directly confirmed** —
see "the instrumentation failed" below.

---

## What has been ruled out

| Ruled out | How |
|---|---|
| **Defect 1 returning** (navigation mode stuck, A becomes Space) | The carousel now handles Return, Enter **and** Space. A stuck mode can no longer produce a dead A. |
| **The "Couldn't pair" message panel appearing and eating the press** | `pairingComplete()` never fires in the log — pairing starts and never reports back. No message panel is raised. |
| **A QML error breaking the handler** | No QML errors or warnings in the log beyond the known-harmless ones. |
| **The carousel losing focus entirely** | Other key handlers on the carousel demonstrably fire after the panel is dismissed, so the carousel is receiving keys. |

That last row is the important one, and it is what makes the hypothesis above the
leading one: the carousel **is** listening, so this is about A specifically being
consumed or transformed, not about the screen going deaf.

---

## Fix attempts that did not work

Both are committed in `be874bf8`, because both are correct independently and one
of them fixed check 1.2. Neither fixed this bug.

1. **Clearing the panel's own focus before handing it back.** A `FocusScope`
   gives active focus to whichever child last held it, so handing focus back to
   the parent could route it straight back into the panel that had just closed.
   Clearing first should prevent that. No effect on this bug.

2. **`enabled: visible` on `HostPanel`, plus a focus handback on every hide.**
   A disabled item cannot hold active focus, so a hidden panel should be
   incapable of keeping it. The second half covers `pairingComplete()`, which
   hides the PIN panel by setting `visible` directly and therefore never runs
   `close()` or its handback at all. No effect on this bug.

The fact that attempt 2 changed nothing is itself evidence, and is the main
reason the hypothesis above is not yet confirmed: if the panel really is holding
focus, disabling it should have released it. Either it is not the panel, or
`enabled: visible` is not doing what it is expected to do here.

---

## The instrumentation failed — read this before adding more

An attempt was made to log which item held focus on every A press, using
`console.log()` from QML.

**Not one line was emitted**, including at a moment when A demonstrably worked
(pairing started, which only happens through the A handler). So the handler ran
and the log stayed empty.

**QML `console.log()` does not reach the Deck log.** `qDebug()` from C++ does —
`Qt Debug: Current Moonlight version:` appears at startup — so the message
handler is not filtering everything, but QML debug output is not arriving.

Anyone instrumenting this next should **verify their logging appears at all**
before drawing conclusions from its absence. An empty log was briefly read here
as "the handler never fired", which is the opposite of what was true.

Suggested alternatives, untested:
- `console.warn()` or `console.error()` instead of `console.log()`.
- A `Q_INVOKABLE` on an existing C++ singleton that calls `qInfo()`, which is
  known to reach the log.

---

## Suggested next steps

1. **Get working logging first.** Nothing below is worth doing blind.
2. **Confirm or kill the hypothesis** by logging the window's active focus item
   at the moment A is pressed, after the panel has been dismissed.
3. If the panel is holding focus, the structural fix is probably to stop
   `HostPanel` claiming Return/Enter unconditionally — it should only accept
   them while it is genuinely on screen — rather than continuing to fight over
   who holds focus.
4. Consider whether **pairing still being in flight** matters. The log shows
   pairing starts and never completes when the panel is dismissed early, and the
   host stays unpaired. It is not obviously related to the dead button, but it
   is an untidy state that no session has looked at.

---

## Related, noticed in passing

`HostCarousel.qml` triggers repeated Qt warnings:

```
Parameter "event" is not declared. Injection of parameters into signal
handlers is deprecated.
```

Several key handlers use `event.accepted = true` without declaring `event`. It
works today and is only a warning, but when that injection is eventually removed
those statements will throw, and each one sits **after** the action it guards —
so the visible behaviour would survive while key propagation silently broke.
Worth fixing before it becomes a mystery. Not urgent, not related to this bug.
