//
//  Created by Mark Battistella
//	@markbattistella
//

import Foundation
import Charty
import Ink
import Plot
import Publish

/// The Charty documentation site.
///
/// It mirrors the docsify-charty documentation page for page and chart for
/// chart, so the two plugins can be compared side by side.
struct ChartyDocs: Website {
    var url =
        ProcessInfo.processInfo.environment["CHARTY_DOCS_URL"]
        .flatMap(URL.init(string:))
        ?? URL(string: "https://charty.publish.markbattistella.com")!
    var name = "publish-plugin-charty"
    var description = "Add some charts to your life"
    var language: Language { .english }
    var imagePath: Path? { nil }

    enum SectionID: String, WebsiteSectionID {
        case charts
    }

    /// Chart pages declare which group they belong to in the sidebar, and where
    /// they sit within it.
    struct ItemMetadata: WebsiteItemMetadata {
        var group: String
        var order: String
    }
}

// MARK: - scrollable tables
extension Plugin {
    /// Wraps every table in a scroll container.
    ///
    /// The reference tables carry a long description column. Left to itself a
    /// table narrower than its content squeezes that column to one word per
    /// line on a phone; given a container to scroll inside, the columns keep
    /// a readable width instead.
    static func scrollableTables() -> Self {
        Plugin(name: "Scrollable tables") { context in
            context.markdownParser.addModifier(
                Modifier(target: .tables) { html, _ in
                    "<div class=\"table-scroll\">\(html)</div>"
                }
            )
        }
    }
}

// MARK: - generate the website
try ChartyDocs().publish(
    withTheme: .docs,
    plugins: [
        .charty(theme: "#F05138", debug: true),
        .scrollableTables(),
    ]
)
