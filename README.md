# starship-palette

A [Starship](https://starship.rs) prompt for bash (built on WSL) with a palette
that changes daily. `starship_colors.sh` picks a hue and intensity seeded from
today's date, derives four backgrounds and two foregrounds from them, and renders
`starship.toml.tmpl` into `~/.config/starship.toml` with `envsubst`. All shells
opened on the same day share a palette.

## Install

```bash
git clone git@github.com:elephantgerald/starship-palette.git ~/starship-palette
~/starship-palette/install.sh   # symlinks the script and template into ~/.config
```

Then add `bashrc.snippet` to `~/.bashrc`. Requires `starship`, `envsubst`
(gettext) and `awk`, plus a Nerd Font for the powerline glyphs.

## Overrides

Set these before the script is sourced:

| Variable | Range | Default |
|---|---|---|
| `STARSHIP_HUE` | 0–359 | random (date-seeded) |
| `STARSHIP_INTENSITY` | 15–70 | random (date-seeded) |
| `STARSHIP_MIN_CONTRAST` | WCAG ratio | 4.5 (AA) |

To try a palette in the current shell:
`STARSHIP_HUE=271 STARSHIP_INTENSITY=57 source ~/.config/starship_colors.sh`

## Palette

| Token | Used for | Derivation |
|---|---|---|
| `BG_1`…`BG_4` | segment backgrounds | pure hue scaled by S×8/5, 7/5, 1, 3/5 |
| `FG_1` | most text | pure hue mixed toward white |
| `FG_2` | the time segment | muted; the `% 256` rollover at S>51 makes deliberate "glitch" colors |

**Contrast guard:** after the colors are derived, each foreground is mixed
toward white in 5% steps until it reaches `STARSHIP_MIN_CONTRAST` against its
background (FG_1 against BG_1, the brightest; FG_2 against BG_3). Hues and
glitches stay as generated; only colors that would be hard to read get lifted.
Without the guard, about 80% of hue/intensity combinations gave the time
segment less than 4.5:1, and blue hues pushed FG_1 down to about 2.5:1.
