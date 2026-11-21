# Validation

These checks run outside Roblox. A successful compile does not show that the
interface matches the hub in a live client. The live comparison is listed in
`docs/INTEGRATION.md` and has not been run.

## Executed

`python tests/test_parity.py` drives the official `luau` runtime.

- `tests/focus-fixture.luau` runs the real `Tab:ScrollToTheElement` from
  `src/components/window/Tab.lua`. It checks a missing index, a foreign
  handle, nested section opening, UIScale with an existing canvas offset,
  one outstanding scroll, a superseded scroll, a tab that is no longer
  selected, and cancellation after destroy.
- `tests/signal-fixture.luau` runs the real `Creator.CompactSignals`. It
  drops disconnected and missing records, preserves live order, and leaves a
  clean list unchanged.
- The migrated modules reject `Lifecycle`, `LesbianHub`, `GhostVector`,
  `FireServer`, and `webhook`. Upstream icon data is not part of that scan.
- `package.json` still declares MIT and credits Footagesus.
- `src/Icons` is present from the Footagesus/Icons submodule.

`luau-compile` 0.745 accepted the 15 migrated and example sources and
`dist/main.lua`. `darklua` 0.17.1, the version pinned in `aftman.toml`,
bundled `src/Init.lua` with `build/darklua.dev.config.json`. Running that
bundle with `luau` exits 0: the chunk defines its modules and returns the
factory. The factory was not called, because that needs Roblox `game`.
The built factory reads `GuiParent` from its argument.

## Roblox client

On place `100245581145289`, Potassium could not move the hardware pointer:
`mousemoveabs`, `mouse1click` and `mousemoverel` left the cursor in place.
An injected drag, after the open tween settled, changed both this fork and
the embedded bundle from 860×560 to 1000×660. That is the same resize math.
A hardware drag was not performed.

Opening set `Closed` one frame late, so a close during that delay could be
undone. `Window:Open` and `Window:Close` now share a generation counter with
the embedded bundle. After that change, five immediate open/close cycles,
a cancelled reopen, a later reopen, and a second destroy matched the
embedded bundle.

With the hub palette registered before `CreateWindow`, both libraries
applied text color 244,241,245, accepted 20 button callbacks, scrolled to
an element, toggled transparency, and detached on destroy. Naming
`LesbhubCustom` before `AddTheme` errors in both libraries.

Construction of a window plus 40 buttons, alternating order and ignoring
the first cold sample, was about 31–36 ms for the fork and 19–26 ms for
the embedded bundle. Heartbeat p95 stayed near 2 ms and p99 near 3 ms
during the interaction pass. These figures are one client, not a reason
to rewrite the library.
