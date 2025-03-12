import SwiftUI

struct PracticeModeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: PracticeViewModel
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: PracticeViewModel(viewContext: context))
    }
    
    @State private var wordCount: Int = 5
    @State private var practiceRange: String = "所有单词"
    @State private var showingBatchPractice = false
    @State private var showingSinglePractice = false
    @State private var selectedGrade: Int16 = 1
    @State private var selectedSemester: Int16 = 1
    @State private var selectedUnit: Int16 = 1
    @State private var showingWordSelector = false
    
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
                        viewModel.startBatchPractice(wordCount: wordCount)
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
                        viewModel.startSinglePractice(wordCount: wordCount)
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
                            viewModel.currentUnit = viewModel.availableUnits.first ?? 1
                        }
                    }
                    
                    // 单元选择
                    HStack {
                        Text("单元")
                        Spacer()
                        Picker("", selection: $viewModel.currentUnit) {
                            ForEach(viewModel.availableUnits, id: \.self) { unit in
                                Text("Unit \(unit)").tag(unit)
                            }
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
            }
            .navigationDestination(isPresented: $showingSinglePractice) {
                SingleWordPracticeView(words: viewModel.selectedWords)
            }
            .sheet(isPresented: $showingWordSelector) {
                WordSelectorView(
                    grade: viewModel.currentGrade,
                    semester: viewModel.currentSemester,
                    unit: viewModel.currentUnit,
                    selectedWords: $viewModel.selectedWords
                )
            }
        }
        .onAppear {
            viewModel.fetchAvailableGrades()
        }
    }  // 这里缺少了 body 的闭合
}  // 这里缺少了 struct 的闭合

#Preview {
    PracticeModeView()
}