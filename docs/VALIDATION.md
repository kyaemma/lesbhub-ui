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

## Not executed

No Roblox Studio or client session. Themes, tweens, dropdown layout,
notification motion, resize handles, and destroy/recreate of real instances
are unchecked. The hub's own Python UI tests still target the embedded
bundle, not this fork.
