//
//  Created by Mark Battistella
//	@markbattistella
//

import Foundation

/// Summary numbers for one row of chart data.
internal struct RowStatistics {

	internal let minimum: Double
	internal let maximum: Double
	internal let sum: Double
	internal let average: Double
}

/// Summary numbers for a whole chart.
///
/// Charts whose series each hold a single number — pie, donut, ring, rating —
/// are summarised as one combined row, so that `sum` means "the total of every
/// slice". Charts whose series hold arrays get one row each.
internal struct ChartStatistics {

	/// One entry per row, in series order.
	internal let rows: [RowStatistics]

	/// The largest single value anywhere in the chart.
	internal let largest: Double

	/// Whether the source data was a list of single values.
	internal let isScalarData: Bool

	internal init(series: [ChartSeries]) {
		let isScalar = series.first?.isScalar ?? false
		self.isScalarData = isScalar

		let grid: [[Double]] = isScalar
			? [series.flatMap(\.values)]
			: series.map(\.values)

		self.rows = grid.map { values in
			guard !values.isEmpty else {
				return RowStatistics(minimum: 0, maximum: 0, sum: 0, average: 0)
			}
			let sum = values.reduce(0, +)
			return RowStatistics(
				minimum: values.min() ?? 0,
				maximum: values.max() ?? 0,
				sum: sum,
				average: sum / Double(values.count)
			)
		}

		self.largest = rows.map(\.maximum).max() ?? 0
	}

	/// The row at `index`, or the first row when the chart has only one.
	internal func row(_ index: Int) -> RowStatistics {
		guard rows.indices.contains(index) else {
			return rows.first ?? RowStatistics(minimum: 0, maximum: 0, sum: 0, average: 0)
		}
		return rows[index]
	}

	/// The scale to divide values by when mapping them onto the canvas.
	///
	/// Guards against the divide-by-zero the original produced whenever every
	/// value in a chart was zero, which rendered `NaN` into the SVG.
	internal var scale: Double { largest > 0 ? largest : 1 }

	/// The total across every value in the chart.
	internal var total: Double { rows.map(\.sum).reduce(0, +) }
}
