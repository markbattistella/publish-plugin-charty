//
//  Created by Mark Battistella
//	@markbattistella
//

import Foundation

/// Draws `area` charts.
internal struct AreaRenderer: ChartRenderer {

	internal func render(in context: RenderContext) -> RenderedChart {
		var chart = RenderedChart()
		chart.axes = ChartAxes(horizontal: nil, vertical: "Values")

		// The box is widened past the unit square so that tick labels sit
		// inside the canvas and scale with it, rather than overflowing it
		// and needing padding guessed at in the stylesheet.
		chart.viewBox = Axis.viewBox(for: .vertical)

		// Values are drawn against the rounded-up axis, so the top of the tallest
		// shape lines up with a tick rather than with the edge of the canvas.
		let scale = Axis.scale(for: context.statistics.largest)

		chart.canvas.append(
			Axis.grid(scale: scale, orientation: .vertical, showsLabels: context.options.labels)
		)

		for (index, series) in context.spec.data.enumerated() {
			guard series.values.count > 1 else {
				// A single point has no span to spread across the canvas, and
				// dividing by that span is where the original produced NaN.
				if !series.values.isEmpty {
					context.warnings.record(.nonSquareMatrix(series: index + 1, values: series.values.count))
				}
				chart.legendValues.append(nil)
				continue
			}

			let step = 100 / Double(series.values.count - 1)
			let labelSide = Double(index) - Double(context.spec.data.count - 1) / 2
			var vertices: [String] = []
			var labels: [Markup] = []

			for (position, value) in series.values.enumerated() {
				let x = step * Double(position)
				let y = 100 - (value / scale.maximum * 100)
				vertices.append("\(x.svgValue),\(y.svgValue)")

				labels.append(.label(
					value.displayValue,
					x: x,
					y: y + 2 * labelSide * 4.5,
					extra: [Attribute("filter", "url(#\(context.identifier)-backdrop)")]
				))
			}

			// Close the shape along the baseline so it fills rather than
			// drawing as an open line.
			vertices.append("100,100")
			vertices.append("0,100")

			chart.canvas.append(
				.tag("g", [
					Attribute("class", "charty__series"),
					Attribute("data-series", String(index)),
					context.colourStyle(index)
				], [
					.tag("polygon", [
						Attribute("points", vertices.joined(separator: " ")),
						Attribute("fill", "var(--charty-series)")
					]),
					context.options.numbers
						? .tag("g", [Attribute("class", "charty__values")], labels)
						: .none
				])
			)

			chart.legendValues.append(nil)
		}

		return chart
	}
}
