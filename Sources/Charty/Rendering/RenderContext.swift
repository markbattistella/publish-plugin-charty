//
//  Created by Mark Battistella
//	@markbattistella
//

import Foundation

/// Everything a renderer needs to draw one chart.
internal struct RenderContext {
    /// The decoded chart definition.
    internal let spec: ChartSpec

    /// Summary numbers for the chart's data.
    internal let statistics: ChartStatistics

    /// One colour per series, already resolved against any explicit overrides.
    internal let colours: [SeriesColour]

    /// The site-wide configuration.
    internal let configuration: ChartyConfiguration

    /// A short identifier, unique to this chart within its page.
    internal let identifier: String

    /// Problems found while drawing, reported at the end of the build.
    internal let warnings: Warnings

    /// A reference box for warnings, so renderers can stay non-mutating.
    internal final class Warnings {
        private(set) var messages: [String] = []
        func record(_ error: ChartyError) { messages.append(error.description) }
    }

    internal init(spec: ChartSpec, configuration: ChartyConfiguration, identifier: String) {
        self.spec = spec
        self.configuration = configuration
        self.identifier = identifier
        self.statistics = ChartStatistics(series: spec.data)
        self.warnings = Warnings()

        // An explicit per-chart theme beats the site theme; an explicit colour
        // on a single series beats both.
        let theme =
            spec.options.theme.flatMap(Colour.init(hex:))
            ?? configuration.themeColour
        let generated = theme.palette(count: spec.data.count)

        self.colours = spec.data.enumerated().map { index, series in
            guard let override = series.colour, !override.isEmpty else {
                return generated[index]
            }
            let parsed = Colour(hex: override)
            return SeriesColour(
                light: override,
                dark: override,
                ink: (parsed?.prefersDarkInk ?? true) ? "oklch(0.2 0 0)" : "oklch(0.99 0 0)"
            )
        }
    }

    /// Convenience access to the chart's options.
    internal var options: ChartOptions { spec.options }

    /// The colour for a series, falling back to the theme if indexes drift.
    internal func colour(_ index: Int) -> SeriesColour {
        colours.indices.contains(index)
            ? colours[index]
            : SeriesColour(light: "currentColor", dark: "currentColor", ink: "oklch(0.2 0 0)")
    }

    /// The custom properties that carry a series colour into CSS.
    internal func colourStyle(_ index: Int) -> Attribute {
        let colour = self.colour(index)
        return Attribute("style", "--charty-series: \(colour.cssValue); --charty-ink: \(colour.ink)")
    }
}

/// The axis titles shown alongside a chart.
internal struct ChartAxes {
    internal let horizontal: String?
    internal let vertical: String?
}

/// What a renderer produces.
internal struct RenderedChart {
    /// Children of the `<g class="charty__data">` group.
    internal var canvas: [Markup] = []

    /// Extra `<defs>` entries, such as the donut mask.
    internal var defs: [Markup] = []

    /// An attribute applied to the data group, such as the donut's mask.
    internal var groupAttributes: [Attribute] = []

    /// The value text shown beside each series in the legend.
    internal var legendValues: [String?] = []

    /// Axis titles, when the chart has axes.
    internal var axes: ChartAxes?

    /// Markup used in place of an SVG canvas. Only `rating` uses this.
    internal var htmlBody: [Markup]?

    /// A trailing note rendered under the chart.
    internal var footnote: Markup?

    /// The SVG view box, when a chart needs something other than the unit square.
    internal var viewBox: String = "0 0 100 100"
}

/// Draws one kind of chart.
internal protocol ChartRenderer {
    func render(in context: RenderContext) -> RenderedChart
}
