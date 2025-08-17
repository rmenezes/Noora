import Foundation

public struct MarkdownStyle {
    public let margins: Int
    public let maxWidth: Int?
    public let codeBlockIndent: Int
    public let listIndent: Int
    public let blockquoteIndent: Int
    public let showCodeLineNumbers: Bool
    public let headerUnderline: Bool
    
    public static let `default` = MarkdownStyle(
        margins: 2,
        maxWidth: 120,
        codeBlockIndent: 4,
        listIndent: 2,
        blockquoteIndent: 2,
        showCodeLineNumbers: false,
        headerUnderline: true
    )
    
    public static let compact = MarkdownStyle(
        margins: 0,
        maxWidth: nil,
        codeBlockIndent: 2,
        listIndent: 2,
        blockquoteIndent: 1,
        showCodeLineNumbers: false,
        headerUnderline: false
    )
    
    public init(
        margins: Int = 2,
        maxWidth: Int? = 120,
        codeBlockIndent: Int = 4,
        listIndent: Int = 2,
        blockquoteIndent: Int = 2,
        showCodeLineNumbers: Bool = false,
        headerUnderline: Bool = true
    ) {
        self.margins = margins
        self.maxWidth = maxWidth
        self.codeBlockIndent = codeBlockIndent
        self.listIndent = listIndent
        self.blockquoteIndent = blockquoteIndent
        self.showCodeLineNumbers = showCodeLineNumbers
        self.headerUnderline = headerUnderline
    }
}
