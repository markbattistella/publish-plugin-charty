//
//  Created by Mark Battistella
//	@markbattistella
//

import Foundation

/// Which colour scheme charts should render for.
public enum ChartyColourScheme: String, Sendable {
    /// Always use the light palette.
    case light

    /// Always use the dark palette.
    case dark

    /// Follow whatever colour scheme the surrounding page is using.
    ///
    /// This is the default, and it writes no `color-scheme` of its own. Forcing
    /// `light dark` here would resolve every `light-dark()` colour against the
    /// reader's system setting even on a site that only has a light theme, so
    /// a light page would end up with dark-mode charts on it. Inheriting means
    /// the charts match the page they are on.
    case system

    /// The value written to the `color-scheme` property, if any.
    internal var cssValue: String? {
        switch self {
            case .light: return "light"
            case .dark: return "dark"
            case .system: return nil
        }
    }
}

/// Site-wide settings for the Charty plugin.
public struct ChartyConfiguration: Sendable {
    /// The hex colour palettes are generated from.
    public var theme: String

    /// The colour scheme charts render for.
    public var colourScheme: ChartyColourScheme

    /// Whether to print a reason to the build log when a chart cannot be drawn.
    public var isDebugEnabled: Bool

    public init(
        theme: String = "#0984E3",
        colourScheme: ChartyColourScheme = .system,
        isDebugEnabled: Bool = false
    ) {
        self.theme = theme
        self.colourScheme = colourScheme
        self.isDebugEnabled = isDebugEnabled
    }

    /// The theme parsed into OKLCH, falling back to the default on bad input.
    internal var themeColour: Colour {
        Colour(hex: theme) ?? .defaultTheme
    }
}
