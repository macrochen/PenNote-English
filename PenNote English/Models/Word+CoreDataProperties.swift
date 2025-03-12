//
//  Word+CoreDataProperties.swift
//  PenNote English
//
//  Created by jolin on 2025/3/12.
//
//

import Foundation
import CoreData


extension Word {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Word> {
        return NSFetchRequest<Word>(entityName: "Word")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var english: String?
    @NSManaged public var chinese: String?
    @NSManaged public var phonetic: String?
    @NSManaged public var importance: Int16
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var grade: Int16
    @NSManaged public var semester: Int16
    @NSManaged public var unit: Int16
    @NSManaged public var lesson: String?
    @NSManaged public var etymology: String?
    @NSManaged public var example: String?
    @NSManaged public var exampleTranslation: String?
    @NSManaged public var memoryTips: String?
    @NSManaged public var structure: String?
    @NSManaged public var partOfSpeech: String?
    @NSManaged public var wordResults: NSSet?

}

// MARK: Generated accessors for wordResults
extension Word {

    @objc(addWordResultsObject:)
    @NSManaged public func addToWordResults(_ value: WordResult)

    @objc(removeWordResultsObject:)
    @NSManaged public func removeFromWordResults(_ value: WordResult)

    @objc(addWordResults:)
    @NSManaged public func addToWordResults(_ values: NSSet)

    @objc(removeWordResults:)
    @NSManaged public func removeFromWordResults(_ values: NSSet)

}

extension Word : Identifiable {

}
