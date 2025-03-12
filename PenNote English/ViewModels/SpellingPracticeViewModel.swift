import Foundation
import CoreData

class SpellingPracticeViewModel: ObservableObject {
    let words: [Word]
    let mode: PracticeViewModel.PracticeMode
    
    @Published var currentIndex: Int = 0
    @Published var totalCount: Int = 0
    @Published var currentWord: String = ""
    @Published var userInput: String = ""
    
    init(words: [Word], mode: PracticeViewModel.PracticeMode) {
        self.words = words
        self.mode = mode
        self.totalCount = words.count
        self.currentWord = words.first?.english ?? ""
    }
}