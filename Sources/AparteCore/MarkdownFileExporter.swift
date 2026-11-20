import Foundation

public enum MarkdownFileExporter {
    public static func suggestedBaseName(for markdown: String) -> String {
        let lines = markdown.split(omittingEmptySubsequences: false, whereSeparator: \Character.isNewline)
        for index in lines.indices where !lines[index].isEmpty {
            let next = index + 1 < lines.count ? lines[index + 1] : nil
            let name = cleanName(MarkdownCodec.lineContent(lines[index], followedBy: next))
            if !name.isEmpty { return name }
        }
        return "Aparte"
    }

    private static func cleanName(_ content: String) -> String {
        var name = content
        for marker in ["**", "__", "*", "_", "`", "<u>", "</u>"] {
            name = name.replacingOccurrences(of: marker, with: "")
        }
        name = name.replacingOccurrences(of: "/", with: "-")
        name = name.replacingOccurrences(of: ":", with: "-")
        name = name.components(separatedBy: .controlCharacters).joined()
        name = name.split(whereSeparator: \Character.isWhitespace).joined(separator: " ")
        return String(name.prefix(80)).trimmingCharacters(in: CharacterSet(charactersIn: ". "))
    }
}
