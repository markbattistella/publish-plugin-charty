//
//  Created by Mark Battistella
//	@markbattistella
//

import Charty
import Foundation
import Plot
import Publish

extension Theme where Site == ChartyDocs {

	/// The documentation theme: a navigation column and a reading column.
	static var docs: Self {
		Theme(htmlFactory: DocsHTMLFactory())
	}
}

// MARK: - Factory

private struct DocsHTMLFactory: HTMLFactory {

	typealias Site = ChartyDocs

	func makeIndexHTML(for index: Index, context: PublishingContext<Site>) throws -> HTML {
		page(title: context.site.name, context: context, body: .group([
			.header(
				.class("page__header"),
				.p(.class("page__eyebrow"), .text("Publish plugin")),
				.h1(.class("page__title"), .text("Charty")),
				.p(.class("page__lede"), .text(context.site.description))
			),
			.div(.class("prose"), .contentBody(index.body)),
			gallery(for: context)
		]))
	}

	func makeItemHTML(for item: Item<Site>, context: PublishingContext<Site>) throws -> HTML {
		let charts = context.orderedCharts
		let position = charts.firstIndex { $0.path == item.path }

		return page(title: item.title, context: context, selected: item.path, body: .group([
			.header(
				.class("page__header"),
				.p(.class("page__eyebrow"), .text(item.metadata.group)),
				.h1(.class("page__title"), .text(item.title))
			),
			.div(.class("prose"), .contentBody(item.body)),
			pager(
				previous: position.flatMap { $0 > 0 ? charts[$0 - 1] : nil },
				next: position.flatMap { $0 < charts.count - 1 ? charts[$0 + 1] : nil }
			)
		]))
	}

	func makeSectionHTML(for section: Section<Site>, context: PublishingContext<Site>) throws -> HTML {
		page(title: "Charts", context: context, body: .group([
			.header(
				.class("page__header"),
				.p(.class("page__eyebrow"), .text("Reference")),
				.h1(.class("page__title"), .text("Every chart type"))
			),
			gallery(for: context)
		]))
	}

	func makePageHTML(for page: Page, context: PublishingContext<Site>) throws -> HTML {
		self.page(title: page.title, context: context, body: .group([
			.header(.class("page__header"), .h1(.class("page__title"), .text(page.title))),
			.div(.class("prose"), .contentBody(page.body))
		]))
	}

	func makeTagListHTML(for page: TagListPage, context: PublishingContext<Site>) throws -> HTML? { nil }

	func makeTagDetailsHTML(for page: TagDetailsPage, context: PublishingContext<Site>) throws -> HTML? { nil }
}

// MARK: - Shell

private extension DocsHTMLFactory {

	func page(
		title: String,
		context: PublishingContext<Site>,
		selected: Path? = nil,
		body: Node<HTML.BodyContext>
	) -> HTML {
		HTML(
			.lang(context.site.language),
			.head(
				.encoding(.utf8),
				.title(title == context.site.name ? title : "\(title) · Charty"),
				.description(context.site.description),
				.viewport(.accordingToDevice),
				.stylesheet("/docs.css"),
				.chartyStylesheet()
			),
			.body(
				.a(.class("skip"), .href("#main"), .text("Skip to content")),
				.div(
					.class("shell"),
					sidebar(for: context, selected: selected),
					.main(.id("main"), .class("main"), .article(.class("page"), body))
				)
			)
		)
	}

	/// The navigation column.
	func sidebar(for context: PublishingContext<Site>, selected: Path?) -> Node<HTML.BodyContext> {
		.aside(
			.class("sidebar"),
			.a(
				.class("brand"),
				.href("/"),
				.span(.class("brand__name"), .text("Charty")),
				.span(.class("brand__kind"), .text("for Publish"))
			),
			.nav(
				.class("nav"),
				.attribute(named: "aria-label", value: "Chart types"),
				.forEach(context.chartGroups) { group in
					.section(
						.class("nav__group"),
						.h2(.class("nav__heading"), .text(group.name)),
						.ul(.forEach(group.items) { item in
							.li(.a(
								.class(item.path == selected ? "nav__link is-current" : "nav__link"),
								.href(item.path),
								.text(item.title)
							))
						})
					)
				}
			),
			.p(
				.class("sidebar__footer"),
				.a(.href("https://github.com/markbattistella/publish-plugin-charty"), .text("Source")),
				.a(.href("https://github.com/markbattistella/docsify-charty"), .text("docsify port"))
			)
		)
	}

	/// A grid of every chart type, used on the index.
	func gallery(for context: PublishingContext<Site>) -> Node<HTML.BodyContext> {
		.section(
			.class("gallery"),
			.h2(.class("gallery__heading"), .text("Chart types")),
			.div(
				.class("gallery__grid"),
				.forEach(context.orderedCharts) { item in
					.a(
						.class("card"),
						.href(item.path),
						.span(.class("card__group"), .text(item.metadata.group)),
						.span(.class("card__title"), .text(item.title))
					)
				}
			)
		)
	}

	/// Links to the previous and next chart, so the set can be read in order.
	func pager(previous: Item<Site>?, next: Item<Site>?) -> Node<HTML.BodyContext> {
		guard previous != nil || next != nil else { return .empty }

		return .nav(
			.class("pager"),
			.attribute(named: "aria-label", value: "Chart navigation"),
			previous.map { item in
				.a(
					.class("pager__link pager__link--previous"),
					.href(item.path),
					.span(.class("pager__direction"), .text("Previous")),
					.span(.class("pager__title"), .text(item.title))
				)
			} ?? .empty,
			next.map { item in
				.a(
					.class("pager__link pager__link--next"),
					.href(item.path),
					.span(.class("pager__direction"), .text("Next")),
					.span(.class("pager__title"), .text(item.title))
				)
			} ?? .empty
		)
	}
}

// MARK: - Grouping

/// A named run of chart pages, as shown in the navigation column.
struct ChartGroup {

	let name: String
	let items: [Item<ChartyDocs>]
}

extension PublishingContext where Site == ChartyDocs {

	/// Chart pages in the order their authors gave them.
	var orderedCharts: [Item<Site>] {
		sections[.charts].items.sorted {
			(Int($0.metadata.order) ?? 0) < (Int($1.metadata.order) ?? 0)
		}
	}

	/// The same pages, gathered under their group name.
	var chartGroups: [ChartGroup] {
		var names: [String] = []
		var grouped: [String: [Item<Site>]] = [:]

		for item in orderedCharts {
			let name = item.metadata.group
			if grouped[name] == nil { names.append(name) }
			grouped[name, default: []].append(item)
		}

		return names.map { ChartGroup(name: $0, items: grouped[$0] ?? []) }
	}
}
