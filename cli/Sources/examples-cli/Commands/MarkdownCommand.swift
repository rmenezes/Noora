import ArgumentParser
import Foundation
import Noora

struct MarkdownCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "markdown",
        abstract: "Display markdown content with terminal styling"
    )
    
    @Option(help: "Style to use for rendering (default, compact)")
    var style: String = "default"
    
    @Option(help: "Path to markdown file (if not provided, uses demo content)")
    var file: String?
    
    func run() throws {
        let noora = Noora()
        
        let markdownStyle: MarkdownStyle = switch style.lowercased() {
        case "compact":
            .compact
        default:
            .default
        }
        
        if let filePath = file {
            try noora.markdownFile(path: filePath, style: markdownStyle)
        } else {
            let demoContent = """
            # Noora Markdown Support
            
            Welcome to **Noora's** markdown rendering capabilities! This demonstrates various markdown features rendered beautifully in your terminal.
            
            ## Features
            
            ### Text Formatting
            
            You can use **bold text**, *italic text*, and `inline code` to emphasize different parts of your content.
            You can also use ~~strikethrough~~ text when needed.
            
            ### Lists
            
            #### Unordered Lists
            - First item
            - Second item with **bold**
            - Third item with `code`
              - Nested item 1
              - Nested item 2
            
            #### Ordered Lists
            1. First step
            2. Second step with *emphasis*
            3. Third step
               1. Sub-step A
               2. Sub-step B
            
            ### Code Blocks
            
            ```swift
            // Swift code example
            let noora = Noora()
            noora.markdown("# Hello, World!")
            ```
            
            ```bash
            # Shell commands
            mise run build
            mise run test
            ```
            
            ### Blockquotes
            
            > This is a blockquote that can contain multiple lines
            > and even **formatted text** within it.
            >
            > It's useful for highlighting important information.
            
            ### Links
            
            Check out [Noora on GitHub](https://github.com/tuist/noora) for more information.
            Visit the [documentation](https://noora.tuist.dev) to learn more.
            
            ---
            
            ## Advanced Features
            
            ### Headers at Different Levels
            
            #### Level 4 Header
            ##### Level 5 Header
            ###### Level 6 Header
            
            ### Mixed Content
            
            Here's a paragraph with various elements: **bold**, *italic*, `code`, and [links](https://example.com).
            
            > **Note:** Blockquotes can also contain:
            > - Lists
            > - `Code`
            > - And other formatted content
            
            ### Tables (Preview)
            
            | Feature | Status | Notes |
            |---------|--------|-------|
            | Headers | ✅ | Fully supported |
            | Lists | ✅ | Nested lists work |
            | Code | ✅ | With syntax highlighting |
            | Tables | 🚧 | Coming soon |
            
            ---
            
            *Thank you for using Noora!*
            """
            
            noora.markdown(demoContent, style: markdownStyle)
        }
    }
}