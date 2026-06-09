import Foundation

public enum ManifestJSONDecoder {
    public static func decode(_ type: ModManifest.Type, from data: Data) throws -> ModManifest {
        let source = String(decoding: data, as: UTF8.self)
        let sanitizedSource = removeTrailingCommas(from: removeComments(from: source))

        guard let sanitizedData = sanitizedSource.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "Manifest is not valid UTF-8")
            )
        }

        return try JSONDecoder().decode(type, from: sanitizedData)
    }

    private static func removeComments(from source: String) -> String {
        let characters = Array(source)
        var output = ""
        var index = 0
        var isInString = false
        var isEscaped = false
        var isInLineComment = false
        var isInBlockComment = false

        while index < characters.count {
            let character = characters[index]
            let nextCharacter = index + 1 < characters.count ? characters[index + 1] : nil

            if isInLineComment {
                if character.isNewline {
                    isInLineComment = false
                    output.append("\n")
                }
                index += 1
                continue
            }

            if isInBlockComment {
                if character.isNewline {
                    output.append("\n")
                }

                if character == "*", nextCharacter == "/" {
                    isInBlockComment = false
                    index += 2
                } else {
                    index += 1
                }
                continue
            }

            if isInString {
                output.append(character)

                if isEscaped {
                    isEscaped = false
                } else if character == "\\" {
                    isEscaped = true
                } else if character == "\"" {
                    isInString = false
                }

                index += 1
                continue
            }

            if character == "\"" {
                isInString = true
                output.append(character)
                index += 1
                continue
            }

            if character == "/", nextCharacter == "/" {
                isInLineComment = true
                index += 2
                continue
            }

            if character == "/", nextCharacter == "*" {
                isInBlockComment = true
                index += 2
                continue
            }

            output.append(character)
            index += 1
        }

        return output
    }

    private static func removeTrailingCommas(from source: String) -> String {
        let characters = Array(source)
        var output = ""
        var index = 0
        var isInString = false
        var isEscaped = false

        while index < characters.count {
            let character = characters[index]

            if isInString {
                output.append(character)

                if isEscaped {
                    isEscaped = false
                } else if character == "\\" {
                    isEscaped = true
                } else if character == "\"" {
                    isInString = false
                }

                index += 1
                continue
            }

            if character == "\"" {
                isInString = true
                output.append(character)
                index += 1
                continue
            }

            if character == "," {
                var lookahead = index + 1
                while lookahead < characters.count, characters[lookahead].isWhitespace {
                    lookahead += 1
                }

                if lookahead < characters.count,
                   characters[lookahead] == "}" || characters[lookahead] == "]" {
                    index += 1
                    continue
                }
            }

            output.append(character)
            index += 1
        }

        return output
    }
}
