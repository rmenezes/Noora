import Foundation
import Markdown
import Rainbow

typealias MarkdownTable = Markdown.Table

struct MarkdownRenderer: MarkupWalker {
    private let terminal: Terminaling
    private let theme: Theme
    private let style: MarkdownStyle
    private var output: [TerminalText.Component] = []
    private var listDepth = 0
    
    // Callback for table rendering
    var tableRenderer: ((MarkdownTable) -> Void)?
    private var orderedListCounters: [Int: Int] = [:]
    private var isInCodeBlock = false
    private var isInBlockquote = false
    
    private var effectiveWidth: Int {
        let terminalWidth = terminal.size()?.columns ?? 80
        let availableWidth = terminalWidth - (style.margins * 2)
        if let maxWidth = style.maxWidth {
            return min(availableWidth, maxWidth)
        }
        return availableWidth
    }
    
    init(terminal: Terminaling, theme: Theme, style: MarkdownStyle, tableRenderer: ((MarkdownTable) -> Void)? = nil) {
        self.terminal = terminal
        self.theme = theme
        self.style = style
        self.tableRenderer = tableRenderer
    }
    
    mutating func render(_ document: Document) -> TerminalText {
        output = []
        visit(document)
        return TerminalText(components: output)
    }
    
    // MARK: - Block Elements
    
    mutating func visitHeading(_ heading: Heading) {
        let level = heading.level
        let text = heading.plainText
        
        switch level {
        case 1:
            output.append(.raw("\n"))
            output.append(.primary(text.uppercased()))
            if style.headerUnderline {
                output.append(.raw("\n"))
                output.append(.primary(String(repeating: "═", count: min(text.count, effectiveWidth))))
            }
        case 2:
            output.append(.raw("\n"))
            output.append(.secondary(text))
            if style.headerUnderline {
                output.append(.raw("\n"))
                output.append(.secondary(String(repeating: "─", count: min(text.count, effectiveWidth))))
            }
        case 3:
            output.append(.raw("\n"))
            output.append(.accent("### " + text))
        case 4:
            output.append(.raw("\n"))
            output.append(.info("#### " + text))
        case 5:
            output.append(.raw("\n"))
            output.append(.muted("##### " + text))
        default:
            output.append(.raw("\n"))
            output.append(.muted("###### " + text))
        }
        output.append(.raw("\n"))
    }
    
    mutating func visitParagraph(_ paragraph: Paragraph) {
        // Skip paragraph wrapper in list items (handled by visitListItem)
        if listDepth > 0 {
            return
        }
        
        if !output.isEmpty && !output.last!.isNewline {
            output.append(.raw("\n"))
        }
        
        let indent = String(repeating: " ", count: calculateCurrentIndent())
        if !indent.isEmpty {
            output.append(.raw(indent))
        }
        
        descendInto(paragraph)
        output.append(.raw("\n"))
    }
    
    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        output.append(.raw("\n"))
        
        let indent = String(repeating: " ", count: style.codeBlockIndent)
        let language = codeBlock.language ?? ""
        
        if !language.isEmpty {
            output.append(.muted(indent + "```" + language))
            output.append(.raw("\n"))
        }
        
        // Apply syntax highlighting if language is specified and terminal supports colors
        if !language.isEmpty && terminal.isColored {
            let highlighter = SyntaxHighlighter(theme: theme, terminal: terminal)
            let highlightedComponents = highlighter.highlight(code: codeBlock.code, language: language)
            
            // Apply indentation to each line
            var isFirstLine = true
            for component in highlightedComponents {
                if case .raw(let text) = component, text.contains("\n") {
                    // Handle multi-line raw text by adding indentation after each newline
                    let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
                    for (index, line) in lines.enumerated() {
                        if index > 0 || !isFirstLine {
                            output.append(.raw("\n" + indent))
                        } else if isFirstLine {
                            output.append(.raw(indent))
                            isFirstLine = false
                        }
                        if !line.isEmpty {
                            output.append(.raw(String(line)))
                        }
                    }
                } else {
                    if isFirstLine {
                        output.append(.raw(indent))
                        isFirstLine = false
                    }
                    output.append(component)
                }
            }
        } else {
            fallbackCodeRendering(codeBlock, indent: indent)
        }
        
