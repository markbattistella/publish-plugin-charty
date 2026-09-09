//
//  Created by Mark Battistella
//	@markbattistella
//

import Foundation

/// The kinds of chart Charty can draw.
///
/// Several spellings map onto the same case — `doughnut` and `donut`, `rings`
/// and `ring`, and the `-stack` / `-stacked` suffixes — so that chart
/// definitions written for any version of the plugin keep working.
public enum ChartType: String, CaseIterable, Sendable {

	case radar
	case area
	case pie
	case donut
	case section
	case ring
	case plot
	case line
	case bubble
	case bar
	case column
	case barStack = "bar-stack"
	case columnStack = "column-stack"
	case rating
}

extension ChartType {

	/// Resolves a raw `type` string, including every accepted alias.
	internal init?(alias: String) {
		let normalised = alias.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

		switch normalised {
			case "doughnut": self = .donut
			case "sectional": self = .section
			case "rings": self = .ring
			case "scatter": self = .plot
			case "review": self = .rating
			default:
				let destacked = normalised.hasSuffix("-stacked")
					? String(normalised.dropLast("-stacked".count)) + "-stack"
					: normalised

				guard let type = ChartType(rawValue: destacked) else { return nil }
				self = type
		}
	}

	/// Charts drawn against a pair of axes.
	internal var hasAxes: Bool {
		switch self {
			case .area, .plot, .line, .bubble, .bar, .column, .barStack, .columnStack: return true
			default: return false
		}
	}

	/// Charts that draw into an SVG canvas. `rating` is laid out with HTML.
	internal var usesSVG: Bool { self != .rating }

	/// Charts that can show a legend.
	internal var supportsLegend: Bool { self != .rating }

	/// Whether this is one of the stacked bar variants.
	internal var isStacked: Bool { self == .barStack || self == .columnStack }

	/// Whether this variant runs vertically (columns) rather than horizontally.
	internal var isColumn: Bool { self == .column || self == .columnStack }
}
