# Theming

A theme is the `appearance` section of the config, saved as its own file:

```json
{
  "name": "Ember Night",
  "appearance": { "mode": "dark", "accent": "ember", "opacity": 0.9, "shape": "cut", "chamfer": 1.25 }
}
```

- **Presets** ship in `src/themes/presets/`: Obsidian Argent (default), Vellum
  Brass, Ember Night, Verdigris Survey, Cobalt Ledger (auto light/dark),
  Square Quiet (no chamfers, no motion).
- **Your themes** live in `~/.config/ssh-shell/themes/`. Settings → Themes
  exports the current look there and imports any file in either place.
- Imports are validated option by option; invalid values are skipped and
  reported, never applied.

## What a theme can change

Ground (`mode`), accent (named or custom hex), plate opacity, shape and corner size,
motion scale, fonts and text scale, and the auto light/dark hours. Grounds
themselves are fixed and contrast-tested; this keeps every theme legible.

## Blur

SSH draws translucent plates but leaves blur to the compositor, so it costs SSH
nothing. All SSH layer surfaces use the `ssh-*` namespace.

Hyprland (classic config):

```
layerrule = blur, ^(ssh-.*)$
layerrule = ignorezero, ^(ssh-.*)$
```

With a Lua config, add the equivalent layer rule for the namespace pattern
`ssh-.*`. Niri: use a `layer-rule` matching `namespace="^ssh-"` with your
preferred background effect, if your niri version supports it.

## Extending the palette

Accents are defined in `src/themes/Palettes.js` as `[onDark, onLight]` pairs.
Add a pair, add its name to `ACCENTS` in `configuration/Schema.js`, and run
`scripts/test.sh` — the palette suite fails if the new accent does not reach
3:1 contrast on both grounds.