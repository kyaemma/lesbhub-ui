# Lesbian Hub changes

Upstream is [Footagesus/WindUI](https://github.com/Footagesus/WindUI) 1.6.66, MIT.
This fork keeps that license, the original author credit, and the Icons submodule.
The hub-specific UI behavior below was recovered from the offline modules already
used by Lesbian Hub and rewritten onto the readable sources. The compact
recovered sources were not copied over this tree.

No Lesbian Hub gameplay, credentials, endpoints, or product callbacks are in
this repository. Icon names such as `webhook` belong to the upstream icon set.

## Entry

`src/Init.lua` returns a factory.

```luau
local WindUI = loadstring(game:HttpGet(URL))()
local parented = loadstring(game:HttpGet(URL))({ GuiParent = parent })
```

`GuiParent` is optional. Without it, the previous `gethui` / `CoreGui` /
`PlayerGui` choice remains. `WindUI:SetParent` still moves the four screen guis
after creation.

## Behavior brought over

| Area | Change |
| --- | --- |
| Signals | `CompactSignals` runs when the tracked list hits a multiple of 64, and at the call sites that drop a listener. `DisconnectAll` walks backward, ignores a disconnect error, and clears the registries. |
| Input | One shared `InputBegan` dispatcher serves the window toggle, open dropdowns, and keybind activation. Drag, resize-end, and keybind capture use the tracked signal list. |
| Registries | Theme objects, fonts, and translation targets are weak-keyed. A theme record does not store the instance again, so the weak key can be collected. |
| Drag and resize | Pointer movement writes `Position` and `Size` directly. A resize claims `CurrentInput` only when `CanResize` is true, and it releases that token only if it still owns it. |
| Window | `CloseBehavior = "Hide"` or `"Destroy"` skips the confirmation dialog. With no `CloseBehavior`, the upstream dialog stays. `HideMinimizeButton` omits the minimize button. Destroy is idempotent, cancels pending tab focus, and disconnects the root pointer listeners. |
| Navigation | `ScrollToTheElement` accepts an index or the element handle, opens parent sections, accounts for UIScale and the current canvas, and cancels a superseded scroll. Selecting a tab opens its sidebar section. |
| Elements | Destruction removes by identity and can run twice. The original `Destroy`, when the element already had one, is preserved. |
| Paragraph | `ButtonsLayout = "Horizontal"` shares one row. Each button has a fixed width and truncates its label. Vertical remains the default. |
| Notifications | Each notification can be destroyed without waiting for the close tween. `DestroyAll` runs from `DisconnectAll`. |
| Keybind | `MouseButton1`, `MouseButton2`, and `MouseButton3` are the stored names. `MouseLeft`, `MouseLeftButton`, `MouseRight`, `MouseRightButton`, and `MouseMiddle` still resolve to those names. |

## Left on the upstream side

Acrylic, the key system, Code, ProgressBar, Group, HStack, VStack, Image,
Viewport, the config manager, and the floating open button stay available.
The hub's embedded bundle omits them. This fork does not.

The hub still owns its theme, the extra Lucide icon, `AutoLocalize = false`,
whole-pixel window snapping, and its pointer-recovery guard. Those are product
choices, not library code. The resize token fix above removes the case that
guard was covering when resizing is disabled. Keep the guard until a live
Roblox pass confirms it.

The 64-step signal scan is the scan in the current hub bundle. A later
geometric scan exists only in an obfuscation experiment and is not part of
this library.
