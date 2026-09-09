//
//  Created by Mark Battistella
//	@markbattistella
//

import Foundation

/// A single attribute on a `Markup` element.
///
/// Attributes are stored as an ordered array rather than a dictionary so that
/// rendered output is deterministic — the JavaScript implementation emits the
/// same attributes in the same order, which keeps the two ports diff-able.
internal struct Attribute {

	internal let name: String
	internal let value: String

	internal init(_ name: String, _ value: String) {
		self.name = name
		self.value = value
	}
}

/// A minimal HTML/SVG tree that renders to a string.
///
/// Plot has no SVG support, and the Ink modifier hands back a `String` anyway,
/// so a small builder is both lighter and more direct than bending Plot's
/// type-safe DSL around arbitrary SVG.
internal enum Markup {

	/// An element with a tag name, ordered attributes, and children.
	case element(String, [Attribute], [Markup])

	/// A text node. Escaped on render.
	case text(String)

	/// Pre-rendered markup. Only ever used with strings this module built.
	case raw(String)

	/// A group of nodes with no element of their own.
	case fragment([Markup])
}

// MARK: - Construction

extension Markup {

	/// Builds an element, dropping any children that are empty fragments.
	internal static func tag(
		_ name: String,
		_ attributes: [Attribute] = [],
		_ children: [Markup] = []
	) -> Markup {
		.element(name, attributes, children.filter { !$0.isEmpty })
	}

	/// An empty node, used where a value is conditionally omitted.
	internal static var none: Markup { .fragment([]) }

	/// Whether this node would render nothing at all.
	internal var isEmpty: Bool {
		switch self {
			case .element: return false
			case .text(let value): return value.isEmpty
			case .raw(let value): return value.isEmpty
			case .fragment(let children): return children.allSatisfy(\.isEmpty)
		}
	}
}

// MARK: - Rendering

extension Markup {

	/// Elements that must never be given a closing tag.
	private static let voidElements: Set<String> = [
		"area", "base", "br", "col", "embed", "hr", "img", "input",
		"link", "meta", "param", "source", "track", "wbr"
	]

	/// Renders the tree to a string.
	internal func render() -> String {
		var output = ""
		render(into: &output)
		return output
	}

	private func render(into output: inout String) {
		switch self {

			case .element(let name, let attributes, let children):
				output += "<" + name
				for attribute in attributes {
					output += " " + attribute.name + "=\"" + Self.escape(attribute.value, isAttribute: true) + "\""
				}
				if children.isEmpty && Self.voidElements.contains(name) {
					output += ">"
					return
				}
				output += ">"
				for child in children {
					child.render(into: &output)
				}
				output += "</" + name + ">"

			case .text(let value):
				output += Self.escape(value, isAttribute: false)

			case .raw(let value):
				output += value

			case .fragment(let children):
				for child in children {
					child.render(into: &output)
				}
		}
	}

	/// Escapes text for safe inclusion in markup.
	///
	/// The original JavaScript wrote every label, title, and caption straight
	/// into `innerHTML`, which made any chart definition an injection vector.
	/// Nothing reaches the output here without passing through this.
	internal static func escape(_ string: String, isAttribute: Bool) -> String {
		var output = ""
		output.reserveCapacity(string.count)

		for character in string {
			switch character {
				case "&": output += "&amp;"
				case "<": output += "&lt;"
				case ">": output += "&gt;"
				case "\"" where isAttribute: output += "&quot;"
				case "'" where isAttribute: output += "&#39;"
				default: output.append(character)
			}
		}

		return output
	}
}

// MARK: - Number formatting

extension Double {

	/// Formats a coordinate for use in SVG output.
	///
	/// Rounded to three decimals and stripped of trailing zeros, so that both
	/// this and the JavaScript port emit byte-identical path data.
	internal var svgValue: String {
		guard isFinite else { return "0" }

		let rounded = (self * 1000).rounded() / 1000

		if rounded == rounded.rounded() && abs(rounded) < 1e15 {
			return String(Int(rounded))
		}

		var string = String(format: "%.3f", rounded)
		while string.hasSuffix("0") { string.removeLast() }
		if string.hasSuffix(".") { string.removeLast() }
		return string
	}

	/// Formats a value for display to a reader, with thousands separators.
	internal var displayValue: String {
		if self == rounded() && abs(self) < 1e15 {
			return Self.displayFormatter.string(from: NSNumber(value: Int(self))) ?? String(Int(self))
		}
		return Self.displayFormatter.string(from: NSNumber(value: self)) ?? svgValue
	}

	private static let displayFormatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.maximumFractionDigits = 2
		formatter.usesGroupingSeparator = true
		formatter.groupingSeparator = ","
		formatter.decimalSeparator = "."
		formatter.locale = Locale(identifier: "en_US_POSIX")
		return formatter
	}()

	/// Formats a fraction (0...1) as a percentage string.
	internal func percentageValue(decimals: Int = 2) -> String {
		let percentage = (self * 100 * pow(10, Double(decimals))).rounded() / pow(10, Double(decimals))
		return percentage.svgValue + "%"
	}
}

// MARK: - Text nodes

extension Markup {

	/// Builds an SVG text node with its alignment set explicitly.
	///
	/// Alignment is written as presentation attributes on every label rather
	/// than being defaulted in the stylesheet, because a CSS declaration beats
	/// a presentation attribute — a blanket `text-anchor` rule would silently
	/// override the per-label alignment set here.
	internal static func label(
		_ string: String,
		x: Double,
		y: Double,
		anchor: TextAnchor = .middle,
		baseline: TextBaseline = .middle,
		extra: [Attribute] = []
	) -> Markup {
		.tag("text", [
			Attribute("x", x.svgValue),
			Attribute("y", y.svgValue),
			Attribute("text-anchor", anchor.rawValue),
			Attribute("dominant-baseline", baseline.rawValue)
		] + extra, [.text(string)])
	}
}

/// Horizontal alignment of an SVG label.
internal enum TextAnchor: String {
	case start
	case middle
	case end
}

/// Vertical alignment of an SVG label.
internal enum TextBaseline: String {
	case middle
	case hanging
	case auto
}
