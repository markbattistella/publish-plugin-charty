//
//  Created by Mark Battistella
//	@markbattistella
//

import Testing
@testable import Charty

// MARK: - Block parsing

@Suite("Block parsing")
struct BlockParsingTests {

	@Test("A charty block yields its body")
	func extractsBody() {
		let block: Substring = """
		```charty
		{ "type": "pie" }
		```
		"""
		#expect(Charty.chartBody(in: block) == "{ \"type\": \"pie\" }")
	}

	@Test("Blocks in other languages are left alone", arguments: ["swift", "json", ""])
	func ignoresOtherLanguages(_ language: String) {
		let block = Substring("```\(language)\n{}\n```")
		#expect(Charty.chartBody(in: block) == nil)
	}

	@Test("Tildes are accepted as fences")
	func acceptsTildeFences() {
		#expect(Charty.chartBody(in: "~~~charty\n{}\n~~~") == "{}")
	}

	@Test("Identifiers are stable between runs")
	func identifiersAreStable() {
		#expect(Charty.identifier(for: "abc") == Charty.identifier(for: "abc"))
		#expect(Charty.identifier(for: "abc") != Charty.identifier(for: "abd"))
	}
}

// MARK: - Types

@Suite("Chart types")
struct ChartTypeTests {

	@Test(
		"Aliases resolve to their canonical type",
		arguments: [
			("doughnut", ChartType.donut),
			("sectional", .section),
			("rings", .ring),
			("scatter", .plot),
			("review", .rating),
			("bar-stacked", .barStack),
			("column-stacked", .columnStack),
			("COLUMN", .column)
		]
	)
	func resolvesAliases(_ alias: String, _ expected: ChartType) {
		#expect(ChartType(alias: alias) == expected)
	}

	@Test("Unknown types are rejected")
	func rejectsUnknown() {
		#expect(ChartType(alias: "sunburst") == nil)
	}
}

// MARK: - Colour

@Suite("Colour")
struct ColourTests {

	@Test("Hex parsing round-trips through OKLCH")
	func parsesHex() throws {
		let blue = try #require(Colour(hex: "#0984E3"))
		#expect(blue.lightness > 0.5 && blue.lightness < 0.7)
		#expect(blue.chroma > 0.1)
		#expect(blue.hue > 220 && blue.hue < 280)
	}

	@Test("Short hex expands")
	func parsesShortHex() throws {
		let short = try #require(Colour(hex: "#08E"))
		let long = try #require(Colour(hex: "#0088EE"))
		#expect(short == long)
	}

	@Test("Invalid input falls back rather than crashing", arguments: ["", "nope", "#12345", "rgb(1,2,3)"])
	func rejectsBadHex(_ input: String) {
		#expect(Colour(hex: input) == nil)
	}

	/// The original ramp multiplied lightness by the series index, which made
	/// the first series pure black in every multi-series chart.
	@Test("No series is generated at either extreme of the lightness scale")
	func paletteAvoidsBlackAndWhite() throws {
		let theme = try #require(Colour(hex: "#0984E3"))

		for count in 1...16 {
			for entry in theme.palette(count: count) {
				#expect(!entry.light.contains("oklch(0 "))
				#expect(!entry.light.contains("oklch(1 "))
			}
		}
	}

	@Test("Palettes step evenly and stay inside the legible range")
	func paletteIsEvenlySpaced() throws {
		let theme = try #require(Colour(hex: "#0984E3"))
		let palette = theme.palette(count: 4)

		#expect(palette.count == 4)
		#expect(Set(palette.map(\.light)).count == 4)
		#expect(palette.allSatisfy { $0.cssValue.contains("light-dark(") })
	}

	@Test("A single series sits in the middle of the ramp")
	func singleSeriesIsMidTone() throws {
		let theme = try #require(Colour(hex: "#0984E3"))
		let only = try #require(theme.palette(count: 1).first)
		#expect(only.light.contains("oklch(0.62"))
	}
}

// MARK: - Markup

@Suite("Markup")
struct MarkupTests {

	/// Labels, titles, and captions used to be written straight into innerHTML.
	@Test("Text is escaped")
	func escapesText() {
		let node = Markup.tag("p", [], [.text("<script>alert('x')</script> & more")])
		#expect(node.render() == "<p>&lt;script&gt;alert('x')&lt;/script&gt; &amp; more</p>")
	}

	@Test("Attributes are escaped")
	func escapesAttributes() {
		let node = Markup.tag("div", [Attribute("title", "a \"quoted\" <value>")], [])
		#expect(node.render() == "<div title=\"a &quot;quoted&quot; &lt;value&gt;\"></div>")
	}

	@Test("Coordinates are trimmed", arguments: [
		(50.0, "50"), (0.3333333, "0.333"), (-86.60254, "-86.603"), (100.0, "100")
	])
	func formatsCoordinates(_ value: Double, _ expected: String) {
		#expect(value.svgValue == expected)
	}

	@Test("Large values are grouped for display")
	func formatsDisplayValues() {
		#expect(Double(1024).displayValue == "1,024")
	}
}

// MARK: - Axis

@Suite("Axis")
struct AxisTests {

	/// Dividing the largest value into ten equal parts produced axes labelled
	/// 22, 43, 65, 87 — correct, and impossible to read a value off.
	@Test(
		"The value axis rounds up to readable ticks",
		arguments: [
			(217.0, 250.0, 50.0),
			(300.0, 300.0, 50.0),
			(70.0, 70.0, 10.0),
			(9.0, 10.0, 2.0),
			(8765.0, 10000.0, 2000.0),
			(18420.0, 20000.0, 5000.0)
		]
	)
	func roundsToReadableTicks(_ largest: Double, _ maximum: Double, _ step: Double) {
		let scale = Axis.scale(for: largest)
		#expect(scale.maximum == maximum)
		#expect(scale.step == step)
	}

	@Test("Every tick lands on a whole step")
	func ticksAreWholeSteps() {
		for largest in stride(from: 1.0, through: 5000.0, by: 37.0) {
			let scale = Axis.scale(for: largest)

			#expect(scale.maximum >= largest)
			#expect(scale.tickCount >= 2)
			#expect(scale.tickCount <= 8)

			let top = Double(scale.tickCount - 1) * scale.step
			#expect(abs(top - scale.maximum) < 1e-9)
		}
	}

	@Test("An empty axis still has a scale", arguments: [0.0, -5.0])
	func handlesEmptyAxis(_ largest: Double) {
		let scale = Axis.scale(for: largest)
		#expect(scale.maximum > 0)
		#expect(scale.step > 0)
	}
}
