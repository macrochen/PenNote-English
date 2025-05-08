import SwiftUI

struct PracticeModeView: View {
    @StateObject private var viewModel: PracticeViewModel
    
    init() {
        // 创建视图模型但不访问其 wrappedValue
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: PracticeViewModel(viewContext: context))
    }
    
    @State private var showingBatchPractice = false
    @State private var showingSinglePractice = false
    @State private var showingWordSelector = false
    @State private var showingAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {  // 添加 ScrollView 使内容可滚动
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
                        
                        // 单词范围设置
                        VStack(alignment: .leading, spacing: 10) {
                            Text("单词范围")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
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
                                    // 删除这行，让 fetchAvailableSemesters 方法决定是否更新 currentSemester
                                    // viewModel.currentSemester = viewModel.availableSemesters.first ?? 1
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
                                    // 删除这行，让 fetchAvailableUnits 方法决定是否更新 currentUnit
                                    // viewModel.currentUnit = viewModel.availableUnits.first?.unit ?? 1
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
                               .onChange(of: viewModel.currentUnit) { newUnit in
                                    viewModel.fetchWordsForCurrentSelection(grade: viewModel.currentGrade, semester: viewModel.currentSemester, unit: newUnit)
                                    viewModel.selectedWords = []  // 清空选中的单词
                                }
                            }
                        }
                        .padding(.vertical, 5)
                        
                        Divider()
                        
                        // 过滤条件
                        VStack(alignment: .leading, spacing: 10) {
                            Text("过滤条件")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // 重点属性过滤
                            HStack {
                                Text("重要程度")
                                Spacer()
                                Picker("重要程度", selection: $viewModel.importanceFilter) {
                                    Text("全部").tag(Int16(-1))
                                    Text("重点").tag(Int16(1))
                                    Text("核心").tag(Int16(2))
                                    Text("特别重要").tag(Int16(3))
                                }
                                .pickerStyle(MenuPickerStyle())
                                .onChange(of: viewModel.importanceFilter) { newValue in
                                    print("重要程度已更改为: \(newValue)")
                                    viewModel.selectedWords = []
                                }
                            }
                            
                            // 听写状态过滤
                            HStack {
                                Text("听写状态")
                                Spacer()
                                Picker("听写状态", selection: $viewModel.practiceStatusFilter) {
                                    Text("全部").tag(Int16(0))
                                    Text("未听写").tag(Int16(1))
                                }
                                .pickerStyle(MenuPickerStyle())
                                .onChange(of: viewModel.practiceStatusFilter) { newValue in
                                    print("听写状态已更改为: \(newValue)")
                                    viewModel.selectedWords = []
                                }
                            }
                            .onAppear {
                                // 确保在视图出现时设置为未听写状态
                                // if viewModel.practiceStatusFilter == 0 {
                                //     viewModel.practiceStatusFilter = 1
                                // }
                            }
                            
                            // 错误次数过滤
                            HStack {
                                Text("错误次数")
                                Spacer()
                                Picker("错误次数", selection: $viewModel.errorCountFilter) {
                                    Text("全部").tag(Int16(0))
                                    Text("1次").tag(Int16(1))
                                    Text("2次").tag(Int16(2))
                                    Text("3次").tag(Int16(3))
                                    Text("3次以上").tag(Int16(4))
                                }
                                .pickerStyle(MenuPickerStyle())
                                .onChange(of: viewModel.errorCountFilter) { newValue in
                                    print("错误次数已更改为: \(newValue)")
                                    viewModel.selectedWords = []
                                }
                            }
                        }
                        .padding(.vertical, 5)
                        
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
                        .padding(.top, 5)
                        
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
                        importanceFilter: viewModel.importanceFilter,
                        practiceStatusFilter: viewModel.practiceStatusFilter,
                        errorCountFilter: viewModel.errorCountFilter,
                        selectedWords: $viewModel.selectedWords
                    )
                    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                }
                .alert("选择单词", isPresented: $showingAlert) {
                    Button("确定", role: .cancel) { }
                } message: {
                    Text("请先选择要练习的单词，再开始听写。")
                }
            }
            .onAppear {
                // 注释掉这行代码，让从 UserDefaults 加载的设置生效
                // viewModel.practiceStatusFilter = 1
            }
        }
    }
}

#Preview {
    PracticeModeView()
}