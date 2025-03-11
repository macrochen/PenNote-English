//
//  ReviewRecord+CoreDataProperties.swift
//  PenNote English
//
//  Created by jolin on 2025/3/10.
//
//

import Foundation
import CoreData


extension ReviewRecord {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReviewRecord> {
        return NSFetchRequest<ReviewRecord>(entityName: "ReviewRecord")
    }

    @NSManaged public var errorType: Int16
    @NSManaged public var id: UUID?
    @NSManaged public var isCorrect: Bool
    @NSManaged public var memoryStrength: Double
    @NSManaged public var reviewDate: Date?
    @NSManaged public var reviewInterval: Double
    @NSManaged public var word: Word?

}

extension ReviewRecord : Identifiable {

}
