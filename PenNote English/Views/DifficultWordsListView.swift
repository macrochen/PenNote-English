import SwiftUI

struct DifficultWordsListView: View {
    let difficultWords: [DifficultWord]
    @State private var currentIndex = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        if currentIndex < difficultWords.count {
            // 显示当前单词详情
            WordDetailView(word: difficultWords[currentIndex].word)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Text("\(currentIndex + 1)/\(difficultWords.count)")
                                .foregroundColor(.secondary)
                            
                            if currentIndex < difficultWords.count - 1 {
                                Button(action: {
                                    withAnimation {
                                        currentIndex += 1
                                    }
                                }) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 50)
                        .onEnded { gesture in
                            if gesture.translation.width < 0 {
                                // 左滑：下一个
                                withAnimation {
                                    if currentIndex < difficultWords.count - 1 {
                                        currentIndex += 1
                                    }
                                }
                            } else {
                                // 右滑：上一个
                                withAnimation {
                                    if currentIndex > 0 {
                                        currentIndex -= 1
                                    }
                                }
                            }
                        }
                )
        } else {
            // 显示完成页面
            VStack(spacing: 20) {
                Text("查看完成！")
                    .font(.title)
                    .foregroundColor(.secondary)
                
                Text("已查看所有易错单词")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("返回") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
}