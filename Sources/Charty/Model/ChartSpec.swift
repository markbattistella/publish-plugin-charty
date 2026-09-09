//
//  Created by Mark Battistella
//	@markbattistella
//

import Foundation

/// One series of data within a chart.
public struct ChartSeries: Decodable, Sendable {
    /// The name shown in the legend and against the axis.
    public var label: String

    /// The series values, always normalised to an array.
    public var values: [Double]

    /// Whether the source JSON gave a single number rather than an array.
    public var isScalar: Bool

    /// An explicit colour, overriding the generated palette.
    public var colour: String?

    /// Axis labels, used by `radar`. Historically these lived on the first series.
    public var points: [String]?

    private enum CodingKeys: String, CodingKey {
        case label, value, colour, color, points
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        self.points = try container.decodeIfPresent([String].self, forKey: .points)

        // Both spellings are accepted; the original plugin rewrote `color` to
        // `colour` with a string replacement before parsing.
        self.colour =
            try container.decodeIfPresent(String.self, forKey: .colour)
            ?? container.decodeIfPresent(String.self, forKey: .color)

        if let single = try? container.decode(Double.self, forKey: .value) {
            self.values = [single]
            self.isScalar = true
        }
        else {
            self.values = try container.decodeIfPresent([Double].self, forKey: .value) ?? []
            self.isScalar = false
        }
    }

    internal init(
        label: String,
        values: [Double],
        isScalar: Bool = false,
        colour: String? = nil,
        points: [String]? = nil
    ) {
        self.label = label
        self.values = values
        self.isScalar = isScalar
        self.colour = colour
        self.points = points
    }
}

/// Per-chart display options.
public struct ChartOptions: Decodable, Sendable {
    /// A theme colour for this chart alone, overriding the site-wide theme.
    public var theme: String?

    /// Whether to draw the legend. Defaults to `true`.
    public var legend: Bool

    /// Whether to draw axis and series labels. Defaults to `true`.
    public var labels: Bool

    /// Whether to draw the numeric values. Defaults to `true`.
    public var numbers: Bool

    private enum CodingKeys: String, CodingKey {
        case theme, legend, labels, numbers
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // The README has always documented these as defaulting to true. The
        // JavaScript defaulted them to false whenever the key was absent,
        // because `undefined` is falsy — this follows the documentation.
        self.theme = try container.decodeIfPresent(String.self, forKey: .theme)
        self.legend = try container.decodeIfPresent(Bool.self, forKey: .legend) ?? true
        self.labels = try container.decodeIfPresent(Bool.self, forKey: .labels) ?? true
        self.numbers = try container.decodeIfPresent(Bool.self, forKey: .numbers) ?? true
    }

    public init(theme: String? = nil, legend: Bool = true, labels: Bool = true, numbers: Bool = true) {
        self.theme = theme
        self.legend = legend
        self.labels = labels
        self.numbers = numbers
    }
}

/// A decoded `charty` code block.
public struct ChartSpec: Decodable, Sendable {
    /// The heading shown above the chart.
    public var title: String?

    /// The sub-heading shown beneath the title.
    public var caption: String?

    /// The kind of chart to draw.
    public var type: ChartType

    /// Display options.
    public var options: ChartOptions

    /// The data series.
    public var data: [ChartSeries]

    /// Axis labels for `radar`, when given at the top level.
    public var points: [String]?

    private enum CodingKeys: String, CodingKey {
        case title, caption, type, options, data, points
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.caption = try container.decodeIfPresent(String.self, forKey: .caption)
        self.points = try container.decodeIfPresent([String].self, forKey: .points)

        let rawType = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        guard let type = ChartType(alias: rawType) else {
            throw ChartyError.unknownType(rawType)
        }
        self.type = type

        // `options` being absent is fine; the JavaScript threw a TypeError.
        self.options =
            try container.decodeIfPresent(ChartOptions.self, forKey: .options)
            ?? ChartOptions()

        // A single object is accepted in place of an array of one.
        if let series = try? container.decode([ChartSeries].self, forKey: .data) {
            self.data = series
        }
        else if let single = try? container.decode(ChartSeries.self, forKey: .data) {
            self.data = [single]
        }
        else {
            self.data = []
        }
    }

    /// The radar axis labels, preferring the top level and falling back to the
    /// first series for backwards compatibility.
    internal var resolvedPoints: [String] {
        points ?? data.first?.points ?? []
    }
}
