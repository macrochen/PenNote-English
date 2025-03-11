import SwiftUI

struct PracticeCheckView: View {
    let words: [Word]
    let userAnswers: [String]
    @State private var results: [(isCorrect: Bool, errorTypes: Set<SpellingErrorType>)] = []
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PracticeViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                progressSection
                wordResultsList
                saveButton
            }
            .padding()
        }
        .navigationTitle("听写结果登记")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkAnswers()
        }
    }
    
    private var progressSection: some View {
        VStack {
            ProgressView(value: Double(results.count), total: Double(words.count))
                .padding(.horizontal)
            
            Text("\(results.count)/\(words.count)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var wordResultsList: some View {
        ForEach(Array(zip(words.indices, words)), id: \.0) { index, word in
            wordResultView(index: index, word: word)
        }
    }
    
    private func wordResultView(index: Int, word: Word) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(index + 1). \(word.english ?? "")")
                .font(.headline)
            Text(word.chinese ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if index < results.count {
                resultView(for: index)
            }
            
            if !(results[safe: index]?.isCorrect ?? false) {
                errorTypeSelector(for: index)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var saveButton: some View {
        Group {
            if results.count == words.count {
                Button("保存结果") {
                    saveResults()
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
    
    private func resultView(for index: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("你的答案：\(userAnswers[index])")
                .foregroundColor(results[index].isCorrect ? .green : .red)
            
            if !results[index].isCorrect {
                Text("错误类型：")
                    .font(.subheadline)
                ForEach(Array(results[index].errorTypes), id: \.rawValue) { errorType in
                    Text("• \(errorType.description)")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private func errorTypeSelector(for index: Int) -> some View {
        VStack(alignment: .leading) {
            Text("选择错误类型：")
                .font(.subheadline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(SpellingErrorType.allCases, id: \.rawValue) { errorType in
                    Button(action: {
                        toggleErrorType(errorType, for: index)
                    }) {
                        Text(errorType.description)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                             .background(
                                results[safe: index]?.errorTypes.contains(errorType) ?? false
                                ? Color.red
                                : Color.gray.opacity(0.3)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private func checkAnswers() {
        results = zip(words, userAnswers).map { word, answer in
            let isCorrect = answer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
                          (word.english ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            return (isCorrect, Set<SpellingErrorType>())
        }
    }
    
    private func toggleErrorType(_ errorType: SpellingErrorType, for index: Int) {
        guard var result = results[safe: index] else { return }
        
        if result.errorTypes.contains(errorType) {
            result.errorTypes.remove(errorType)
        } else {
            result.errorTypes.insert(errorType)
        }
        
        results[index] = result
    }
    
    private func saveResults() {
        for (index, word) in words.enumerated() {
            viewModel.saveWordResult(
                word: word,
                isCorrect: results[index].isCorrect,
                errorTypes: Array(results[index].errorTypes)
            )
        }
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
