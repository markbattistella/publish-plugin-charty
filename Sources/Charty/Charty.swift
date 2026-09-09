//
//  Created by Mark Battistella
//	@markbattistella
//

import Foundation
import Ink
import Plot
import Publish

/// Charty turns fenced ```` ```charty ```` blocks into inline SVG charts.
public enum Charty {

	/// The language tag a code block must carry to be treated as a chart.
	public static let language = "charty"

	/// The stylesheet the generated markup expects.
	///
	/// Exposed so that a site can inline it rather than serve it as a file.
	public static var stylesheet: String {
		guard
			let url = Bundle.module.url(forResource: "charty", withExtension: "css"),
			let contents = try? String(contentsOf: url, encoding: .utf8)
		else {
			return ""
		}
		return contents
	}
}

// MARK: - Plugin

public extension Plugin {

	/// Installs Charty into a Publish site.
	///
	/// - Parameters:
	///   - theme: The hex colour series palettes are generated from.
	///   - colourScheme: Which colour scheme charts should render for. The
	///     default follows the reader's system setting with no JavaScript.
	///   - stylesheetPath: Where to write Charty's stylesheet within the output
	///     folder. Pass `nil` to skip it and inline `Charty.stylesheet` instead.
	///   - debug: Whether to report unusable charts during the build.
	static func charty(
		theme: String = "#0984E3",
		colourScheme: ChartyColourScheme = .system,
		stylesheetPath: Path? = "charty.css",
		debug: Bool = false
	) -> Self {

		let configuration = ChartyConfiguration(
			theme: theme,
			colourScheme: colourScheme,
			isDebugEnabled: debug
		)

		return Plugin(name: "Charty") { context in
			context.markdownParser.addModifier(.charty(configuration: configuration))

			guard let stylesheetPath else { return }

			let stylesheet = Charty.stylesheet
			guard !stylesheet.isEmpty else {
				throw ChartyInstallationError.missingStylesheet
			}

			let file = try context.createOutputFile(at: stylesheetPath)
			try file.write(stylesheet)
		}
	}
}

/// A problem installing the plugin, as opposed to drawing a chart.
public enum ChartyInstallationError: Error, CustomStringConvertible {

	/// Charty's bundled stylesheet could not be read.
	case missingStylesheet

	public var description: String {
		"Charty could not read its bundled stylesheet from the module bundle"
	}
}

// MARK: - Modifier

public extension Modifier {

	/// A Markdown modifier that renders ```` ```charty ```` blocks.
	///
	/// Use this directly when installing Charty into a parser by hand; the
	/// `charty` plugin does it for you.
	static func charty(configuration: ChartyConfiguration = ChartyConfiguration()) -> Self {
		Modifier(target: .codeBlocks) { html, markdown in
			Charty.render(block: markdown, configuration: configuration) ?? html
		}
	}
}

// MARK: - Rendering

extension Charty {

	/// Renders a fenced code block, or returns `nil` to leave it alone.
	internal static func render(block: Substring, configuration: ChartyConfiguration) -> String? {

		guard let body = chartBody(in: block) else { return nil }

		let spec: ChartSpec
		do {
			spec = try JSONDecoder().decode(ChartSpec.self, from: Data(body.utf8))
		} catch let error as ChartyError {
			report(error, configuration: configuration)
			return nil
		} catch {
			report(.malformedJSON(error.localizedDescription), configuration: configuration)
			return nil
		}

		guard !spec.data.isEmpty else {
			report(.noData, configuration: configuration)
			return nil
		}

		let context = RenderContext(
			spec: spec,
			configuration: configuration,
			identifier: identifier(for: body)
		)

		let chart = renderer(for: spec.type).render(in: context)

		for message in context.warnings.messages where configuration.isDebugEnabled {
			print("[Charty] \(message)")
		}

		return ChartAssembler(context: context, chart: chart).assemble().render()
	}

	/// Picks the renderer for a chart type.
	private static func renderer(for type: ChartType) -> ChartRenderer {
		switch type {
			case .radar: return RadarRenderer()
			case .area: return AreaRenderer()
			case .pie, .donut, .section: return CircleRenderer()
			case .ring: return RingRenderer()
			case .plot, .line, .bubble: return PlotRenderer()
			case .bar, .column, .barStack, .columnStack: return BarRenderer()
			case .rating: return RatingRenderer()
		}
	}

	/// Writes a reason to the build log, when debugging is turned on.
	private static func report(_ error: ChartyError, configuration: ChartyConfiguration) {
		guard configuration.isDebugEnabled else { return }
		print("[Charty] Skipped a chart: \(error.description)")
	}
}

// MARK: - Block parsing

extension Charty {

	/// Extracts the body of a ```` ```charty ```` block.
	///
	/// Ink hands modifiers the raw Markdown of the fragment, fences included,
	/// so the language tag and the surrounding fences are stripped here.
	internal static func chartBody(in block: Substring) -> String? {

		var lines = block.split(separator: "\n", omittingEmptySubsequences: false)

		guard let first = lines.first else { return nil }

		let opening = first.trimmingCharacters(in: .whitespaces)
		guard opening.hasPrefix("```") || opening.hasPrefix("~~~") else { return nil }

		let tag = opening
			.drop(while: { $0 == "`" || $0 == "~" })
			.trimmingCharacters(in: .whitespaces)
			.lowercased()

		guard tag == language else { return nil }

		lines.removeFirst()

		if let last = lines.last {
			let closing = last.trimmingCharacters(in: .whitespaces)
			if closing.hasPrefix("```") || closing.hasPrefix("~~~") || closing.isEmpty {
				lines.removeLast()
			}
		}

		let body = lines.joined(separator: "\n")
		return body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : body
	}

	/// A short, stable identifier derived from a chart's contents.
	///
	/// Element identifiers inside the SVG — the label backdrop filter, the
	/// donut mask — must be unique per page. The original hard-coded them, so
	/// a second chart on a page silently referenced the first chart's filter.
	/// Swift's own hashing is seeded per process, so this uses FNV-1a to stay
	/// stable between builds. It runs over UTF-16 code units at 32 bits so that
	/// the JavaScript port derives exactly the same identifier for the same
	/// chart, which is what lets the two be diffed against each other.
	internal static func identifier(for body: String) -> String {
		var hash: UInt32 = 0x811c_9dc5

		for unit in body.utf16 {
			hash ^= UInt32(unit & 0xFFFF)
			hash = hash &* 0x0100_0193
		}

		return "charty-" + String(hash, radix: 36)
	}
}

// MARK: - Theme support

public extension Node where Context: HTMLContext {

	/// Links Charty's stylesheet from a site's `<head>`.
	///
	/// - Parameter path: Where the plugin was told to write the stylesheet.
	static func chartyStylesheet(at path: Path = "charty.css") -> Node {
		.element(named: "link", attributes: [
			.attribute(named: "rel", value: "stylesheet"),
			.attribute(named: "href", value: path.absoluteString)
		])
	}
}
