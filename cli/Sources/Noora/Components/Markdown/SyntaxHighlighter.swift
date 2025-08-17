import Foundation

/// Simple syntax highlighter for common programming languages
struct SyntaxHighlighter {
    private let theme: Theme
    private let terminal: Terminaling
    
    init(theme: Theme, terminal: Terminaling) {
        self.theme = theme
        self.terminal = terminal
    }
    
    /// Highlight code for the given language
    func highlight(code: String, language: String) -> [TerminalText.Component] {
        let lang = language.lowercased()
        
        switch lang {
        case "swift":
            return highlightSwift(code)
        case "bash", "sh", "shell":
            return highlightBash(code)
        case "json":
            return highlightJSON(code)
        case "javascript", "js":
            return highlightJavaScript(code)
        case "python", "py":
            return highlightPython(code)
        default:
            // Return unhighlighted code
            return [.info(code)]
        }
    }
    
    // MARK: - Language-specific highlighters
    
    private func highlightSwift(_ code: String) -> [TerminalText.Component] {
        let keywords = [
            "func", "var", "let", "class", "struct", "enum", "protocol", "extension",
            "import", "if", "else", "for", "while", "switch", "case", "default",
            "return", "break", "continue", "public", "private", "internal", "fileprivate",
            "static", "override", "final", "lazy", "weak", "strong", "unowned",
            "init", "deinit", "guard", "defer", "throws", "rethrows", "try", "catch"
        ]
        return highlightWithKeywords(code, keywords: keywords)
    }
    
    private func highlightBash(_ code: String) -> [TerminalText.Component] {
        let keywords = [
            "if", "then", "else", "elif", "fi", "for", "while", "do", "done",
            "case", "esac", "function", "return", "local", "export", "readonly",
            "declare", "typeset", "unset", "shift", "break", "continue", "exit"
        ]
        return highlightWithKeywords(code, keywords: keywords)
    }
    
    private func highlightJSON(_ code: String) -> [TerminalText.Component] {
        let keywords = ["true", "false", "null"]
        return highlightWithKeywords(code, keywords: keywords)
    }
    
    private func highlightJavaScript(_ code: String) -> [TerminalText.Component] {
        let keywords = [
            "function", "var", "let", "const", "if", "else", "for", "while", "do",
            "switch", "case", "default", "return", "break", "continue", "try", "catch",
            "finally", "throw", "new", "class", "extends", "import", "export", "from"
        ]
        return highlightWithKeywords(code, keywords: keywords)
    }
    
    private func highlightPython(_ code: String) -> [TerminalText.Component] {
        let keywords = [
            "def", "class", "if", "else", "elif", "for", "while", "do", "import",
            "from", "return", "break", "continue", "try", "except", "finally",
            "raise", "with", "as", "pass", "lambda", "global", "nonlocal"
        ]
        return highlightWithKeywords(code, keywords: keywords)
    }
    
    // MARK: - Helper methods
    
    private func highlightWithKeywords(_ code: String, keywords: [String]) -> [TerminalText.Component] {
        var components: [TerminalText.Component] = []
        var currentWord = ""
        var inString = false
        var inComment = false
        var stringChar: Character?
        
        func flushWord() {
            if !currentWord.isEmpty {
                if inComment {
                    components.append(.muted(currentWord))
                } else if inString {
                    components.append(.success(currentWord))
                } else if keywords.contains(currentWord.lowercased()) {
                    components.append(.primary(currentWord))
                } else {
                    components.append(.raw(currentWord))
                }
                currentWord = ""
            }
        }
        
        for char in code {
            if char == "\n" {
                flushWord()
                components.append(.raw("\n"))
                inComment = false
            } else if inComment {
                currentWord.append(char)
            } else if inString {
                currentWord.append(char)
                if char == stringChar && (currentWord.count < 2 || currentWord[currentWord.index(currentWord.endIndex, offsetBy: -2)] != "\\") {
                    inString = false
                    stringChar = nil
                    flushWord()
                }
            } else if char == "#" || (char == "/" && currentWord.last == "/") {
                if char == "/" && currentWord.last == "/" {
                    currentWord.removeLast() // Remove the first /
                    flushWord()
                    currentWord = "//"
                }
                inComment = true
                currentWord.append(char)
            } else if char == "\"" || char == "'" {
                flushWord()
                inString = true
                stringChar = char
                currentWord.append(char)
            } else if char.isWhitespace || char.isPunctuation {
                flushWord()
                components.append(.raw(String(char)))
            } else {
                currentWord.append(char)
            }
        }
        
        flushWord()
        return components
    }
}