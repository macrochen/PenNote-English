import SwiftUI

struct DifficultWordsListView: View {
    let difficultWords: [DifficultWord]
    
    var body: some View {
        List {
            ForEach(difficultWords) { word in
                VStack(alignment: .leading, spacing: 4) {
                    Text(word.english)
                        .font(.headline)
                    Text(word.chinese)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("错误率: \(Int(word.errorRate * 100))%")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("易错单词")
        .navigationBarTitleDisplayMode(.inline)
    }
}