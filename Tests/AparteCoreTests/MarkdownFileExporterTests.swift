import Foundation
import XCTest
@testable import AparteCore

final class MarkdownFileExporterTests: XCTestCase {
    func testDraftTitleUsesTheFirstWordsAfterAnEmptyListMarker() {
        for markdown in ["-   \nAda", "7.   \nAda", "- \n- Ada", "# \n\nAda", "- .\n\nAda", "- *\n\nAda"] {
            XCTAssertEqual(MarkdownFileExporter.suggestedBaseName(for: markdown), "Ada")
        }
        XCTAssertEqual(MarkdownFileExporter.suggestedBaseName(for: "- \n7. "), "Aparte")
        XCTAssertEqual(MarkdownFileExporter.suggestedBaseName(for: "7.\nAda"), "7")
        XCTAssertEqual(MarkdownFileExporter.suggestedBaseName(for: "7.  \nAda"), "7")
        XCTAssertEqual(MarkdownFileExporter.suggestedBaseName(for: "-  \nAda"), "-")
        XCTAssertEqual(MarkdownFileExporter.suggestedBaseName(for: "  # \n\nAda"), "#")
    }

    func testSuggestedNameUsesTheFirstHeadingWithoutItsMarkup() {
        XCTAssertEqual(MarkdownFileExporter.suggestedBaseName(for: "# Focused writing\n\nBody"), "Focused writing")
    }

    func testSuggestedNameReplacesPathCharactersAndStaysShort() {
        let name = MarkdownFileExporter.suggestedBaseName(for: String(repeating: "a/b:", count: 40))

        XCTAssertTrue(name.hasPrefix("a-b-a-b-"))
        XCTAssertFalse(name.contains("/"))
        XCTAssertFalse(name.contains(":"))
        XCTAssertEqual(name.count, 80)
    }
}
