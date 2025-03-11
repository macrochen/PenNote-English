import SwiftUI

struct WordEditView: View {
    let word: Word
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var english: String
    @State private var chinese: String
    @State private var phonetic: String
    @State private var etymology: String
    @State private var structure: String
    @State private var example: String
    @State private var exampleTranslation: String
    @State private var memoryTips: String
    
    init(word: Word) {
        self.word = word
        _english = State(initialValue: word.english ?? "")
        _chinese = State(initialValue: word.chinese ?? "")
        _phonetic = State(initialValue: word.phonetic ?? "")
        _etymology = State(initialValue: word.etymology ?? "")
        _structure = State(initialValue: word.structure ?? "")
        _example = State(initialValue: word.example ?? "")
        _exampleTranslation = State(initialValue: word.exampleTranslation ?? "")
        _memoryTips = State(initialValue: word.memoryTips ?? "")
    }
    
    var body: some View {
        Form {
            Section("基本信息") {
                TextField("英文单词", text: $english)
                TextField("中文释义", text: $chinese)
                TextField("音标", text: $phonetic)
            }
            
            Section("词根词缀") {
                TextField("词根词缀", text: $etymology)
            }
            
            Section("单词结构") {
                TextField("单词结构", text: $structure)
            }
            
            Section("例句") {
                TextField("例句", text: $example)
                TextField("例句翻译", text: $exampleTranslation)
            }
            
            Section("记忆技巧") {
                TextField("记忆技巧", text: $memoryTips)
            }
        }
        .navigationTitle("修改单词")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    saveWord()
                    dismiss()
                }
            }
        }
    }
    
    private func saveWord() {
        word.english = english
        word.chinese = chinese
        word.phonetic = phonetic
        word.etymology = etymology
        word.structure = structure
        word.example = example
        word.exampleTranslation = exampleTranslation
        word.memoryTips = memoryTips
        word.updatedAt = Date()
        
        try? viewContext.save()
    }
}