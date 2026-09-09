//
//  Created by Mark Battistella
//	@markbattistella
//

import Foundation
import Testing
@testable import Charty

/// Renders a chart definition the way the Markdown modifier would.
private func render(_ json: String, configuration: ChartyConfiguration = ChartyConfiguration()) -> String? {
	Charty.render(block: Substring("```charty\n\(json)\n```"), configuration: configuration)
}

// MARK: - Contract

@Suite("Rendering")
struct RenderingTests {

	@Test("Every chart type renders", arguments: ChartType.allCases)
	func rendersEveryType(_ type: ChartType) throws {
		let json = """
		{
		  "title": "Example",
		  "type": "\(type.rawValue)",
		  "points": ["A", "B", "C"],
		  "data": [
		    { "label": "First", "value": [30, 45, 25] },
		    { "label": "Second", "value": [20, 35, 45] }
		  ]
		}
		"""

		let html = try #require(render(json))
		#expect(html.hasPrefix("<figure class=\"charty charty--\(type.rawValue)"))
		#expect(html.hasSuffix("</figure>"))
		#expect(!html.contains("NaN"))
		#expect(!html.contains("Infinity"))
		#expect(!html.contains("undefined"))
	}

	@Test("Malformed JSON leaves the block alone")
	func skipsMalformedJSON() {
		#expect(render("{ not json }") == nil)
	}

	@Test("An unknown type leaves the block alone")
	func skipsUnknownType() {
		#expect(render("{ \"type\": \"sunburst\", \"data\": [] }") == nil)
	}

	@Test("A chart with no data leaves the block alone")
	func skipsEmptyData() {
		#expect(render("{ \"type\": \"pie\", \"data\": [] }") == nil)
	}

	/// `options` being absent threw a TypeError in the JavaScript.
	@Test("Options may be omitted entirely")
	func toleratesMissingOptions() throws {
		let html = try #require(render("{ \"type\": \"pie\", \"data\": [{ \"label\": \"A\", \"value\": 1 }] }"))
		#expect(html.contains("charty__legend"))
	}

	/// The README documented these as defaulting to true; the code defaulted
	/// them to false because a missing key is falsy in JavaScript.
	@Test("Legend, labels, and numbers default to on")
	func optionsDefaultToOn() throws {
		let options = try JSONDecoder().decode(ChartOptions.self, from: Data("{}".utf8))
		#expect(options.legend)
		#expect(options.labels)
		#expect(options.numbers)
	}

	@Test("Options can be turned off")
	func honoursDisabledOptions() throws {
		let json = """
		{
		  "type": "pie",
		  "options": { "legend": false, "numbers": false },
		  "data": [{ "label": "A", "value": 1 }, { "label": "B", "value": 2 }]
		}
		"""
		let html = try #require(render(json))
		#expect(!html.contains("charty__legend"))
	}
}

// MARK: - Fixed defects

@Suite("Regressions")
struct RegressionTests {

