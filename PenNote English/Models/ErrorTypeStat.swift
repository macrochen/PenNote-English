import Foundation

struct ErrorTypeStat {
    let type: SpellingErrorType
    let percentage: Double
}

extension ErrorTypeStat: Identifiable {
    var id: String { type.description }
}