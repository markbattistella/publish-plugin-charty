//
//  Created by Mark Battistella
//	@markbattistella
//

import Foundation

/// A colour in the OKLCH space.
///
/// The original plugin built its palettes by converting the theme colour to HSL
/// and multiplying lightness by the series index. That ramp ran from 0% to 98%,
/// so the first series was always pure black and the last was always near-white
/// — and because HSL lightness is not perceptually uniform, the steps in between
/// were unevenly spaced. OKLCH fixes both: equal steps in `L` look like equal
/// steps to the eye, and the range can be clamped to values that stay legible.
internal struct Colour: Equatable {

	/// Perceptual lightness, 0...1.
	internal var lightness: Double

	/// Chroma. Unbounded in theory, roughly 0...0.37 in sRGB.
	internal var chroma: Double

	/// Hue angle in degrees, 0..<360.
	internal var hue: Double

	internal init(lightness: Double, chroma: Double, hue: Double) {
		self.lightness = lightness
		self.chroma = chroma
		self.hue = hue
	}
}

// MARK: - Parsing

extension Colour {

	/// The fallback theme, used when no theme is configured or parsing fails.
	internal static let defaultTheme = Colour(lightness: 0.623, chroma: 0.164, hue: 251.5)

	/// Parses a three- or six-digit hex string into OKLCH.
	///
	/// Returns `nil` for anything that is not a hex colour, which lets callers
	/// fall back rather than silently rendering something wrong.
	internal init?(hex: String) {
		var digits = hex.trimmingCharacters(in: .whitespacesAndNewlines)
		digits = digits.hasPrefix("#") ? String(digits.dropFirst()) : digits

		if digits.count == 3 {
			digits = digits.map { "\($0)\($0)" }.joined()
		}

		guard digits.count == 6, digits.allSatisfy(\.isHexDigit) else { return nil }

		func channel(_ offset: Int) -> Double {
			let start = digits.index(digits.startIndex, offsetBy: offset)
			let end = digits.index(start, offsetBy: 2)
			return Double(UInt8(digits[start..<end], radix: 16) ?? 0) / 255
		}

		self = Colour(
			red: channel(0),
			green: channel(2),
			blue: channel(4)
		)
	}

	/// Converts sRGB (0...1 per channel) to OKLCH.
	internal init(red: Double, green: Double, blue: Double) {

		func linear(_ channel: Double) -> Double {
			channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
		}

		let r = linear(red), g = linear(green), b = linear(blue)

		let long = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
		let medium = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
		let short = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

		let l = Foundation.cbrt(long), m = Foundation.cbrt(medium), s = Foundation.cbrt(short)

		let lightness = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
		let a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
		let bAxis = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s

		var hue = atan2(bAxis, a) * 180 / .pi
		if hue < 0 { hue += 360 }

		self.lightness = lightness
		self.chroma = (a * a + bAxis * bAxis).squareRoot()
		self.hue = hue
	}
}

// MARK: - Output

extension Colour {

	/// The CSS `oklch()` representation.
	internal var cssValue: String {
		"oklch(\(lightness.svgValue) \(chroma.svgValue) \(hue.svgValue))"
	}

	/// Whether dark text reads better than light text on top of this colour.
	internal var prefersDarkInk: Bool { lightness > 0.62 }
}

// MARK: - Palettes

/// A generated pair of colours for one data series — one for each colour scheme.
internal struct SeriesColour {

	/// The colour used when the page is in light mode.
	internal let light: String

	/// The colour used when the page is in dark mode.
	internal let dark: String

	/// A CSS value that resolves to the right one automatically.
	///
	/// `light-dark()` removes the need for the old `.dark` class to be toggled
	/// by JavaScript — the browser picks the branch from `color-scheme`.
	internal var cssValue: String {
		light == dark ? light : "light-dark(\(light), \(dark))"
	}

	/// A readable text colour to sit on top of this series colour.
	internal let ink: String
}

extension Colour {

	/// Builds a perceptually even palette of `count` colours from this theme.
	///
	/// Series run darkest-first, which preserves the visual weighting of the
	/// original plugin (the first, usually largest, series reads strongest)
	/// while keeping every step inside a legible lightness range.
	internal func palette(count: Int) -> [SeriesColour] {
		guard count > 0 else { return [] }

		guard count > 1 else {
			let single = ramp(position: 0.5, isDark: false)
			let singleDark = ramp(position: 0.5, isDark: true)
			return [
				SeriesColour(
					light: single.cssValue,
					dark: singleDark.cssValue,
					ink: single.prefersDarkInk ? Self.darkInk : Self.lightInk
				)
			]
		}

		return (0..<count).map { index in
			let position = Double(index) / Double(count - 1)
			let light = ramp(position: position, isDark: false)
			let dark = ramp(position: position, isDark: true)

			return SeriesColour(
				light: light.cssValue,
				dark: dark.cssValue,
				ink: light.prefersDarkInk ? Self.darkInk : Self.lightInk
			)
		}
	}

	/// Ink colours used on top of a filled shape.
	private static let darkInk = "oklch(0.2 0 0)"
	private static let lightInk = "oklch(0.99 0 0)"

	/// Lightness bounds for each colour scheme.
	///
	/// Dark mode sits higher up the scale so that fills keep their separation
	/// against a dark page rather than collapsing into it.
	private static let lightBounds = (start: 0.44, end: 0.80)
	private static let darkBounds = (start: 0.54, end: 0.87)

	/// Produces one step of the ramp.
	///
	/// - Parameters:
	///   - position: 0 for the first series, 1 for the last.
	///   - isDark: Whether this step is for the dark colour scheme.
	private func ramp(position: Double, isDark: Bool) -> Colour {
		let bounds = isDark ? Self.darkBounds : Self.lightBounds

		// Taper chroma towards both ends of the ramp — very light and very dark
		// colours cannot hold full chroma without clipping outside sRGB.
		let taper = 1 - 0.28 * abs(2 * position - 1)

		// A small hue rotation across the ramp gives adjacent series a second
		// cue beyond lightness alone, which helps when they sit side by side.
		let rotation = 16 * (position - 0.5)

		var rotated = hue + rotation
		rotated.formTruncatingRemainder(dividingBy: 360)
		if rotated < 0 { rotated += 360 }

		return Colour(
			lightness: bounds.start + (bounds.end - bounds.start) * position,
			chroma: chroma * taper,
			hue: rotated
		)
	}
}
