import SwiftUI

struct PracticeModeView: View {
    @StateObject private var viewModel = PracticeViewModel()
    @State private var wordCount: Int = 5
    @State private var practiceRange: String = "所有单词"
    @State private var showingBatchPractice = false
    @State private var showingSinglePractice = false
    
    var body: some View {
        NavigationStack {  // 将 NavigationView 改为 NavigationStack
            VStack(spacing: 20) {
                Text("选择练习模式")
                    .font(.title)
                    .padding(.top)
                
                // 批量听写模式
                VStack(alignment: .leading) {
                    Label("练习本批量听写", systemImage: "doc.text")
                        .font(.headline)
                    Text("一次性显示所有单词的中文释义，在练习本上完成听写后登记结果")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button(action: {
                        viewModel.startBatchPractice(wordCount: wordCount, range: practiceRange)
                        showingBatchPractice = true
                    }) {
                        Label("开始批量听写", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // APP内逐个拼写
                VStack(alignment: .leading) {
                    Label("APP内逐个拼写", systemImage: "keyboard")
                        .font(.headline)
                    Text("在APP内逐个显示单词的中文释义，直接在输入框中拼写单词")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button(action: {
                        viewModel.startSinglePractice(wordCount: wordCount, range: practiceRange)
                        showingSinglePractice = true
                    }) {
                        Label("开始逐个拼写", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // 练习设置
                VStack(alignment: .leading, spacing: 15) {
                    Text("练习设置")
                        .font(.headline)
                    
                    HStack {
                        Text("每次练习单词数量")
                        Spacer()
                        Picker("", selection: $wordCount) {
                            ForEach([5, 8, 10, 15], id: \.self) { count in
                                Text("\(count)个").tag(count)
                            }
                        }
                    }
                    
                    HStack {
                        Text("练习范围")
                        Spacer()
                        Picker("", selection: $practiceRange) {
                            Text("所有单词").tag("所有单词")
                            Text("待复习").tag("待复习")
                            Text("易错词").tag("易错词")
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showingBatchPractice) {
                BatchDictationView(words: viewModel.selectedWords)
            }
            .navigationDestination(isPresented: $showingSinglePractice) {
                SingleWordPracticeView(words: viewModel.selectedWords)
            }
        }
    }
}

#Preview {
    PracticeModeView()
}