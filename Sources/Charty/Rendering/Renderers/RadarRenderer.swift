//
//  Created by Mark Battistella
//	@markbattistella
//

import Foundation

/// Draws `radar` charts.
internal struct RadarRenderer: ChartRenderer {
    /// The radius of the outermost ring, in user units.
    private static let radius = 100.0

    /// How far beyond the outer ring the axis labels sit.
    private static let labelRadius = 116.0

    internal func render(in context: RenderContext) -> RenderedChart {
        var chart = RenderedChart()

        // The canvas is centred on the origin so that the geometry needs no
        // CSS transform to sit in the right place.
        chart.viewBox = "-132 -132 264 264"

        let points = context.spec.resolvedPoints

        guard !points.isEmpty else {
            context.warnings.record(
                .pointCountMismatch(series: context.spec.title ?? "chart", values: 0, points: 0)
            )
            return chart
        }

        chart.canvas.append(scaffold(points: points, showsLabels: context.options.labels))

        for (index, series) in context.spec.data.enumerated() {
            guard series.values.count == points.count else {
                context.warnings.record(
                    .pointCountMismatch(
                        series: series.label,
                        values: series.values.count,
                        points: points.count
                    )
                )
                chart.legendValues.append(nil)
                continue
            }

            var vertices: [String] = []
            var labels: [Markup] = []

            // Labels are fanned along the spoke, one step per series, so that
            // overlapping shapes do not stack their numbers in one place.
            let labelNudge = 9 * (Double(index) - Double(context.spec.data.count - 1) / 2)

            for (position, value) in series.values.enumerated() {
                guard (0...100).contains(value) else {
                    context.warnings.record(.valueOutOfRange(series: series.label, value: value))
                    continue
                }

                let angle = self.angle(at: position, of: points.count)
                let distance = Self.radius * value / 100

                let x = distance * cos(angle)
                let y = distance * sin(angle)
                vertices.append("\(x.svgValue),\(y.svgValue)")

                let labelDistance = min(max(distance + labelNudge, 12), 104)

                labels.append(
                    .label(
                        value.svgValue + "%",
                        x: labelDistance * cos(angle),
                        y: labelDistance * sin(angle),
                        extra: [Attribute("filter", "url(#\(context.identifier)-backdrop)")]
                    )
                )
            }

            chart.canvas.append(
                .tag(
                    "g",
                    [
                        Attribute("class", "charty__series"),
                        Attribute("data-series", String(index)),
                        context.colourStyle(index),
                    ],
                    [
                        .tag(
                            "polygon",
                            [
                                Attribute("points", vertices.joined(separator: " ")),
                                Attribute("fill", "var(--charty-series)"),
                            ]
                        ),
                        context.options.numbers
                            ? .tag("g", [Attribute("class", "charty__values")], labels)
                            : .none,
                    ]
                )
            )

            chart.legendValues.append(nil)
        }

        return chart
    }
}

// MARK: - Geometry

extension RadarRenderer {
    /// The angle of a spoke, measured from twelve o'clock.
    private func angle(at position: Int, of count: Int) -> Double {
        (2 * Double.pi / Double(count)) * Double(position) - Double.pi / 2
    }

    /// The rings, spokes, and axis labels the data is drawn on top of.
    private func scaffold(points: [String], showsLabels: Bool) -> Markup {
        let rings = stride(from: 20.0, through: Self.radius, by: 20.0).map { radius in
            Markup.tag(
                "circle",
                [
                    Attribute("cx", "0"), Attribute("cy", "0"),
                    Attribute("r", radius.svgValue),
                ]
            )
        }

        var spokes: [Markup] = []
        var labels: [Markup] = []

        for (position, name) in points.enumerated() {
            let angle = self.angle(at: position, of: points.count)

            spokes.append(
                .tag(
                    "line",
                    [
                        Attribute("x1", "0"), Attribute("y1", "0"),
                        Attribute("x2", (Self.radius * cos(angle)).svgValue),
                        Attribute("y2", (Self.radius * sin(angle)).svgValue),
                    ]
                )
            )

            // Labels are placed by coordinate rather than rotated into position,
            // so they stay upright instead of running upside-down on the left
            // half of the chart.
            labels.append(
                .label(
                    name,
                    x: Self.labelRadius * cos(angle),
                    y: Self.labelRadius * sin(angle),
                    anchor: anchor(for: cos(angle))
                )
            )
        }

        return .tag(
            "g",
            [
                Attribute("class", "charty__grid"),
                Attribute("aria-hidden", "true"),
            ],
            [
                .tag("g", [Attribute("class", "charty__grid-rings")], rings),
                .tag("g", [Attribute("class", "charty__grid-lines")], spokes),
                showsLabels ? .tag("g", [Attribute("class", "charty__grid-labels")], labels) : .none,
            ]
        )
    }

    /// Keeps axis labels from overhanging the chart on the left and right.
    private func anchor(for cosine: Double) -> TextAnchor {
        if cosine > 0.2 { return .start }
        if cosine < -0.2 { return .end }
        return .middle
    }
}
