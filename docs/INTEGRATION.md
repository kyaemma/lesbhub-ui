# Integration into Lesbian Hub

Do not replace `src/vendor/windui` until the checks below have passed on a
running Roblox client. This repository is the library only.

## Load a pinned build

The distributable file is `dist/main.lua`, produced by `npm run build`
(Aftman darklua 0.17.1, Node, and `build/build.sh`). After this branch is
pushed, pin the reviewed commit. Do not follow a branch name from the game.

```luau
local commit = "<40-character SHA from git rev-parse on the reviewed commit>"
local url = "https://raw.githubusercontent.com/kyaemma/lesbhub-ui/" .. commit .. "/dist/main.lua"
local createWindUI = loadstring(game:HttpGet(url))
local WindUI = createWindUI({ GuiParent = guiParent })
```

`loadstring(...)()` without a table uses the default parent. One call of the
loaded chunk returns the library. The chunk itself is the factory, so the call
above passes `GuiParent` into that factory.

## What the hub should pass

The current window already passes `CloseBehavior = "Hide"` and
`HideMinimizeButton = true`. Keep passing them. Horizontal paragraph actions
use `ButtonsLayout = "Horizontal"`. `ScrollToTheElement` accepts the element
handle and returns false when the destination is gone.

The coffee icon, English `AutoLocalize` override, pixel snapping, and the
window pointer recovery stay in the hub. They are not in this build.

## Suggested switch, after a live pass

1. Build this branch and record the SHA of the commit that contains `dist/main.lua`.
2. In a private test place, load that URL with the real `GuiParent`.
3. Compare against the embedded bundle: open, hide, destroy and recreate,
   theme change, notifications, dropdowns outside the menu, sliders, keybinds
   including mouse buttons, search scrolling, horizontal paragraph buttons,
   resize while resize is enabled and while it is disabled, and unload.
4. Only then point the hub's loader at the pinned URL, or vendor the built
   factory, and delete the embedded copy in a separate change.

Until that pass, the embedded offline bundle remains the one the game runs.
