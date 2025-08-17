import Foundation
import Logging
import Markdown
import Path

struct MarkdownComponent {
    let content: String
    let style: MarkdownStyle
    let theme: Theme
    let terminal: Terminaling
    let renderer: Rendering
    let standardPipelines: StandardPipelines
    let logger: Logger?
    
    func run() {
        let document = Document(parsing: content)

        // Helper function to extract row data from a table element
        func extractRowData(from element: any Markup) -> [String] {
            var cellData: [String] = []
            
            // Try to extract cell data by iterating through children
            for i in 0..<element.childCount {
                if let cell = element.child(at: i) {
                    // Extract text using a simple text extraction
                    let cellText = extractTextFromElement(cell)
                    if !cellText.isEmpty {
                        cellData.append(cellText)
                    }
                }
            }
            
            return cellData
        }
        
        // Helper function to extract text from any markup element
        func extractTextFromElement(_ element: any Markup) -> String {
            var text = ""
            
            // Extract text recursively from children
            for i in 0..<element.childCount {
                if let child = element.child(at: i) {
                    text += extractTextFromElement(child)
                }
            }
            
            // If no children, try to get text representation
            if text.isEmpty {
                let description = String(describing: element)
                // Extract text from the description - this is a fallback
                if description.contains("text: \"") {
                    let components = description.components(separatedBy: "text: \"")
                    if components.count > 1 {
                        let textPart = components[1].components(separatedBy: "\"")[0]
                        text = textPart
                    }
                }
            }
            
            return text
        }
        
        var markdownRenderer = MarkdownRenderer(
            terminal: terminal,
            theme: theme,
            style: style
        )
        
        let formattedContent = markdownRenderer.render(document)
        let output = formattedContent.formatted(theme: theme, terminal: terminal)
        
        if style.margins > 0 {
            let margin = String(repeating: " ", count: style.margins)
            for line in output.split(separator: "\n", omittingEmptySubsequences: false) {
                standardPipelines.output.write(content: margin + String(line) + "\n")
            }
        } else {
            standardPipelines.output.write(content: output)
        }
        
        logger?.debug("Rendered markdown with \(document.childCount) top-level elements")
    }
    
    static func fromFile(
        path: String,
        style: MarkdownStyle,
        theme: Theme,
        terminal: Terminaling,
        renderer: Rendering,
        standardPipelines: StandardPipelines,
        logger: Logger?
    ) throws -> MarkdownComponent {
        let absolutePath = try AbsolutePath(validating: path)
        guard FileManager.default.fileExists(atPath: absolutePath.pathString) else {
            throw MarkdownError.fileNotFound(path)
        }
        
        let content = try String(contentsOfFile: absolutePath.pathString, encoding: .utf8)
        
        return MarkdownComponent(
            content: content,
            style: style,
            theme: theme,
            terminal: terminal,
            renderer: renderer,
            standardPipelines: standardPipelines,
            logger: logger
        )
    }
}

enum MarkdownError: Error, CustomStringConvertible {
    case fileNotFound(String)
    
    var description: String {
        switch self {
        case .fileNotFound(let path):
            return "Markdown file not found: \(path)"
        }
    }
}
