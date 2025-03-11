//
//  LearningStats+CoreDataProperties.swift
//  PenNote English
//
//  Created by jolin on 2025/3/10.
//
//

import Foundation
import CoreData


extension LearningStats {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LearningStats> {
        return NSFetchRequest<LearningStats>(entityName: "LearningStats")
    }

    @NSManaged public var correctCount: Int16
    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var masteredCount: Int16
    @NSManaged public var newWordsCount: Int16
    @NSManaged public var reviewedCount: Int16
    @NSManaged public var totalTime: Double

}

extension LearningStats : Identifiable {

}
