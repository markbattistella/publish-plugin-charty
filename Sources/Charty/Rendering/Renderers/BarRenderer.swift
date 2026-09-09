//
//  Created by Mark Battistella
//	@markbattistella
//

import Foundation

/// Draws `bar`, `column`, and their stacked variants.
///
/// `bar` runs vertically and `column` runs horizontally. The original produced
/// the horizontal form by rotating the whole SVG group ninety degrees in CSS,
/// which turned every tick number and category label on its side. Here the
/// geometry is mirrored instead, so text stays upright either way.
internal struct BarRenderer: ChartRenderer {

	/// The share of a group's width left empty, split between its two sides.
	private static let groupPadding = 0.24

	/// The share of a bar's slot left empty when a group holds several bars.
	///
	/// Bars within a group sit close together and groups sit far apart, so the
	/// grouping reads at a glance. The original spaced every bar identically,
	/// which made a grouped chart look like one long run of bars.
	private static let barPadding = 0.12

	internal func render(in context: RenderContext) -> RenderedChart {
		var chart = RenderedChart()

		let type = context.spec.type
		let orientation: Orientation = type.isColumn ? .horizontal : .vertical
		let isStacked = type.isStacked

		chart.viewBox = Axis.viewBox(for: orientation)

		let series = context.spec.data
		let valueCount = series.map(\.values.count).max() ?? 0

		guard valueCount > 0 else {
			context.warnings.record(.noData)
			return chart
		}

		if let mismatched = series.first(where: { $0.values.count != valueCount }) {
			context.warnings.record(.nonSquareMatrix(
				series: series.count,
				values: mismatched.values.count
			))
		}

		// With one value per series, each series is its own category and gets
		// its own slot along the axis. With several, the slots are the value
		// positions and the series are grouped inside them.
		let isSimple = valueCount == 1 && !isStacked
		let groupCount = isSimple ? series.count : valueCount
		let barsPerGroup = (isSimple || isStacked) ? 1 : series.count

		let scale = isStacked
			? Scale(maximum: 100, step: 20)
			: Axis.scale(for: context.statistics.largest)

		// Stacked charts are measured as a share of each column, so the axis is
		// named for what it actually shows rather than for raw values.
		let valueTitle = isStacked ? "Share" : "Values"

		// Grouped charts name their bars in the legend rather than along the
		// axis, so there is no category axis left to title.
		let categoryTitle = isSimple ? "Labels" : nil

		chart.axes = orientation == .vertical
			? ChartAxes(horizontal: categoryTitle, vertical: valueTitle)
			: ChartAxes(horizontal: valueTitle, vertical: categoryTitle)

		chart.canvas.append(Axis.grid(
			scale: scale,
			orientation: orientation,
			showsLabels: context.options.labels,
			isPercentage: isStacked
		))

		let geometry = Geometry(groupCount: groupCount, barsPerGroup: barsPerGroup)

		// Totals down each column, used to size the segments of a stack.
		let columnTotals = (0..<valueCount).map { position in
			series.reduce(0.0) { $0 + ($1.values.indices.contains(position) ? $1.values[position] : 0) }
		}

		var offsets = [Double](repeating: 0, count: valueCount)
		var categoryLabels: [Markup] = []

		for (index, item) in series.enumerated() {
			var shapes: [Markup] = []
			var labels: [Markup] = []

			for (position, value) in item.values.enumerated() {
				let group = isSimple ? index : position
				let slotIndex = (isSimple || isStacked) ? 0 : index

				let extent = isStacked
					? (columnTotals[position] > 0 ? value / columnTotals[position] * 100 : 0)
					: (scale.maximum > 0 ? value / scale.maximum * 100 : 0)

				let start = isStacked ? offsets[position] : 0
				if isStacked { offsets[position] += extent }

				let bar = geometry.bar(group: group, index: slotIndex)

				shapes.append(rectangle(
					slot: bar.start,
					thickness: bar.width,
					start: start,
					extent: extent,
					orientation: orientation,
					isStacked: isStacked
				))

				if context.options.numbers {
					labels.append(valueLabel(
						value: value,
						slot: bar.centre,
						start: start,
						extent: extent,
						orientation: orientation,
						isStacked: isStacked,
						identifier: context.identifier
					))
				}

				if context.options.labels && isSimple && !item.label.isEmpty {
					categoryLabels.append(categoryLabel(
						item.label,
						slot: bar.centre,
						orientation: orientation
					))
				}
			}

			chart.canvas.append(
				.tag("g", [
					Attribute("class", "charty__series"),
					Attribute("data-series", String(index)),
					context.colourStyle(index)
				], shapes + [
					labels.isEmpty ? .none : .tag("g", [Attribute("class", "charty__values")], labels)
				])
			)

			chart.legendValues.append(nil)
		}

		if !categoryLabels.isEmpty {
			chart.canvas.append(.tag("g", [
				Attribute("class", "charty__categories"),
				Attribute("aria-hidden", "true")
			], categoryLabels))
		}

		return chart
	}
}

