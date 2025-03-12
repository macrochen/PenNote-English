import Foundation
import CoreData

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "PenNote_English")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // 配置持久化存储选项
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("CoreData 加载错误: \(error), \(error.userInfo)")
                return
            }
        }
    }
    
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        // 添加预览数据
        let word = Word(context: context)
        word.id = UUID()
        word.english = "example"
        word.chinese = "示例"
        word.phonetic = "/ɪɡˈzɑːmpl/"
        word.importance = 0
        word.grade = 7
        word.semester = 1
        word.unit = 1
        word.createdAt = Date()
        word.updatedAt = Date()
        
        do {
            try context.save()
        } catch {
            print("预览数据保存失败: \(error)")
        }
        
        return controller
    }()
}