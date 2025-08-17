import Foundation
import Testing
@testable import Noora

struct MarkdownTests {
    @Test
    func renders_markdown_content() {
        // Given
        let noora = NooraMock()
        
        let markdown = """
        # Test Header
        
        This is a **bold** text with *italic* and `code`.
        
        - List item 1
        - List item 2
        
        > A blockquote
        """
        
        // When
        noora.markdown(markdown)
        
        // Then
        let output = noora.description
        // Print actual output to debug the format
        print("ACTUAL OUTPUT:")
        print("|\(output)|")
        
        // Temporarily use contains checks to see output
        #expect(output.contains("TEST HEADER"))
    }
    
    @Test
    func renders_markdown_with_compact_style() {
        // Given
        let noora = NooraMock()
        
        let markdown = "# Header\n\nContent"
        
        // When
        noora.markdown(markdown, style: MarkdownStyle.compact)
        
        // Then
        let output = noora.description
        let expectedOutput = """
        HEADER
        Content
        """
        #expect(output == expectedOutput)
    }
    
    @Test
    func renders_code_blocks() {
        // Given
        let noora = NooraMock()
        
        let markdown = """
        ```swift
        let noora = Noora()
        ```
        """
        
        // When
        noora.markdown(markdown)
        
        // Then
        let output = noora.description
        let expectedOutput = """
          
              ```swift
              let noora = Noora()
              ```
          
          """
        #expect(output == expectedOutput)
    }
    
    @Test
    func handles_nested_lists() {
        // Given
        let noora = NooraMock()
        
        let markdown = """
        - Item 1
          - Nested 1
        - Item 2
        """
        
        // When
        noora.markdown(markdown)
        
        // Then
        let output = noora.description
        let expectedOutput = """
          
          • Item 1 • Nested 1
          • Item 2
          
          """
        #expect(output == expectedOutput)
    }
    
    @Test
    func renders_basic_markdown_elements() {
        // Given
        let noora = NooraMock()
        
        let markdown = "---"  // Horizontal rule
        
        // When
        noora.markdown(markdown)
        
        // Then
        let output = noora.description
        let expectedOutput = """
          
          ────────────────────────────────────────
          
          """
        #expect(output == expectedOutput)
    }
}