// MARK: - Geometry

extension BarRenderer {

	/// Works out where each bar sits along the category axis.
	private struct Geometry {

		let groupCount: Int
		let barsPerGroup: Int

		private var groupWidth: Double { 100 / Double(max(groupCount, 1)) }

		private var inset: Double { groupWidth * BarRenderer.groupPadding / 2 }

		private var slotWidth: Double {
			groupWidth * (1 - BarRenderer.groupPadding) / Double(max(barsPerGroup, 1))
		}

		private var barWidth: Double {
			barsPerGroup > 1 ? slotWidth * (1 - BarRenderer.barPadding) : slotWidth
		}

		/// The leading edge, width, and midpoint of one bar.
		func bar(group: Int, index: Int) -> (start: Double, width: Double, centre: Double) {
			let slot = groupWidth * Double(group) + inset + slotWidth * Double(index)
			let start = slot + (slotWidth - barWidth) / 2
			return (start, barWidth, start + barWidth / 2)
		}
	}

	/// One bar or one segment of a stack.
	private func rectangle(
		slot: Double,
		thickness: Double,
		start: Double,
		extent: Double,
		orientation: Orientation,
		isStacked: Bool
	) -> Markup {

		let attributes: [Attribute]

		switch orientation {

			case .vertical:
				// Grouped bars grow up from the baseline; stacked segments are
				// laid down from the top of the column.
				attributes = [
					Attribute("x", slot.svgValue),
					Attribute("y", (isStacked ? start : 100 - extent).svgValue),
					Attribute("width", thickness.svgValue),
					Attribute("height", max(extent, 0).svgValue)
				]

			case .horizontal:
				attributes = [
					Attribute("x", (isStacked ? start : 0).svgValue),
					Attribute("y", slot.svgValue),
					Attribute("width", max(extent, 0).svgValue),
					Attribute("height", thickness.svgValue)
				]
		}

		return .tag("rect", attributes + [Attribute("fill", "var(--charty-series)")])
	}

	/// The number drawn against a bar.
	private func valueLabel(
		value: Double,
		slot: Double,
		start: Double,
		extent: Double,
		orientation: Orientation,
		isStacked: Bool,
		identifier: String
	) -> Markup {

		let backdrop = [Attribute("filter", "url(#\(identifier)-backdrop)")]

		switch orientation {

			case .vertical:
				return .label(
					value.displayValue,
					x: slot,
					y: isStacked ? start + extent / 2 : 100 - extent - 2.5,
					extra: backdrop
				)

			case .horizontal:
				return .label(
					value.displayValue,
					x: isStacked ? start + extent / 2 : extent + 2,
					y: slot,
					anchor: isStacked ? .middle : .start,
					extra: backdrop
				)
		}
	}

	/// The series name shown against the category axis.
	private func categoryLabel(_ label: String, slot: Double, orientation: Orientation) -> Markup {
		switch orientation {
			case .vertical: return .label(label, x: slot, y: 104, baseline: .hanging)
			case .horizontal: return .label(label, x: -3, y: slot, anchor: .end)
		}
	}
}
