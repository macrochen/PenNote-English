import SwiftUI

struct SpellingPracticeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SpellingPracticeViewModel
    
    var body: some View {
        VStack {
            Text("\(viewModel.currentIndex + 1)/\(viewModel.totalCount)")
                .font(.caption)
                .foregroundColor(.secondary)
                
            // TODO: 添加其他练习界面元素
        }
        .navigationTitle("听写练习")
        .navigationBarTitleDisplayMode(.inline)
    }
}