//
//  Created by Mark Battistella
//	@markbattistella
//

import Foundation

/// Draws `pie`, `donut`, and `section` charts.
internal struct CircleRenderer: ChartRenderer {
    internal func render(in context: RenderContext) -> RenderedChart {
        var chart = RenderedChart()

        let isSection = context.spec.type == .section
        let total = context.statistics.total
        var cumulative = 0.0

        for (index, series) in context.spec.data.enumerated() {
            let value = series.values.first ?? 0

            // `section` takes fractions straight from the data; the other two
            // work out each slice's share of the total.
            let fraction =
                isSection
                ? value
                : (total > 0 ? value / total : 0)

            guard fraction > 0 else {
                chart.legendValues.append(
                    legendValue(value: value, fraction: 0, isSection: isSection, context: context)
                )
                continue
            }

            chart.canvas.append(
                .tag(
                    "g",
                    [
                        Attribute("class", "charty__series"),
                        Attribute("data-series", String(index)),
                        context.colourStyle(index),
                    ],
                    [slice(from: cumulative, fraction: fraction)]
                )
            )

            cumulative += fraction
            chart.legendValues.append(
                legendValue(value: value, fraction: fraction, isSection: isSection, context: context)
            )
        }

        if context.spec.type == .donut {
            chart.defs.append(hole(identifier: context.identifier))
            chart.groupAttributes.append(Attribute("mask", "url(#\(context.identifier)-hole)"))
        }

        return chart
    }
}

// MARK: - Geometry

extension CircleRenderer {
    /// The point on the circle at a given fraction of a full turn.
    ///
    /// Slices begin at twelve o'clock. The original began at three o'clock and
    /// then rotated the whole group by -90° in CSS, which meant the geometry
    /// only looked right once the stylesheet had loaded.
    private func point(at fraction: Double) -> (x: Double, y: Double) {
        let angle = 2 * Double.pi * fraction - Double.pi / 2
        return (50 + 50 * cos(angle), 50 + 50 * sin(angle))
    }

    /// One slice of the circle.
    private func slice(from start: Double, fraction: Double) -> Markup {
        // A slice covering the whole circle starts and ends at the same point,
        // which makes an arc command draw nothing at all. Any chart with a
        // single data point used to render as an empty box because of this.
        guard fraction < 1 else {
            return .tag(
                "circle",
                [
                    Attribute("cx", "50"), Attribute("cy", "50"), Attribute("r", "50"),
                    Attribute("fill", "var(--charty-series)"),
                ]
            )
        }

        let begin = point(at: start)
        let end = point(at: start + fraction)
        let largeArc = fraction > 0.5 ? "1" : "0"

        let path = [
            "M 50 50",
            "L \(begin.x.svgValue) \(begin.y.svgValue)",
            "A 50 50 0 \(largeArc) 1 \(end.x.svgValue) \(end.y.svgValue)",
            "Z",
        ].joined(separator: " ")

        return .tag(
            "path",
            [
                Attribute("d", path),
                Attribute("fill", "var(--charty-series)"),
            ]
        )
    }

    /// The mask that cuts the middle out of a donut.
    private func hole(identifier: String) -> Markup {
        .tag(
            "mask",
            [Attribute("id", "\(identifier)-hole")],
            [
                .tag(
                    "rect",
                    [
                        Attribute("width", "100"), Attribute("height", "100"),
                        Attribute("fill", "white"),
                    ]
                ),
                .tag(
                    "circle",
                    [
                        Attribute("cx", "50"), Attribute("cy", "50"),
                        Attribute("r", "25"), Attribute("fill", "black"),
                    ]
                ),
            ]
        )
    }

    /// The text shown next to this series in the legend.
    private func legendValue(
        value: Double,
        fraction: Double,
        isSection: Bool,
        context: RenderContext
    ) -> String? {
        guard context.options.numbers else { return nil }

        return isSection
            ? fraction.percentageValue()
            : "\(value.displayValue) · \(fraction.percentageValue(decimals: 1))"
    }
}
