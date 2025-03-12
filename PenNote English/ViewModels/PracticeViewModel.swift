import Foundation
import CoreData

class PracticeViewModel: ObservableObject {
    private let viewContext: NSManagedObjectContext
    @Published var selectedWords: [Word] = []
    @Published var currentPracticeMode: PracticeMode = .none
    
    @Published var availableGrades: [Int16] = []
    @Published var availableSemesters: [Int16] = []
    @Published var availableUnits: [Int16] = []
    
    @Published var currentGrade: Int16 = 1
    @Published var currentSemester: Int16 = 1
    @Published var currentUnit: Int16 = 1
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    enum PracticeMode {
        case none
        case batch
        case single
    }
    
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
    
    func fetchAvailableUnits(for grade: Int16, semester: Int16) {
        let request = NSFetchRequest<NSDictionary>(entityName: "Word")
        request.propertiesToFetch = ["unit"]
        request.resultType = .dictionaryResultType
        request.predicate = NSPredicate(format: "grade == %d AND semester == %d", grade, semester)
        
        do {
            let results = try viewContext.fetch(request)
            let units = Set(results.compactMap { $0["unit"] as? Int16 }).sorted()
            availableUnits = units.isEmpty ? [1] : units
            
            // 设置当前单元为第一个可用的单元
            currentUnit = availableUnits.first ?? 1
        } catch {
            print("获取单元失败: \(error)")
            availableUnits = [1]
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
}