import Foundation

func parseUSDAFile(usdaFileURL: URL) throws -> [String: String] {
    var nodeNameMap = [String: String]()
    do {
        let usdaContent = try String(contentsOf: usdaFileURL, encoding: .utf8)
        
        let pattern = #"def Xform \"([^\"]+)\" \("#
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: usdaContent, options: [], range: NSRange(usdaContent.startIndex..., in: usdaContent))
        
        for match in matches {
            if let range = Range(match.range(at: 1), in: usdaContent) {
                let modelName = String(usdaContent[range])
                
                // Extract the geometry reference
                let geometryPattern = #"prepend references = @\.\/geometries\/([^\"]+)\.usd"#
                let geometryRegex = try NSRegularExpression(pattern: geometryPattern, options: [])
                if let geometryMatch = geometryRegex.firstMatch(in: usdaContent, options: [], range: NSRange(range.upperBound..., in: usdaContent)),
                   let geometryRange = Range(geometryMatch.range(at: 1), in: usdaContent) {
                    let geometryName = String(usdaContent[geometryRange])
                    nodeNameMap[geometryName] = modelName
                }
            }
        }
    } catch {
        print("Error reading USDA file: \(error.localizedDescription)")
    }
    return nodeNameMap
}
