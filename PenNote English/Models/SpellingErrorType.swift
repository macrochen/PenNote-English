import Foundation

enum SpellingErrorType: Int16, CaseIterable {
    case typo = 0
    case missing = 1
    case extra = 2
    case wrong = 3
    case other = 4
    
    var description: String {
        switch self {
        case .typo: return "拼写错误"
        case .missing: return "遗漏字母"
        case .extra: return "多余字母"
        case .wrong: return "错误字母"
        case .other: return "其他错误"
        }
    }
    
    static func from(description: String) -> SpellingErrorType {
        switch description {
        case "拼写错误": return .typo
        case "遗漏字母": return .missing
        case "多余字母": return .extra
        case "错误字母": return .wrong
        default: return .other
        }
    }
}