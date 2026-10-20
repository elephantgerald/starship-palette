#!/usr/bin/env bash
# ~/.config/starship_colors.sh
# Source in .bashrc to generate a randomized starship theme each session.
#
# Override before sourcing:
#   STARSHIP_HUE=240       # 0-359 (default: random)
#   STARSHIP_INTENSITY=40  # 15-70 (default: random; 40 ≈ original red palette)
#   STARSHIP_MIN_CONTRAST=4.5  # WCAG contrast floor for text (default: 4.5 = AA)
#
# Palette math (H = hue, S = intensity):
#   BG_4..BG_1 : pure hue scaled by S×[3/5, 1, 7/5, 8/5], floor at intensity/5
#   FG_2       : lerp(S/3, 115+2S, pure/255) — sedate, saturated
#   FG_1       : lerp(pure_hue, white, (S×8/5)/255) — loud, bright
#
# Rollover (% 256) on FG_2 dominant at S>51 produces glitch colors — intentional.
# Contrast guard: each FG is then mixed toward white in 5% steps until it meets
# STARSHIP_MIN_CONTRAST against its background, so glitch hues stay but text stays readable.

# Seed from today's date so all sessions on the same day share a palette.
# Open sessions keep their exported values; override with STARSHIP_HUE / STARSHIP_INTENSITY.
RANDOM=$(date +%Y%m%d)
H=${STARSHIP_HUE:-$(( RANDOM % 360 ))}
S=${STARSHIP_INTENSITY:-$(( RANDOM % 56 + 15 ))}

# Compute pure hue RGB into globals _HR _HG _HB (max channel=255, min=0)
_pure_hue() {
    local sector=$(( H / 60 ))
    local frac=$(( H % 60 ))
    local rising=$(( frac * 255 / 60 ))
    local falling=$(( (59 - frac) * 255 / 60 ))
    case $sector in
        0) _HR=255;      _HG=$rising;  _HB=0        ;;
        1) _HR=$falling; _HG=255;      _HB=0        ;;
        2) _HR=0;        _HG=255;      _HB=$rising  ;;
        3) _HR=0;        _HG=$falling; _HB=255      ;;
        4) _HR=$rising;  _HG=0;        _HB=255      ;;
        5) _HR=255;      _HG=0;        _HB=$falling ;;
    esac
}

# Background: pure hue scaled by intensity, floor = intensity/5
_bg() {
    local intensity=$1
    local min=$(( intensity / 5 ))
    local r=$(( _HR * intensity / 255 ))
    local g=$(( _HG * intensity / 255 ))
    local b=$(( _HB * intensity / 255 ))
    [ $r -lt $min ] && r=$min
    [ $g -lt $min ] && g=$min
    [ $b -lt $min ] && b=$min
    printf '%02X%02X%02X' $r $g $b
}

# FG_2 channel: lerp between non-dominant level and dominant level by pure hue value
# dom = (S*5)%256, non = S/3   (rollover on dom at S≈51 is a feature)
_fg2() {
    local dom=$(( (S * 5) % 256 ))
    local non=$(( S / 3 ))
    local r=$(( (_HR * dom + (255 - _HR) * non) / 255 ))
    local g=$(( (_HG * dom + (255 - _HG) * non) / 255 ))
    local b=$(( (_HB * dom + (255 - _HB) * non) / 255 ))
    printf '%02X%02X%02X' $r $g $b
}

# FG_1 channel: white-mix toward pure hue — lerp(white, pure_hue, (255-boost)/255)
# boost = (S*8/5)%256; no rollover in range [15,70]
_fg1() {
    local boost=$(( S * 8 / 5 ))
    local inv=$(( 255 - boost ))
    local r=$(( (_HR * inv + 255 * boost) / 255 ))
    local g=$(( (_HG * inv + 255 * boost) / 255 ))
    local b=$(( (_HB * inv + 255 * boost) / 255 ))
    printf '%02X%02X%02X' $r $g $b
}

# Lighten FG (hex, no #) toward white until WCAG contrast vs BG >= MIN; prints hex
_ensure_contrast() {
    awk -v fg="$1" -v bg="$2" -v min="${STARSHIP_MIN_CONTRAST:-4.5}" '
        function ch(v) { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ^ 2.4 }
        function lum(r, g, b) { return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b) }
        function hx(s) { return index("0123456789ABCDEF", substr(s, 1, 1)) * 16 - 16 + index("0123456789ABCDEF", substr(s, 2, 1)) - 1 }
        BEGIN {
            fr = hx(substr(fg, 1, 2)); fgg = hx(substr(fg, 3, 2)); fb = hx(substr(fg, 5, 2))
            lb = lum(hx(substr(bg, 1, 2)), hx(substr(bg, 3, 2)), hx(substr(bg, 5, 2)))
            for (t = 0; t <= 1.0001; t += 0.05) {
                r = int(fr + (255 - fr) * t); g = int(fgg + (255 - fgg) * t); b = int(fb + (255 - fb) * t)
                lf = lum(r, g, b)
                hi = lf > lb ? lf : lb; lo = lf > lb ? lb : lf
                if ((hi + 0.05) / (lo + 0.05) >= min) break
            }
            printf "%02X%02X%02X", r, g, b
        }'
}

_pure_hue

export STARSHIP_HUE=$H
export STARSHIP_INTENSITY=$S
_BG1=$(_bg $(( S * 8 / 5 )))
_BG3=$(_bg $S)
# FG_1 sits on every BG; BG_1 is the brightest, so it is the worst case
export STARSHIP_FG_1="#$(_ensure_contrast "$(_fg1)" "$_BG1")"
# FG_2 is only used on BG_3 (time)
export STARSHIP_FG_2="#$(_ensure_contrast "$(_fg2)" "$_BG3")"
export STARSHIP_BG_1="#$_BG1"
export STARSHIP_BG_2="#$(_bg $(( S * 7 / 5 )))"
export STARSHIP_BG_3="#$_BG3"
export STARSHIP_BG_4="#$(_bg $(( S * 3 / 5 )))"

unset _BG1 _BG3

envsubst '${STARSHIP_FG_1}${STARSHIP_FG_2}${STARSHIP_BG_1}${STARSHIP_BG_2}${STARSHIP_BG_3}${STARSHIP_BG_4}' \
    < ~/.config/starship.toml.tmpl > ~/.config/starship.toml
