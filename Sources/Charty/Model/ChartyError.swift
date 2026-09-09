//
//  Created by Mark Battistella
//	@markbattistella
//

import Foundation

/// A problem found while reading or drawing a chart.
///
/// Charty never throws out of the Markdown pipeline. Errors are surfaced two
/// ways: the offending code block is left untouched in the page so nothing
/// disappears silently, and — when debugging is enabled — the reason is written
/// to standard output during the build.
public enum ChartyError: Error, CustomStringConvertible {
    /// The block did not contain valid JSON.
    case malformedJSON(String)

    /// The `type` key was missing or named a chart that does not exist.
    case unknownType(String)

    /// The chart had no usable data.
    case noData

    /// A radar chart's value count did not match its axis labels.
    case pointCountMismatch(series: String, values: Int, points: Int)

    /// A radar value fell outside the 0–100 range it must sit in.
    case valueOutOfRange(series: String, value: Double)

    /// A grouped bar chart's rows and columns did not form a square matrix.
    case nonSquareMatrix(series: Int, values: Int)

    public var description: String {
        switch self {
            case .malformedJSON(let reason):
                return "the block is not valid JSON — \(reason)"

            case .unknownType(let type):
                return type.isEmpty
                    ? "no \"type\" was given"
                    : "\"\(type)\" is not a chart type Charty knows about"

            case .noData:
                return "the chart has no data to draw"

            case .pointCountMismatch(let series, let values, let points):
                return "\"\(series)\" has \(values) values but the chart declares \(points) points"

            case .valueOutOfRange(let series, let value):
                return "\"\(series)\" has a value of \(value.svgValue); radar values must be between 0 and 100"

            case .nonSquareMatrix(let series, let values):
                return "the chart has \(series) series but \(values) values per series; these must match"
        }
    }
}
