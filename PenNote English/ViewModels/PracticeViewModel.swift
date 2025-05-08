import Foundation
import CoreData

class PracticeViewModel: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    // MARK: - Published Properties
    @Published var currentGrade: Int16 = 7 {
        didSet {
            saveSettings()
        }
    }
    @Published var currentSemester: Int16 = 1 {
        didSet {
            saveSettings()
        }
    }
    @Published var selectedWords: [Word] = []
    @Published var availableGrades: [Int16] = []
    @Published var availableSemesters: [Int16] = []
    @Published var availableUnits: [UnitInfo] = []
    @Published var currentPracticeMode: PracticeMode = .none
    @Published var currentUnitInfo: UnitInfo = UnitInfo(unit: 1, wordCount: 0)
    
    // 在 PracticeViewModel 类中添加以下属性
    @Published var importanceFilter: Int16 = -1 { // -1表示全部
        didSet {
            saveSettings()
        }
    }
    @Published var practiceStatusFilter: Int16 = 0 { // 0表示全部，1表示未听写
        didSet {
            saveSettings()
        }
    }
    @Published var errorCountFilter: Int16 = 0 { // 0表示全部，1-4表示对应错误次数
        didSet {
            saveSettings()
        }
    }
    
    // 修改为计算属性
    @Published var currentUnit: Int16 = 1 {
        didSet {
            if let unitInfo = availableUnits.first(where: { $0.unit == currentUnit }) {
                currentUnitInfo = unitInfo
            }
            saveSettings()
        }
    }
    
    // MARK: - Initialization
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        loadSettings() // 先加载保存的设置
        fetchAvailableGrades()
    }
    
    // MARK: - Types
    enum PracticeMode {
        case none
        case batch
        case single
    }
    
    // MARK: - UserDefaults 相关方法
    private var isLoading = false // 添加一个标志变量
    
    private func saveSettings() {
        // 如果正在加载，则不保存
        if isLoading { return }
        
        let defaults = UserDefaults.standard
        defaults.set(Int(currentGrade), forKey: "practiceCurrentGrade")
        defaults.set(Int(currentSemester), forKey: "practiceCurrentSemester")
        defaults.set(Int(currentUnit), forKey: "practiceCurrentUnit")
        defaults.set(Int(importanceFilter), forKey: "practiceImportanceFilter")
        defaults.set(Int(practiceStatusFilter), forKey: "practicePracticeStatusFilter")
        defaults.set(Int(errorCountFilter), forKey: "practiceErrorCountFilter")
    }
    
    private func loadSettings() {
        isLoading = true // 开始加载
        
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "practiceCurrentGrade") != nil {
            currentGrade = Int16(defaults.integer(forKey: "practiceCurrentGrade"))
        }
        if defaults.object(forKey: "practiceCurrentSemester") != nil {
            currentSemester = Int16(defaults.integer(forKey: "practiceCurrentSemester"))
        }
        if defaults.object(forKey: "practiceCurrentUnit") != nil {
            currentUnit = Int16(defaults.integer(forKey: "practiceCurrentUnit"))
        }
        if defaults.object(forKey: "practiceImportanceFilter") != nil {
            importanceFilter = Int16(defaults.integer(forKey: "practiceImportanceFilter"))
        }
        if defaults.object(forKey: "practicePracticeStatusFilter") != nil {
            practiceStatusFilter = Int16(defaults.integer(forKey: "practicePracticeStatusFilter"))
        }
        if defaults.object(forKey: "practiceErrorCountFilter") != nil {
            errorCountFilter = Int16(defaults.integer(forKey: "practiceErrorCountFilter"))
        }
        
        isLoading = false // 加载完成
    }
    
    // MARK: - Methods
    func fetchWords(count: Int) -> [Word] {
        let request = Word.fetchRequest()
        request.fetchLimit = count
        
        do {
            let words = try viewContext.fetch(request)
            return words.shuffled()
        } catch {
            print("获取单词失败: \(error)")
            return []
        }
    }
    
    func startBatchPractice(wordCount: Int) {
        selectedWords = fetchWords(count: wordCount)
        currentPracticeMode = .batch
    }
    
    func startSinglePractice(wordCount: Int) {
        selectedWords = fetchWords(count: wordCount)
        currentPracticeMode = .single
    }
    
    func saveWordResult(word: Word, isCorrect: Bool, errorTypes: [SpellingErrorType] = []) {
        let result = WordResult(context: viewContext)
        result.id = UUID()
        result.word = word
        result.isCorrect = isCorrect
        result.date = Date()
        result.errorTypes = errorTypes.map { $0.description }
        
        do {
            try viewContext.save()
        } catch {
            print("保存练习结果失败: \(error)")
        }
    }
    
    func saveBatchResults(results: [String: Bool]) {
        for word in selectedWords {
            if let isCorrect = results[word.english ?? ""] {
                saveWordResult(word: word, isCorrect: isCorrect)
            }
        }
    }
    
    func fetchAvailableGrades() {
        let request = NSFetchRequest<NSDictionary>(entityName: "Word")
        request.propertiesToFetch = ["grade"]
        request.resultType = .dictionaryResultType
        
        do {
            let results = try viewContext.fetch(request)
            let grades = Set(results.compactMap { $0["grade"] as? Int16 }).sorted()
            let oldGrades = availableGrades
            availableGrades = grades.isEmpty ? [1] : grades
            
            // 只有在初始化时（oldGrades为空）或当前年级不在可用年级列表中时才更新当前年级
            if oldGrades.isEmpty || !availableGrades.contains(currentGrade) {
                currentGrade = availableGrades.first ?? 1
            }
            
            // 获取对应学期
            fetchAvailableSemesters(for: currentGrade)
        } catch {
            print("获取年级失败: \(error)")
            availableGrades = [1]
        }
    }
    
    func fetchAvailableSemesters(for grade: Int16) {
        let request = NSFetchRequest<NSDictionary>(entityName: "Word")
        request.propertiesToFetch = ["semester"]
        request.resultType = .dictionaryResultType
        request.predicate = NSPredicate(format: "grade == %d", grade)
        
        do {
            let results = try viewContext.fetch(request)
            let semesters = Set(results.compactMap { $0["semester"] as? Int16 }).sorted()
            let oldSemesters = availableSemesters
            availableSemesters = semesters.isEmpty ? [1] : semesters
            
            // 只有在初始化时（oldSemesters为空）或当前学期不在可用学期列表中时才更新当前学期
            if oldSemesters.isEmpty || !availableSemesters.contains(currentSemester) {
                currentSemester = availableSemesters.first ?? 1
            }
            
            // 获取对应单元
            fetchAvailableUnits(for: grade, semester: currentSemester)
        } catch {
            print("获取学期失败: \(error)")
            availableSemesters = [1]
        }
    }
    
    struct UnitInfo: Identifiable {
        let unit: Int16
        let wordCount: Int
        var id: Int16 { unit }
    }
    
    
    func fetchAvailableUnits(for grade: Int16, semester: Int16) {
        let request = NSFetchRequest<NSDictionary>(entityName: "Word")
        request.propertiesToFetch = ["unit"]
        request.resultType = .dictionaryResultType
        request.predicate = NSPredicate(format: "grade == %d AND semester == %d", grade, semester)
        
        do {
            let results = try viewContext.fetch(request)
            let units = Set(results.compactMap { $0["unit"] as? Int16 }).sorted()
            availableUnits = units.map { unit in
                let count = fetchUnitWordCount(grade: grade, semester: semester, unit: unit)
                return UnitInfo(unit: unit, wordCount: count)
            }
            
            // 只有在初始化时（availableUnits为空）或当前单元不在可用单元列表中时才更新当前单元
            if availableUnits.isEmpty || !availableUnits.contains(where: { $0.unit == currentUnit }) {
                currentUnit = availableUnits.first?.unit ?? 1
                currentUnitInfo = availableUnits.first ?? UnitInfo(unit: 1, wordCount: 0)
            } else if let unitInfo = availableUnits.first(where: { $0.unit == currentUnit }) {
                currentUnitInfo = unitInfo
            }
        } catch {
            print("获取单元失败: \(error)")
            availableUnits = [UnitInfo(unit: 1, wordCount: 0)]
        }
    }
    
    func fetchWordsForCurrentSelection(grade: Int16, semester: Int16, unit: Int16) {
        let request = Word.fetchRequest()
        request.predicate = NSPredicate(
            format: "grade == %d AND semester == %d AND unit == %d",
            grade, semester, unit
        )
        // 按照创建时间排序
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        
        do {
            let words = try viewContext.fetch(request)
            selectedWords = words
        } catch {
            print("获取单词失败: \(error)")
            selectedWords = []
        }
    }
    
    func fetchUnitWordCount(grade: Int16, semester: Int16, unit: Int16) -> Int {
        let request = Word.fetchRequest()
        request.predicate = NSPredicate(
            format: "grade == %d AND semester == %d AND unit == %d",
            grade, semester, unit
        )
        
        do {
            return try viewContext.count(for: request)
        } catch {
            print("获取单元单词数量失败: \(error)")
            return 0
        }
    }
}