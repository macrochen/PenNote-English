//
//  Word+CoreDataProperties.swift
//  PenNote English
//
//  Created by jolin on 2025/3/11.
//
//

import Foundation
import CoreData


extension Word {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Word> {
        return NSFetchRequest<Word>(entityName: "Word")
    }

    @NSManaged public var chinese: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var english: String?
    @NSManaged public var errorCount: Int16
    @NSManaged public var etymology: String?
    @NSManaged public var example: String?
    @NSManaged public var exampleTranslation: String?
    @NSManaged public var id: UUID?
    @NSManaged public var memoryTips: String?
    @NSManaged public var status: Int16
    @NSManaged public var structure: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var phonetic: String?
    @NSManaged public var reviewRecords: NSSet?

}

// MARK: Generated accessors for reviewRecords
extension Word {

    @objc(addReviewRecordsObject:)
    @NSManaged public func addToReviewRecords(_ value: ReviewRecord)

    @objc(removeReviewRecordsObject:)
    @NSManaged public func removeFromReviewRecords(_ value: ReviewRecord)

    @objc(addReviewRecords:)
    @NSManaged public func addToReviewRecords(_ values: NSSet)

    @objc(removeReviewRecords:)
    @NSManaged public func removeFromReviewRecords(_ values: NSSet)

}

extension Word : Identifiable {

}
