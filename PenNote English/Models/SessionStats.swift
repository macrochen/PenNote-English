import Foundation
import CoreData

struct SessionStats {
    let totalCount: Int
    let correctCount: Int
    let errorTypes: [ErrorTypeStat]
}

struct ErrorTypeStat: Identifiable {
    let id: UUID = UUID()
    let type: SpellingErrorType
    let count: Int
    let percentage: Double
}