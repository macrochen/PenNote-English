//
//  Persistence.swift
//  PenNote English
//
//  Created by jolin on 2025/3/10.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // 创建示例单词数据
        let word = Word(context: viewContext)
        word.id = UUID()
        word.english = "example"
        word.chinese = "例子，实例"
        word.etymology = "来自拉丁语 exemplum"
        word.structure = "ex-(out) + emere(take) + -plum(thing)"
        word.example = "This is an example sentence."
        word.exampleTranslation = "这是一个示例句子。"
        word.memoryTips = "ex- means \"out\", root em- means \"take\", the whole word means \"something taken out as a sample\""
        word.createdAt = Date()
        word.updatedAt = Date()
        word.status = 0
        word.errorCount = 0
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "PenNote_English")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
