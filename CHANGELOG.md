# Changelog

## 1.0.0

First release. A port of
[docsify-charty](https://github.com/markbattistella/docsify-charty) 4.0, sharing
its stylesheet and producing byte-identical markup from the same chart
definition.

- Every chart type from the original: pie, donut, section, ring, radar, area,
  line, plot, bubble, bar, column, stacked bar, stacked column, and rating.
- Palettes generated in OKLCH so series colours are evenly spaced to the eye.
- Colour-scheme aware through CSS `light-dark()`, with no JavaScript served.
- Series highlighting from the legend done with `:has()`, reachable by keyboard.
- `role="img"`, `aria-labelledby`, and `role="meter"` on rating bars.
- Container-query layout, `prefers-reduced-motion`, and print styles.
- Blocks that can't be drawn are left in the page as code blocks; `debug: true`
  reports why during the build.
- Value labels are revealed on hover, or when a legend entry takes keyboard
  focus, rather than being drawn permanently.
- Charts with a value axis round it up to a readable ceiling and step it in even
  intervals, so an axis topping out at 217 runs to 250 in fifties.
- Bars are spaced by group, and a chart with one value per series gives each
  series its own slot along the axis.
