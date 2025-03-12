import Foundation

struct DifficultWord {
    let english: String
    let chinese: String
    let errorRate: Double
}

extension DifficultWord: Identifiable {
    var id: String { english }
}