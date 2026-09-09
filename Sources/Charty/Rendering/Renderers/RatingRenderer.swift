//
//  Created by Mark Battistella
//	@markbattistella
//

import Foundation

/// Draws `rating` charts, which are laid out with HTML rather than SVG.
internal struct RatingRenderer: ChartRenderer {

	internal func render(in context: RenderContext) -> RenderedChart {
		var chart = RenderedChart()

		let maximum = context.statistics.rows.first?.maximum ?? 0
		let scale = maximum > 0 ? maximum : 1

		let rows = context.spec.data.enumerated().map { index, series -> Markup in
			let value = series.values.first ?? 0
			let fraction = min(max(value / scale, 0), 1)

			return .tag("div", [
				Attribute("class", "charty__rating"),
				Attribute("data-series", String(index)),
				context.colourStyle(index)
			], [
				context.options.labels && !series.label.isEmpty
					? .tag("span", [Attribute("class", "charty__rating-label")], [.text(series.label)])
					: .none,
				context.options.numbers
					? .tag("span", [Attribute("class", "charty__rating-value")], [.text(value.displayValue)])
					: .none,
				.tag("div", [
					Attribute("class", "charty__rating-track"),
					Attribute("role", "meter"),
					Attribute("aria-valuenow", value.displayValue),
					Attribute("aria-valuemin", "0"),
					Attribute("aria-valuemax", scale.displayValue),
					Attribute("aria-label", series.label)
				], [
					.tag("div", [
						Attribute("class", "charty__rating-fill"),
						Attribute("style", "inline-size: \(fraction.percentageValue(decimals: 2))")
					])
				])
			])
		}

		chart.htmlBody = [.tag("div", [Attribute("class", "charty__ratings")], rows)]

		chart.footnote = .tag("p", [Attribute("class", "charty__footnote")], [
			.text("Ratings are out of a total of "),
			.tag("strong", [], [.text(scale.displayValue)])
		])

		return chart
	}
}
