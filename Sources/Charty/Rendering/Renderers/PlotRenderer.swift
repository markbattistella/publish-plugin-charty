//
//  Created by Mark Battistella
//	@markbattistella
//

import Foundation

/// Draws `plot`, `line`, and `bubble` charts.
internal struct PlotRenderer: ChartRenderer {

	/// The radius of a plotted point when it is not scaled by its value.
	private static let pointRadius = 1.6

	internal func render(in context: RenderContext) -> RenderedChart {
		var chart = RenderedChart()
		chart.axes = ChartAxes(horizontal: nil, vertical: "Values")

		// The box is widened past the unit square so that tick labels sit
		// inside the canvas and scale with it, rather than overflowing it
		// and needing padding guessed at in the stylesheet.
		chart.viewBox = Axis.viewBox(for: .vertical)

		let type = context.spec.type
		let scale = Axis.scale(for: context.statistics.largest)

		chart.canvas.append(
			Axis.grid(scale: scale, orientation: .vertical, showsLabels: context.options.labels)
		)

		for (index, series) in context.spec.data.enumerated() {
			guard !series.values.isEmpty else {
				chart.legendValues.append(nil)
				continue
			}

			let slot = 100 / Double(series.values.count)
			let rowSum = context.statistics.row(index).sum

			// Labels are fanned out around the point, one step per series, so
			// that lines running close together do not stack their numbers on
			// top of each other.
			let labelSide = Double(index) - Double(context.spec.data.count - 1) / 2

			var vertices: [String] = []
			var points: [Markup] = []
			var labels: [Markup] = []

			for (position, value) in series.values.enumerated() {
				let x = slot * (Double(position) + 0.5)
				let y = 100 - (value / scale.maximum * 100)
				vertices.append("\(x.svgValue),\(y.svgValue)")

				let radius = type == .bubble && rowSum > 0
					? Self.pointRadius + 5 * value / rowSum
					: Self.pointRadius

				points.append(.tag("circle", [
					Attribute("cx", x.svgValue),
					Attribute("cy", y.svgValue),
					Attribute("r", radius.svgValue),
					Attribute("fill", "var(--charty-series)")
				]))

				labels.append(.label(
					value.displayValue,
					x: x,
					y: y + 2 * labelSide * (radius + 3.5),
					extra: [Attribute("filter", "url(#\(context.identifier)-backdrop)")]
				))
			}

			// The connecting line is drawn first so the points sit on top of it
			// rather than being covered by later segments.
			var children: [Markup] = []

			if type == .line {
				children.append(.tag("polyline", [
					Attribute("class", "charty__line"),
					Attribute("points", vertices.joined(separator: " ")),
					Attribute("stroke", "var(--charty-series)"),
					Attribute("stroke-width", "0.8"),
					Attribute("stroke-linecap", "round"),
					Attribute("stroke-linejoin", "round"),
					Attribute("fill", "none")
				]))
			}

			children.append(contentsOf: points)

			if context.options.numbers {
				children.append(.tag("g", [Attribute("class", "charty__values")], labels))
			}

			chart.canvas.append(
				.tag("g", [
					Attribute("class", "charty__series"),
					Attribute("data-series", String(index)),
					context.colourStyle(index)
				], children)
			)

			chart.legendValues.append(nil)
		}

		return chart
	}
}
