import Foundation
import CoreData

class PracticeViewModel: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    // MARK: - Published Properties
    @Published var currentGrade: Int16 = 7
    @Published var currentSemester: Int16 = 1
    @Published var selectedWords: [Word] = []
    @Published var availableGrades: [Int16] = []
    @Published var availableSemesters: [Int16] = []
    @Published var availableUnits: [UnitInfo] = []
    @Published var currentPracticeMode: PracticeMode = .none
    @Published var currentUnitInfo: UnitInfo = UnitInfo(unit: 1, wordCount: 0)
    
    // 在 PracticeViewModel 类中添加以下属性
    @Published var importanceFilter: Int16 = -1 // -1表示全部
    @Published var practiceStatusFilter: Int16 = 0 // 0表示全部，1表示未听写
    @Published var errorCountFilter: Int16 = 0 // 0表示全部，1-4表示对应错误次数
    
    // 修改为计算属性
    @Published var currentUnit: Int16 = 1 {
        didSet {
            if let unitInfo = availableUnits.first(where: { $0.unit == currentUnit }) {
                currentUnitInfo = unitInfo
            }
        }
    }
    
    // MARK: - Initialization
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        fetchAvailableGrades()
    }
    
    // MARK: - Types
    enum PracticeMode {
        case none
        case batch
        case single
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
            availableGrades = grades.isEmpty ? [1] : grades
            
            // 设置当前年级为第一个可用的年级
            currentGrade = availableGrades.first ?? 1
            
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
            availableSemesters = semesters.isEmpty ? [1] : semesters
            
            // 设置当前学期为第一个可用的学期
            currentSemester = availableSemesters.first ?? 1
            
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
            
            // 更新当前单元信息
            currentUnit = availableUnits.first?.unit ?? 1
            currentUnitInfo = availableUnits.first ?? UnitInfo(unit: 1, wordCount: 0)
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