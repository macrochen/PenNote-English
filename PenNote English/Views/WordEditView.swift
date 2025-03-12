import SwiftUI

struct WordEditView: View {
    let word: Word
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var english: String
    @State private var chinese: String
    @State private var phonetic: String
    @State private var partOfSpeech: String
    @State private var importance: Int16
    @State private var grade: Int16
    @State private var semester: Int16
    @State private var unit: Int16
    @State private var lesson: String
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
        _partOfSpeech = State(initialValue: word.partOfSpeech ?? "")
        _importance = State(initialValue: word.importance)
        _grade = State(initialValue: word.grade)
        _semester = State(initialValue: word.semester)
        _unit = State(initialValue: word.unit)
        _lesson = State(initialValue: word.lesson ?? "")
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
                TextField("词性", text: $partOfSpeech)
                Picker("重要程度", selection: $importance) {
                    Text("普通词汇").tag(Int16(0))
                    Text("重点词汇").tag(Int16(1))
                    Text("核心词汇").tag(Int16(2))
                    Text("特别重要").tag(Int16(3))
                }
            }
            
            Section("教材信息") {
                Picker("年级", selection: $grade) {
                    ForEach(1...9, id: \.self) { grade in
                        Text("\(grade)年级").tag(Int16(grade))
                    }
                }
                
                Picker("学期", selection: $semester) {
                    Text("第1学期").tag(Int16(1))
                    Text("第2学期").tag(Int16(2))
                }
                
                Stepper("Unit \(unit)", value: $unit, in: 1...20)
                
                TextField("课文", text: $lesson)
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
        word.partOfSpeech = partOfSpeech
        word.importance = importance
        word.grade = grade
        word.semester = semester
        word.unit = unit
        word.lesson = lesson
        word.etymology = etymology
        word.structure = structure
        word.example = example
        word.exampleTranslation = exampleTranslation
        word.memoryTips = memoryTips
        word.updatedAt = Date()
        
        try? viewContext.save()
    }
}