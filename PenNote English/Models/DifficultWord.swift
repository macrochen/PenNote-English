import Foundation

struct DifficultWord: Identifiable {
    let id = UUID()
    let english: String
    let chinese: String
    let errorRate: Double
    let word: Word  // 添加 Word 属性
    
    init(english: String, chinese: String, errorRate: Double, word: Word) {
        self.english = english
        self.chinese = chinese
        self.errorRate = errorRate
        self.word = word
    }
}