	/// An arc whose start and end coincide draws nothing, so a pie with one
	/// data point rendered as an empty box.
	@Test("A single slice fills the circle")
	func singleSliceIsACircle() throws {
		let html = try #require(render("""
		{ "type": "pie", "data": [{ "label": "All", "value": 100 }] }
		"""))
		#expect(html.contains("<circle cx=\"50\" cy=\"50\" r=\"50\""))
		#expect(!html.contains("<path"))
	}

	/// Element identifiers inside the SVG were hard-coded, so a second chart on
	/// a page referenced the first chart's filter.
	@Test("Two charts on a page do not share element identifiers")
	func identifiersAreScopedPerChart() throws {
		let first = try #require(render("""
		{ "type": "donut", "data": [{ "label": "A", "value": 1 }, { "label": "B", "value": 2 }] }
		"""))
		let second = try #require(render("""
		{ "type": "donut", "data": [{ "label": "C", "value": 3 }, { "label": "D", "value": 4 }] }
		"""))

		func maskIdentifier(_ html: String) -> String? {
			guard let range = html.range(of: "<mask id=\"") else { return nil }
			return String(html[range.upperBound...].prefix(while: { $0 != "\"" }))
		}

		let a = try #require(maskIdentifier(first))
		let b = try #require(maskIdentifier(second))
		#expect(a != b)
	}

	@Test("Labels cannot inject markup")
	func labelsAreEscaped() throws {
		let html = try #require(render("""
		{
		  "title": "<img src=x onerror=alert(1)>",
		  "type": "pie",
		  "data": [{ "label": "</title><script>alert(1)</script>", "value": 1 }]
		}
		"""))
		#expect(!html.contains("<script"))
		#expect(!html.contains("<img"))
		#expect(html.contains("&lt;script&gt;"))
	}

	/// Every value being zero divided by zero and wrote NaN into the SVG.
	@Test("All-zero data does not produce NaN", arguments: ["bar", "line", "area", "pie", "ring"])
	func handlesAllZeroData(_ type: String) throws {
		let html = try #require(render("""
		{
		  "type": "\(type)",
		  "data": [{ "label": "A", "value": [0, 0] }, { "label": "B", "value": [0, 0] }]
		}
		"""))
		#expect(!html.contains("NaN"))
	}

	@Test("Ring percentages are not floated out")
	func ringPercentagesAreClean() throws {
		let html = try #require(render("""
		{ "type": "rings", "data": [{ "label": "A", "value": 0.76 }] }
		"""))
		#expect(html.contains("76%"))
		#expect(!html.contains("76.00000000000001"))
	}

	@Test("Both spellings of colour are accepted", arguments: ["colour", "color"])
	func acceptsBothColourSpellings(_ key: String) throws {
		let html = try #require(render("""
		{ "type": "pie", "data": [{ "label": "A", "value": 1, "\(key)": "#FF0000" }] }
		"""))
		#expect(html.contains("#FF0000"))
	}

	@Test("A single data object is accepted in place of an array")
	func acceptsSingleDataObject() throws {
		let html = try #require(render("""
		{ "type": "rings", "data": { "label": "Only", "value": 0.5 } }
		"""))
		#expect(html.contains("charty__series"))
	}

	/// Radar axis labels historically lived on the first series.
	@Test("Radar points are read from either location")
	func radarPointsFallBackToFirstSeries() throws {
		let html = try #require(render("""
		{
		  "type": "radar",
		  "data": [{ "label": "A", "points": ["X", "Y", "Z"], "value": [10, 20, 30] }]
		}
		"""))
		#expect(html.contains(">X</text>"))
	}

	@Test("A radar series with the wrong number of values is skipped, not drawn")
	func radarMismatchIsSkipped() throws {
		let html = try #require(render("""
		{
		  "type": "radar",
		  "points": ["X", "Y", "Z"],
		  "data": [{ "label": "Bad", "value": [10, 20] }]
		}
		"""))
		#expect(!html.contains("<polygon"))
	}
}

// MARK: - Accessibility

@Suite("Accessibility")
struct AccessibilityTests {

	@Test("Charts are named for assistive technology")
	func chartsAreLabelled() throws {
		let html = try #require(render("""
		{ "title": "Sales", "caption": "By quarter", "type": "pie",
		  "data": [{ "label": "A", "value": 1 }, { "label": "B", "value": 2 }] }
		"""))
		#expect(html.contains("role=\"img\""))
		#expect(html.contains("aria-labelledby="))
		#expect(html.contains(">Sales</title>"))
		#expect(html.contains(">By quarter</desc>"))
	}

	@Test("An untitled chart still gets a name")
	func untitledChartsAreNamed() throws {
		let html = try #require(render("""
		{ "type": "bubble", "data": [{ "label": "A", "value": [1, 2] }] }
		"""))
		#expect(html.contains(">bubble chart</title>"))
		#expect(!html.contains(">undefined<"))
	}

	@Test("Legend entries can be reached from the keyboard")
	func legendIsFocusable() throws {
		let html = try #require(render("""
		{ "type": "pie", "data": [{ "label": "A", "value": 1 }, { "label": "B", "value": 2 }] }
		"""))
		#expect(html.contains("tabindex=\"0\""))
	}
}

// MARK: - Configuration

@Suite("Configuration")
struct ConfigurationTests {

	@Test("An explicit colour scheme reaches the markup", arguments: [
		(ChartyColourScheme.light, "light"),
		(.dark, "dark")
	])
	func writesColourScheme(_ scheme: ChartyColourScheme, _ expected: String) throws {
		let html = try #require(render(
			"{ \"type\": \"pie\", \"data\": [{ \"label\": \"A\", \"value\": 1 }] }",
			configuration: ChartyConfiguration(colourScheme: scheme)
		))
		#expect(html.contains("color-scheme: \(expected)"))
	}

	/// Forcing "light dark" would resolve every light-dark() colour against the
	/// reader's system setting even on a site that only has a light theme.
	@Test("Following the page writes no colour scheme of its own")
	func systemSchemeInherits() throws {
		let html = try #require(render(
			"{ \"type\": \"pie\", \"data\": [{ \"label\": \"A\", \"value\": 1 }] }",
			configuration: ChartyConfiguration(colourScheme: .system)
		))
		#expect(!html.contains("color-scheme"))
	}

	@Test("A per-chart theme overrides the site theme")
	func perChartThemeWins() throws {
		let html = try #require(render("""
		{
		  "type": "pie",
		  "options": { "theme": "#FF0000" },
		  "data": [{ "label": "A", "value": 1 }, { "label": "B", "value": 2 }]
		}
		""", configuration: ChartyConfiguration(theme: "#0984E3")))

		// Red sits near 29 degrees in OKLCH; the site's blue is near 250.
		#expect(html.contains("oklch(0.44 0.1"))
		#expect(!html.contains("250.569"))
	}

	@Test("An unparseable theme falls back to the default")
	func badThemeFallsBack() throws {
		let html = try #require(render(
			"{ \"type\": \"pie\", \"data\": [{ \"label\": \"A\", \"value\": 1 }] }",
			configuration: ChartyConfiguration(theme: "not-a-colour")
		))
		#expect(html.contains("oklch("))
	}

	@Test("The bundled stylesheet is readable")
	func stylesheetIsAvailable() {
		#expect(Charty.stylesheet.contains(".charty__svg"))

		// A cascade layer would lose to a host theme's unlayered
		// `* { font-size: inherit }`, which resizes every SVG label.
		#expect(!Charty.stylesheet.contains("@layer"))
	}
}