        if !language.isEmpty {
            output.append(.raw("\n"))
            output.append(.muted(indent + "```"))
        }
        output.append(.raw("\n"))
    }
    
    private mutating func fallbackCodeRendering(_ codeBlock: CodeBlock, indent: String) {
        // Fallback to unhighlighted code
        let lines = codeBlock.code.split(separator: "\n", omittingEmptySubsequences: false)
        for (index, line) in lines.enumerated() {
            if style.showCodeLineNumbers {
                let lineNumber = String(format: "%3d │ ", index + 1)
                output.append(.muted(indent + lineNumber))
            } else {
                output.append(.raw(indent))
            }
            output.append(.info(String(line)))
            if index < lines.count - 1 {
                output.append(.raw("\n"))
            }
        }
    }
    
    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        output.append(.raw("\n"))
        isInBlockquote = true
        
        let indent = String(repeating: " ", count: style.blockquoteIndent)
        let originalOutput = output
        output = []
        
        descendInto(blockQuote)
        
        let quotedContent = TerminalText(components: output).plain()
        output = originalOutput
        
        let lines = quotedContent.split(separator: "\n", omittingEmptySubsequences: false)
        for (index, line) in lines.enumerated() {
            output.append(.muted(indent + "│ "))
            output.append(.raw(String(line)))
            // Don't add extra newline for the last line if it's empty
            if index < lines.count - 1 || !line.isEmpty {
                output.append(.raw("\n"))
            }
        }
        
        isInBlockquote = false
    }
    
    mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        if listDepth == 0 && !output.isEmpty {
            output.append(.raw("\n"))
        }
        listDepth += 1
        descendInto(unorderedList)
        listDepth -= 1
    }
    
    mutating func visitOrderedList(_ orderedList: OrderedList) {
        if listDepth == 0 && !output.isEmpty {
            output.append(.raw("\n"))
        }
        listDepth += 1
        orderedListCounters[listDepth] = Int(orderedList.startIndex)
        descendInto(orderedList)
        orderedListCounters[listDepth] = nil
        listDepth -= 1
    }
    
    mutating func visitListItem(_ listItem: ListItem) {
        let indent = String(repeating: " ", count: (listDepth - 1) * style.listIndent)
        output.append(.raw(indent))
        
        if let counter = orderedListCounters[listDepth] {
            output.append(.accent("\(counter). "))
            orderedListCounters[listDepth] = counter + 1
        } else {
            output.append(.accent("• "))
        }
        
        // Process children, handling nested lists specially
        var hasNestedList = false
        for child in listItem.children {
            if child is Paragraph {
                // Handle paragraph content inline
                for inlineChild in child.children {
                    visit(inlineChild)
                }
            } else if child is UnorderedList || child is OrderedList {
                // Nested list - add newline before processing
                output.append(.raw("\n"))
                visit(child)
                hasNestedList = true
            } else {
                visit(child)
            }
        }
        
        // Only add newline if we haven't already added one for nested lists
        if !hasNestedList {
            output.append(.raw("\n"))
        }
    }
    
    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) {
        output.append(.raw("\n"))
        let line = String(repeating: "─", count: min(effectiveWidth, 40))
        output.append(.muted(line))
        output.append(.raw("\n"))
    }
    
    // MARK: - Inline Elements
    
    mutating func visitText(_ text: Text) {
        output.append(.raw(text.string))
    }
    
    mutating func visitStrong(_ strong: Strong) {
        let text = strong.plainText
        if terminal.isColored {
            output.append(.raw(text.bold))
        } else {
            output.append(.raw("**\(text)**"))
        }
    }
    
    mutating func visitEmphasis(_ emphasis: Emphasis) {
        let text = emphasis.plainText
        if terminal.isColored {
            output.append(.raw(text.italic))
        } else {
            output.append(.raw("_\(text)_"))
        }
    }
    
    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        output.append(.secondary("`\(inlineCode.code)`"))
    }
    
    mutating func visitLink(_ link: Link) {
        let title = link.plainText
        if let destination = link.destination {
            output.append(.link(title: title, href: destination))
        } else {
            output.append(.secondary(title))
        }
    }
    
    mutating func visitImage(_ image: Image) {
        let alt = image.plainText
        if let source = image.source {
            output.append(.muted("[Image: \(alt.isEmpty ? source : alt)]"))
        } else {
            output.append(.muted("[Image: \(alt)]"))
        }
    }
    
    mutating func visitLineBreak(_ lineBreak: LineBreak) {
        output.append(.raw("\n"))
    }
    
    mutating func visitSoftBreak(_ softBreak: SoftBreak) {
        output.append(.raw(" "))
    }
    
    mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        let text = strikethrough.plainText
        output.append(.muted("~~\(text)~~"))
    }
    
    // MARK: - Tables
    
    mutating func visitTable(_ table: MarkdownTable) {
        // If we have a table renderer callback, use it
        if let tableRenderer = tableRenderer {
            tableRenderer(table)
            return
        }
        
        // Use Noora's TableRenderer to create proper table formatting
        output.append(.raw("\n"))
        
        var headers: [String] = []
        var rows: [[String]] = []
        
        // Parse the table structure using child(at:) method
        for i in 0..<table.childCount {
            if let child = table.child(at: i) {
                let childType = String(describing: type(of: child))
                
                if childType.contains("Head") {
                    // Extract headers by getting the first row data
                    headers = extractTableRowData(from: child)
                } else if childType.contains("Body") {
                    // Extract all rows from the body
                    for j in 0..<child.childCount {
                        if let bodyChild = child.child(at: j) {
                            let rowData = extractTableRowData(from: bodyChild)
                            if !rowData.isEmpty {
                                rows.append(rowData)
                            }
                        }
                    }
                }
            }
        }
        
        // Use Noora's TableRenderer for proper table formatting
        if !headers.isEmpty {
            renderTableUsingNooraRenderer(headers: headers, rows: rows)
        }
        
        output.append(.raw("\n"))
    }
    
    // Helper method to extract row data from table elements
    private func extractTableRowData(from element: any Markup) -> [String] {
        var cellData: [String] = []
        
        // Try to extract cell data by iterating through children
        for i in 0..<element.childCount {
            if let cell = element.child(at: i) {
                // Extract text using a simple recursive approach
                let cellText = extractTableCellText(from: cell)
                if !cellText.isEmpty {
                    cellData.append(cellText)
                }
            }
        }
        
        return cellData
    }
    
    // Helper method to extract text from table cells recursively
    private func extractTableCellText(from element: any Markup) -> String {
        var text = ""
        
        // Extract text recursively from children
        for i in 0..<element.childCount {
            if let child = element.child(at: i) {
                text += extractTableCellText(from: child)
            }
        }
        
        // If no children, try to get text representation from the element description
        if text.isEmpty {
            let description = String(describing: element)
            // Simple text extraction from description
            if description.contains("text: \"") {
                let components = description.components(separatedBy: "text: \"")
                if components.count > 1 {
                    let textPart = components[1].components(separatedBy: "\"")[0]
                    text = textPart
                }
            }
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Use Noora's TableRenderer for proper table formatting
    private mutating func renderTableUsingNooraRenderer(headers: [String], rows: [[String]]) {
        // Create TableData using Noora's table structure
        let columns = headers.map { TableColumn(title: TerminalText(stringLiteral: $0)) }
        let tableRows: [TableRow] = rows.map { rowData in
            rowData.map { TerminalText(stringLiteral: $0) }
        }
        
        let tableData = TableData(columns: columns, rows: tableRows)
        let tableStyle = theme.tableStyle
        let tableRenderer = TableRenderer()
        
        // Render table using Noora's TableRenderer
        let tableString = tableRenderer.render(
            data: tableData,
            style: tableStyle,
            theme: theme,
            terminal: terminal,
            logger: nil
        )
        
        // Add the rendered table to the output
        output.append(.raw(tableString))
    }
    
    // MARK: - Helpers
    
    private func calculateCurrentIndent() -> Int {
        var indent = 0
        if listDepth > 0 {
            indent += listDepth * style.listIndent
        }
        if isInBlockquote {
            indent += style.blockquoteIndent + 2
        }
        return indent
    }
}

extension TerminalText.Component {
    var isNewline: Bool {
        switch self {
        case .raw(let str):
            return str.hasSuffix("\n")
        default:
            return false
        }
    }
}
