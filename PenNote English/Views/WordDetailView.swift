import SwiftUI

struct WordDetailView: View {
    let word: Word
    @State private var showEditSheet = false
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(word.english ?? "")
                            .font(.title)
                        if let phonetic = word.phonetic {
                            Text(phonetic)
                                .font(.headline)
                                .foregroundColor(.gray)
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
                }
                .padding(.vertical, 8)
            }
            
            if let etymology = word.etymology {
                Section("词根词缀") {
                    Text(etymology)
                }
            }
            
            if let structure = word.structure {
                Section("单词结构") {
                    Text(structure)
                }
            }
            
            if let example = word.example {
                Section("例句") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(example)
                        if let translation = word.exampleTranslation {
                            Text(translation)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            if let tips = word.memoryTips {
                Section("记忆技巧") {
                    Text(tips)
                }
            }
            
            // 学习记录部分
            Section("学习记录") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("添加时间")
                        Spacer()
                        Text(word.createdAt?.formatted(date: .numeric, time: .omitted) ?? "")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("复习次数")
                        Spacer()
                        Text("\(word.reviewRecords?.count ?? 0)次")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("正确率")
                        Spacer()
                        Text(String(format: "%.0f%%", word.reviewProgress * 100))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("下次复习")
                        Spacer()
                        Text(word.needsReview ? "今天" : "待定")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 移除立即复习按钮部分
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
}