//
//  Created by Mark Battistella
//	@markbattistella
//

import Foundation

/// Turns a decoded chart and its rendered body into the final markup.
internal struct ChartAssembler {

	internal let context: RenderContext
	internal let chart: RenderedChart

	/// Builds the complete `<figure>` for a chart.
	internal func assemble() -> Markup {

		var classes = ["charty", "charty--\(context.spec.type.rawValue)"]
		if context.spec.type.hasAxes && context.options.labels { classes.append("charty--axes") }
		if showsLegend { classes.append("charty--legend") }

		var attributes = [
			Attribute("class", classes.joined(separator: " ")),
			Attribute("data-charty", context.spec.type.rawValue)
		]

		if let scheme = context.configuration.colourScheme.cssValue {
			attributes.append(Attribute("style", "color-scheme: \(scheme)"))
		}

		return .tag("figure", attributes, [
			header,
			.tag("div", [Attribute("class", "charty__container")], [body, legend]),
			chart.footnote ?? .none
		])
	}
}

// MARK: - Header

extension ChartAssembler {

	private var title: String? {
		context.spec.title.flatMap { $0.isEmpty ? nil : $0 }
	}

	private var caption: String? {
		context.spec.caption.flatMap { $0.isEmpty ? nil : $0 }
	}

	/// The title and caption, wrapped in the figure's caption element.
	private var header: Markup {
		guard title != nil || caption != nil else { return .none }

		return .tag("figcaption", [Attribute("class", "charty__header")], [
			title.map { value in
				Markup.tag("h3", [
					Attribute("class", "charty__title"),
					Attribute("id", "\(context.identifier)-title")
				], [.text(value)])
			} ?? .none,
			caption.map { value in
				Markup.tag("p", [
					Attribute("class", "charty__caption"),
					Attribute("id", "\(context.identifier)-caption")
				], [.text(value)])
			} ?? .none
		])
	}
}

// MARK: - Body

extension ChartAssembler {

	/// The plot area, including any axis titles.
	private var body: Markup {
		var children: [Markup] = []

		if let axes = chart.axes, context.options.labels {
			if let vertical = axes.vertical {
				children.append(.tag("span", [
					Attribute("class", "charty__axis charty__axis--vertical")
				], [.text(vertical)]))
			}
			children.append(canvas)
			if let horizontal = axes.horizontal {
				children.append(.tag("span", [
					Attribute("class", "charty__axis charty__axis--horizontal")
				], [.text(horizontal)]))
			}
		} else {
			children.append(canvas)
		}

		return .tag("div", [Attribute("class", "charty__plot")], children)
	}

	/// The SVG canvas, or the HTML body for charts that do not use SVG.
	private var canvas: Markup {
		if let htmlBody = chart.htmlBody {
			return .tag("div", [
				Attribute("class", "charty__canvas"),
				Attribute("role", "img"),
				Attribute("aria-label", accessibleLabel)
			], htmlBody)
		}

		return .tag("div", [Attribute("class", "charty__canvas")], [svg])
	}

	/// The SVG element itself.
	private var svg: Markup {
		var labelledBy: [String] = []
		var describedNodes: [Markup] = []

		// A chart with no title of its own still needs a name, otherwise it is
		// announced as an unlabelled graphic.
		let name = title ?? defaultName
		labelledBy.append("\(context.identifier)-svg-title")
		describedNodes.append(.tag("title", [
			Attribute("id", "\(context.identifier)-svg-title")
		], [.text(name)]))

		if let caption {
			labelledBy.append("\(context.identifier)-svg-desc")
			describedNodes.append(.tag("desc", [
				Attribute("id", "\(context.identifier)-svg-desc")
			], [.text(caption)]))
		}

		var defs = chart.defs
		if context.options.numbers {
			defs.append(inkBackdrop)
		}

		if !defs.isEmpty {
			describedNodes.append(.tag("defs", [], defs))
		}

		describedNodes.append(
			.tag("g", [Attribute("class", "charty__data")] + chart.groupAttributes, chart.canvas)
		)

		return .tag("svg", [
			Attribute("class", "charty__svg"),
			Attribute("viewBox", chart.viewBox),
			Attribute("preserveAspectRatio", "xMidYMid meet"),
			Attribute("role", "img"),
			Attribute("aria-labelledby", labelledBy.joined(separator: " ")),
			Attribute("xmlns", "http://www.w3.org/2000/svg")
		], describedNodes)
	}

	/// A name for charts with no title, so the graphic is never anonymous.
	private var defaultName: String {
		let kind = context.spec.type.rawValue.replacingOccurrences(of: "-", with: " ")
		return "\(kind) chart"
	}

	/// A flat text label for non-SVG charts.
	private var accessibleLabel: String {
		[title, caption].compactMap { $0 }.joined(separator: ". ").isEmpty
			? defaultName
			: [title, caption].compactMap { $0 }.joined(separator: ". ")
	}

	/// The filter that puts a solid backdrop behind value labels.
	///
	/// The identifier is scoped to this chart. The original used a single fixed
	/// `text-bg` identifier, so a page with more than one chart had every chart
	/// after the first referencing the first chart's filter.
	private var inkBackdrop: Markup {
		.tag("filter", [
			Attribute("id", "\(context.identifier)-backdrop"),
			Attribute("x", "-0.2"),
			Attribute("y", "-0.15"),
			Attribute("width", "1.4"),
			Attribute("height", "1.3")
		], [
			.tag("feFlood", [Attribute("flood-color", "var(--charty-surface)")]),
			.tag("feComposite", [Attribute("in", "SourceGraphic"), Attribute("operator", "over")])
		])
	}
}

// MARK: - Legend

extension ChartAssembler {

	private var showsLegend: Bool {
		context.options.legend
			&& context.spec.type.supportsLegend
			&& !context.spec.data.isEmpty
	}

	/// The legend list.
	///
	/// Items carry `data-series` so the stylesheet can pair a legend entry with
	/// its shape using `:has()`, which is what removed the plugin's need for
	/// any runtime JavaScript.
	private var legend: Markup {
		guard showsLegend else { return .none }

		let items = context.spec.data.enumerated().map { index, series -> Markup in
			let value = chart.legendValues.indices.contains(index)
				? chart.legendValues[index]
				: nil

			return .tag("li", [
				Attribute("class", "charty__legend-item"),
				Attribute("data-series", String(index)),
				Attribute("tabindex", "0"),
				context.colourStyle(index)
			], [
				.tag("span", [
					Attribute("class", "charty__swatch"),
					Attribute("aria-hidden", "true")
				]),
				context.options.labels && !series.label.isEmpty
					? .tag("span", [Attribute("class", "charty__legend-label")], [.text(series.label)])
					: .none,
				value.map { text in
					Markup.tag("span", [Attribute("class", "charty__legend-value")], [.text(text)])
				} ?? .none
			])
		}

		return .tag("ul", [
			Attribute("class", "charty__legend"),
			Attribute("aria-label", "Legend")
		], items)
	}
}
