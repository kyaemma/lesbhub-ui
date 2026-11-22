# Lesbian Hub theme assets

Images the hub downloads once and caches in its workspace (`assets/`). It fetches them from a pinned commit
of this repository, so every URL is immutable. File names carry a version because Roblox caches images by path:
change the name whenever the pixels change.

- `shape-*-v1.png`: redrawn copies of WindUI's 9-slice fill shapes. They use the same slice geometry as
  `src/modules/DynamicShape.lua`: Squircle, Circle, SquircleH, SquircleV, Squircle-TL-TR and Squircle-BL-BR.
  Pixels under transparency are white, so a light tint shows no grey fringe when Roblox scales the image down.
  Light themes swap them in through `Creator.SetShapeOverrides`.
- `teto-backdrop-v2.png`, `teto-chibi-v3.png`, `teto-chibi-waiting-v3.png`: art for the Teto preset.
  The mascot stickers come from the project's own chibi art, with a white outline and a pink shadow.

`generator.rs.txt` is the program that produced these files. It is a small Rust binary on resvg 0.49 that
includes `lesbhub-renderer/src/radar/raster.rs` from lesbhub-core for alpha snapping, trimming, resizing and
the sticker outline.
