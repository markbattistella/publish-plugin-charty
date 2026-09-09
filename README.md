<div align="center">

# Charty

**Charts and graphs for [Publish](https://github.com/JohnSundell/Publish)**

</div>

Charty turns fenced ` ```charty ` blocks in your Markdown into inline SVG charts
at build time. Pie, donut, section, ring, radar, area, line, scatter, bubble,
bar, column, stacked bar, stacked column, and rating.

No JavaScript is served. Charts are static SVG, they follow the reader's colour
scheme on their own, and highlighting a series from the legend is done in CSS.

This is a port of [docsify-charty](https://github.com/markbattistella/docsify-charty).
The two share a stylesheet and emit byte-identical markup from the same chart
definition, so a chart written once looks the same on either site.

## Installation

Add the package to your site's `Package.swift`:

```swift
.package(url: "https://github.com/markbattistella/publish-plugin-charty.git", from: "1.0.0")
```

...and to your target:

```swift
.product(name: "Charty", package: "publish-plugin-charty")
```

## Usage

Install the plugin in your publishing pipeline:

```swift
import Charty
import Publish

try MySite().publish(
	withTheme: .foundation,
	plugins: [.charty()]
)
```

Then link the stylesheet from your theme's `<head>`:

```swift
.head(
	.chartyStylesheet()
)
```

The plugin writes `charty.css` into your output folder. To inline it instead,
pass `stylesheetPath: nil` and use `Charty.stylesheet`.

### Configuration

```swift
.charty(
	theme: "#0984E3",
	colourScheme: .system,
	stylesheetPath: "charty.css",
	debug: false
)
```

| Parameter        | Default        | Description |
|------------------|----------------|-------------|
| `theme`          | `"#0984E3"`    | The hex colour series palettes are generated from. Charty converts it to OKLCH and steps across a clamped lightness range, so the colours are evenly spaced to the eye and never bottom out at black or top out at white |
| `colourScheme`   | `.system`      | `.light`, `.dark`, or `.system`. `.system` writes no `color-scheme` of its own and follows the surrounding page — forcing `light dark` would give a light-only site dark charts whenever the reader's OS was in dark mode |
| `stylesheetPath` | `"charty.css"` | Where to write the stylesheet in the output folder. `nil` skips it |
| `debug`          | `false`        | Report unusable charts during the build, and why |

## Writing a chart

````markdown
```charty
{
  "title":   "Visitors",
  "caption": "By year",
  "type":    "pie",
  "options": {
    "legend":  true,
    "labels":  true,
    "numbers": true
  },
  "data": [
    { "label": "2012", "value": 1024 },
    { "label": "2010", "value": 200 },
    { "label": "2011", "value": 560 }
  ]
}
```
````

A block that isn't valid JSON, names a type Charty doesn't know, or has no data
is left in the page as an ordinary code block rather than disappearing. Turn on
`debug` to find out why.

Value labels stay hidden until a series is hovered, or its legend entry is
focused from the keyboard. Charts with an axis round it up to a readable
ceiling — a series topping out at 217 is drawn against an axis running to 250
in steps of 50, rather than one divided into ten equal parts.

### Keys

| Key               | Type            | Description |
|-------------------|-----------------|-------------|
| `title`           | `String`        | Heading above the chart. Also names the chart for screen readers |
| `caption`         | `String`        | Sub-heading beneath the title |
| `type`            | `String`        | One of the types below |
| `points`          | `[String]`      | Axis names for `radar`. May also be given on the first data item |
| `options.theme`   | `String`        | A hex colour for this chart alone, overriding the site theme |
| `options.legend`  | `Bool`          | Show the legend. Default `true` |
| `options.labels`  | `Bool`          | Show axis and series labels. Default `true` |
| `options.numbers` | `Bool`          | Draw the value labels, revealed when a series is hovered or its legend entry is focused. Default `true` |
| `data[].label`    | `String`        | Series name, shown in the legend |
| `data[].value`    | `Double\|[Double]` | A single number, or an array for charts with multiple points per series |
| `data[].colour`   | `String`        | An explicit colour for this series, overriding the palette. `color` is accepted too |

### Types

| Type | Aliases | Notes |
|------|---------|-------|
| `pie` | | Values are shares of the total |
| `donut` | `doughnut` | |
| `section` | `sectional` | Values are fractions between 0 and 1 |
| `ring` | `rings` | One concentric ring per series; values are fractions or percentages |
| `radar` | | Values are percentages, and must match the number of `points` |
| `area` | | |
| `line` | | |
| `plot` | `scatter` | |
| `bubble` | | Point size scales with the value |
| `bar` | | Vertical. One value per series gives each series its own slot; several values group them |
| `column` | | The same, running horizontally |
| `bar-stack` | `bar-stacked` | |
| `column-stack` | `column-stacked` | |
| `rating` | `review` | Laid out with HTML rather than SVG |

## Styling

Charty's stylesheet uses plain class selectors — deliberately not a cascade
layer, because unlayered rules beat layered ones no matter how specific, and
host themes routinely ship an unlayered `* { font-size: inherit }` that would
resize every label in every chart.

To restyle something, write a rule of equal specificity after the stylesheet:

```css
.charty { --charty-canvas: 34rem; }
.charty__title { font-size: 1.4em; }
```

The colour tokens (`--charty-surface`, `--charty-text`, `--charty-muted`,
`--charty-line`, `--charty-axis`, `--charty-track`, `--charty-focus`) all use
`light-dark()`, so overriding one means supplying both halves.

## Browser support

Charts need the 2023–2024 CSS baseline: `:has()`, `light-dark()`, `oklch()`,
nesting, and container queries. Older browsers get the markup and the data
without the styling.

## Documentation site

`Docs/` is a small Publish site covering every chart type:

```sh
cd Docs && swift run ChartyDocs
```

## Licence

MIT. See [LICENSE](LICENSE).
