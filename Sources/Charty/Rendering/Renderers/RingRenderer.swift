//
//  Created by Mark Battistella
//	@markbattistella
//

import Foundation

/// Draws `ring` charts — one concentric progress ring per series.
internal struct RingRenderer: ChartRenderer {
    internal func render(in context: RenderContext) -> RenderedChart {
        var chart = RenderedChart()

        let count = max(context.spec.data.count, 1)
        let bandWidth = 32 / Double(count)

        // Values may be given as fractions or as percentages; whichever way,
        // they end up clamped to 0...1 rather than producing NaN.
        let usesFractions = (context.statistics.rows.first?.maximum ?? 0) <= 1

        for (index, series) in context.spec.data.enumerated() {
            let raw = series.values.first ?? 0
            let fraction = min(max(usesFractions ? raw : raw / 100, 0), 1)

            let radius = 50 - (3 * Double(index) + 1) * bandWidth / 2
            let circumference = 2 * Double.pi * radius

            let shared = [
                Attribute("cx", "50"), Attribute("cy", "50"),
                Attribute("r", radius.svgValue),
                Attribute("stroke-width", bandWidth.svgValue),
                Attribute("fill", "none"),
            ]

            chart.canvas.append(
                .tag(
                    "g",
                    [
                        Attribute("class", "charty__series"),
                        Attribute("data-series", String(index)),
                        // Rings begin at the top. Rotating in the SVG rather than
                        // the stylesheet keeps the drawing correct on its own.
                        Attribute("transform", "rotate(-90 50 50)"),
                        context.colourStyle(index),
                    ],
                    [
                        .tag("circle", [Attribute("class", "charty__ring-track")] + shared),
                        .tag(
                            "circle",
                            [
                                Attribute("class", "charty__ring-fill"),
                                Attribute("stroke", "var(--charty-series)"),
                                Attribute("stroke-linecap", "round"),
                                Attribute("stroke-dasharray", "\(circumference.svgValue) \(circumference.svgValue)"),
                                Attribute("stroke-dashoffset", (circumference - fraction * circumference).svgValue),
                            ] + shared
                        ),
                    ]
                )
            )

            // The original multiplied a `toFixed` string by 100, which floated
            // values such as 76 out to 76.00000000000001.
            chart.legendValues.append(
                context.options.numbers ? fraction.percentageValue(decimals: 1) : nil
            )
        }

        return chart
    }
}
