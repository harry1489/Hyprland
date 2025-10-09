#!/usr/bin/env bash

DAY_WALLPAPER="$HOME/Pictures/wallpapers/day.jpg"
NIGHT_WALLPAPER="$HOME/Pictures/wallpapers/night.jpg"

HOUR=$(date +%H)

if [ "$HOUR" -ge 6 ] && [ "$HOUR" -lt 18 ]; then
    swaybg -i "$DAY_WALLPAPER" -m fill &
else
    swaybg -i "$NIGHT_WALLPAPER" -m fill &
fi
