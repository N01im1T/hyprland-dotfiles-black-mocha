# Theming

`settings.toml` owns user-facing appearance, animation, command and wallpaper settings. `theme.toml` owns palette tokens. Black Mocha replaces Catppuccin's standard dark bases with `#000000`, `#010101`, and `#020202`.

Change the accent, background, text, font, radii, gaps, blur, shadows or animation speed in one place, then run:

```bash
dotctl apply
```

The generator writes files atomically and reloads only live components. Do not edit generated files if the change belongs in TOML or a template; the next apply will replace it.

The same options are available graphically through **Super+A** or `dotctl settings`. The Settings Center is a client of the validated `dotctl config export/save` API, so GUI edits and manual TOML edits share exactly the same source of truth.
