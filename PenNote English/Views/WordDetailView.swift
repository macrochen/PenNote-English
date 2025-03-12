import SwiftUI

struct WordDetailView: View {
    let word: Word
    @State private var showEditSheet = false
    
    var body: some View {
        List {
            // 基本信息部分
            Section("基本信息") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(word.english ?? "")
                            .font(.title)
                        if let phonetic = word.phonetic {
                            Text(phonetic)
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        if let partOfSpeech = word.partOfSpeech {
                            Text(partOfSpeech)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                        Spacer()
                        Button(action: {
                            if let english = word.english {
                                SpeechService.shared.speak(english)
                            }
                        }) {
                            Image(systemName: "speaker.wave.2")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text(word.chinese ?? "")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        
                    
                    Text(importanceText)
                        .foregroundColor(importanceColor)
                        .font(.subheadline)
                }
                .padding(.vertical, 8)
            }
            
            // 学习辅助部分
            Section("") {
                
                if let example = word.example {
                    VStack(alignment: .leading) {
                        Text("例句")
                            .font(.headline)
                        Text(example)
                        if let translation = word.exampleTranslation {
                            Text(translation)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                if let etymology = word.etymology {
                    VStack(alignment: .leading) {
                        Text("词源")
                            .font(.headline)
                        Text(etymology)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                if let structure = word.structure {
                    VStack(alignment: .leading) {
                        Text("词形结构")
                            .font(.headline)
                        Text(structure)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                if let tips = word.memoryTips {
                    VStack(alignment: .leading) {
                        Text("记忆技巧")
                            .font(.headline)
                        Text(tips)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // 教材信息部分
            Section("教材信息") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("年级")
                        Spacer()
                        Text("\(word.grade)年级")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("学期")
                        Spacer()
                        Text("第\(word.semester)学期")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("单元")
                        Spacer()
                        Text("Unit \(word.unit)")
                            .foregroundColor(.secondary)
                    }
                    
                    if let lesson = word.lesson {
                        HStack {
                            Text("课文")
                            Spacer()
                            Text(lesson)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showEditSheet = true }) {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationView {
                WordEditView(word: word)
            }
        }
    }
    
    // 添加计算属性
    private var importanceText: String {
        switch word.importance {
        case 0: return "普通词汇"
        case 1: return "重点词汇"
        case 2: return "核心词汇"
        case 3: return "特别重要"
        default: return "未知"
        }
    }
    
    private var importanceColor: Color {
        switch word.importance {
        case 0: return .secondary
        case 1: return .blue
        case 2: return .orange
        case 3: return .red
        default: return .secondary
        }
    }
    
    private var correctRate: Int {
        guard let results = word.wordResults as? Set<WordResult>,
              !results.isEmpty else { return 0 }
        
        let correctCount = results.filter { $0.isCorrect }.count
        return Int(Double(correctCount) / Double(results.count) * 100)
    }
}