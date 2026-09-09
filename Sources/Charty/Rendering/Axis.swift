//
//  Created by Mark Battistella
//	@markbattistella
//

import Foundation

/// Which way a chart's value axis runs.
internal enum Orientation {

	/// Values grow upwards; categories sit along the bottom.
	case vertical

	/// Values grow rightwards; categories sit down the left.
	case horizontal
}

/// A value axis: where it tops out, and how far apart its ticks are.
internal struct Scale {

	/// The value at the far end of the axis.
	internal let maximum: Double

	/// The gap between ticks.
	internal let step: Double

	/// How many ticks the axis carries, counting zero.
	internal var tickCount: Int {
		guard step > 0 else { return 2 }
		return Int((maximum / step).rounded()) + 1
	}
}

/// Draws the grid lines and tick labels behind a chart.
internal enum Axis {

	/// The most ticks an axis will carry, counting zero.
	private static let maximumTicks = 8

	/// Step sizes an axis is allowed to use, before scaling by a power of ten.
	///
	/// These are the intervals people actually read — halves, quarters, fifths
	/// — rather than whatever falls out of dividing the largest value evenly.
	private static let steps: [Double] = [1, 2, 2.5, 5]

	/// Rounds an axis up to a sensible ceiling with evenly readable ticks.
	///
	/// Dividing the largest value into ten equal parts, as the original did,
	/// produced axes labelled 22, 43, 65, 87 — arithmetically correct and
	/// impossible to read a value off. This rounds 217 up to 250 and steps it
	/// in fifties instead.
	internal static func scale(for maximum: Double) -> Scale {
		guard maximum.isFinite, maximum > 0 else {
			return Scale(maximum: 1, step: 1)
		}

		let exponent = Int(floor(log10(maximum))) - 2

		for power in exponent...(exponent + 4) {
			let magnitude = pow(10, Double(power))

			for candidate in steps {
				let step = candidate * magnitude
				guard step > 0 else { continue }

				let ticks = Int((maximum / step).rounded(.up)) + 1
				if ticks <= maximumTicks {
					return Scale(maximum: (maximum / step).rounded(.up) * step, step: step)
				}
			}
		}

		return Scale(maximum: maximum, step: maximum)
	}

	/// Builds the grid for a chart with a value axis.
	///
	/// - Parameters:
	///   - scale: The axis the data is drawn against.
	///   - orientation: Which way values grow.
	///   - showsLabels: Whether to draw the tick numbers.
	///   - isPercentage: Whether ticks read as percentages rather than values.
	internal static func grid(
		scale: Scale,
		orientation: Orientation,
		showsLabels: Bool,
		isPercentage: Bool = false
	) -> Markup {

		var lines: [Markup] = []
		var labels: [Markup] = []

		for tick in 0..<scale.tickCount {
			let value = Double(tick) * scale.step
			let position = scale.maximum > 0 ? value / scale.maximum * 100 : 0
			let text = isPercentage ? value.svgValue + "%" : value.displayValue

			switch orientation {

				case .vertical:
					let y = 100 - position
					lines.append(.tag("line", [
						Attribute("x1", "0"), Attribute("x2", "100"),
						Attribute("y1", y.svgValue), Attribute("y2", y.svgValue)
					]))
					labels.append(.label(text, x: -3, y: y, anchor: .end))

				case .horizontal:
					lines.append(.tag("line", [
						Attribute("x1", position.svgValue), Attribute("x2", position.svgValue),
						Attribute("y1", "0"), Attribute("y2", "100")
					]))
					labels.append(.label(text, x: position, y: 104, baseline: .hanging))
			}
		}

		var children: [Markup] = [
			.tag("g", [Attribute("class", "charty__grid-lines")], lines),
			axisLines
		]

		if showsLabels {
			children.append(.tag("g", [Attribute("class", "charty__grid-labels")], labels))
		}

		return .tag("g", [
			Attribute("class", "charty__grid"),
			Attribute("aria-hidden", "true")
		], children)
	}
}

// MARK: - Canvas

extension Axis {

	/// The two solid lines the data is measured against.
	///
	/// These are drawn inside the canvas at the edges of the data area. The
	/// original put them on the container as CSS borders, which placed them at
	/// the edge of the box rather than at the origin of the chart.
	internal static var axisLines: Markup {
		.tag("g", [Attribute("class", "charty__axis-lines")], [
			.tag("line", [
				Attribute("x1", "0"), Attribute("y1", "0"),
				Attribute("x2", "0"), Attribute("y2", "100")
			]),
			.tag("line", [
				Attribute("x1", "0"), Attribute("y1", "100"),
				Attribute("x2", "100"), Attribute("y2", "100")
			])
		])
	}

	/// The SVG view box for a chart with a value axis.
	///
	/// Data is always drawn inside the unit square, but tick numbers and
	/// category names sit just outside it. Extending the box to include those
	/// gutters keeps them part of the drawing, so they scale with the chart
	/// instead of relying on `overflow: visible` and padding that has to be
	/// guessed at in the stylesheet.
	internal static func viewBox(for orientation: Orientation) -> String {
		switch orientation {
			case .vertical: return "-16 -7 120 118"
			case .horizontal: return "-22 -5 136 116"
		}
	}
}
