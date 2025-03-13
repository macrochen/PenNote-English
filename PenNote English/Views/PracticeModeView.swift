import SwiftUI

struct PracticeModeView: View {
    @StateObject private var viewModel: PracticeViewModel
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: PracticeViewModel(viewContext: context))
    }
    
    @State private var showingBatchPractice = false
    @State private var showingSinglePractice = false
    @State private var showingWordSelector = false
    @State private var showingAlert = false
    
    var body: some View {
        NavigationStack {
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
                    // 修改批量听写按钮的 action
                    // 批量听写按钮
                    Button(action: {
                        if viewModel.selectedWords.isEmpty {
                            showingAlert = true  // 显示提示
                        } else {
                            showingBatchPractice = true
                        }
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
                    // 修改逐个拼写按钮的 action
                    Button(action: {
                        if viewModel.selectedWords.isEmpty {
                            showingAlert = true
                        } else {
                            showingSinglePractice = true
                        }
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
                    
                    // 年级选择
                    HStack {
                        Text("年级")
                        Spacer()
                        Picker("", selection: $viewModel.currentGrade) {
                            ForEach(viewModel.availableGrades, id: \.self) { grade in
                                Text("\(grade)年级").tag(grade)
                            }
                        }
                        .onChange(of: viewModel.currentGrade) { newGrade in
                            viewModel.fetchAvailableSemesters(for: newGrade)
                            viewModel.currentSemester = viewModel.availableSemesters.first ?? 1
                            viewModel.selectedWords = []  // 清空选中的单词
                        }
                    }
                    
                    // 学期选择
                    HStack {
                        Text("学期")
                        Spacer()
                        Picker("", selection: $viewModel.currentSemester) {
                            ForEach(viewModel.availableSemesters, id: \.self) { semester in
                                Text("第\(semester)学期").tag(semester)
                            }
                        }
                        .onChange(of: viewModel.currentSemester) { newSemester in
                            viewModel.fetchAvailableUnits(for: viewModel.currentGrade, semester: newSemester)
                            viewModel.currentUnit = viewModel.availableUnits.first?.unit ?? 1
                            viewModel.selectedWords = []  // 清空选中的单词
                        }
                    }
                    
                    // 单元选择
                    HStack {
                        Text("单元")
                        Spacer()
                        Picker("单元", selection: $viewModel.currentUnit) {
                            ForEach(viewModel.availableUnits) { unitInfo in
                                Text("Unit \(unitInfo.unit) (\(unitInfo.wordCount))")
                                    .tag(unitInfo.unit)
                            }
                        }
                        .onChange(of: viewModel.currentUnit) { _ in
                            viewModel.selectedWords = []  // 清空选中的单词
                        }
                    }
                    
                    // 选择单词按钮
                    Button(action: { showingWordSelector = true }) {
                        HStack {
                            Text("选择练习单词")
                            Spacer()
                            Text("\(viewModel.selectedWords.count)个")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showingBatchPractice) {
                BatchDictationView(words: viewModel.selectedWords)
                    .onDisappear {
                        showingBatchPractice = false  // 只重置导航状态，不清空选中的单词
                    }
            }
            .navigationDestination(isPresented: $showingSinglePractice) {
                SingleWordPracticeView(words: viewModel.selectedWords)
                    .onDisappear {
                        showingSinglePractice = false  // 只重置导航状态，不清空选中的单词
                    }
            }
            .sheet(isPresented: $showingWordSelector) {
                WordSelectorView(
                    grade: viewModel.currentGrade,
                    semester: viewModel.currentSemester,
                    unit: viewModel.currentUnit,
                    selectedWords: $viewModel.selectedWords
                )
            }
            .alert("选择单词", isPresented: $showingAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text("请先选择要练习的单词，再开始听写。")
            }
        }
    }
}

#Preview {
    PracticeModeView()
}