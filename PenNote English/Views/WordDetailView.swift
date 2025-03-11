import SwiftUI

struct WordDetailView: View {
    let word: Word
    
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
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}