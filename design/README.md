# App icon

`AppIcon.svg` is the source of truth for the Carousel / Carrousel app icon — a
slow turntable of pebbles (the lineage of the original "Le Galet" single pebble),
with the one currently "on stage" lit amber and the rest cooling and receding
into the charcoal. Lit from the upper-left, in the app's candle-lit palette.

Regenerate the 1024 PNG that the asset catalog uses:

    rsvg-convert -w 1024 -h 1024 design/AppIcon.svg \
      -o LeGalet/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png
