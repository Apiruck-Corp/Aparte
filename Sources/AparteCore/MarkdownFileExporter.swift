import Foundation

public enum MarkdownFileExporter {
    public static func suggestedBaseName(for markdown: String) -> String {
        let lines = markdown.split(whereSeparator: \Character.isNewline)
        let titles = lines.lazy.map { line in
            line.replacingOccurrences(of: #"^\s*(#{1,6}|[-*+]|[0-9]+\.)\s+"#,
                                      with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
        }
        guard var name = titles.first(where: { !$0.isEmpty }) else {
            return "Aparte"
        }
        for marker in ["**", "__", "*", "_", "`", "<u>", "</u>"] {
            name = name.replacingOccurrences(of: marker, with: "")
        }
        name = name.replacingOccurrences(of: "/", with: "-")
        name = name.replacingOccurrences(of: ":", with: "-")
        name = name.components(separatedBy: .controlCharacters).joined()
        name = name.split(whereSeparator: \Character.isWhitespace).joined(separator: " ")
        name = String(name.prefix(80)).trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        return name.isEmpty ? "Aparte" : name
    }
}
