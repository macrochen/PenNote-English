import Foundation

enum SpellingErrorType: Int16, CaseIterable {
    case spelling = 1      // 拼写错误
    case morphology = 2    // 词形变化错误
    case capitalization = 3 // 大小写错误
    case sequence = 4      // 字母顺序错误
    
    var description: String {
        switch self {
        case .spelling: return "拼写错误"
        case .morphology: return "词形变化错误"
        case .capitalization: return "大小写错误"
        case .sequence: return "字母顺序错误"
        }
    }
}