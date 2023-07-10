//
//  Settings+CoreDataProperties.swift
//  XYPlotCoreData
//
//  Created by Joseph Levy on 12/11/22.
//
//

import Foundation
import CoreData
import UIKit

@objc(NSAttributedStringTransformer)
class NSAttributedStringTransformer: NSSecureUnarchiveFromDataTransformer {
    override class var allowedTopLevelClasses: [AnyClass] {
        return super.allowedTopLevelClasses + [NSAttributedString.self]
    }
}

extension Settings {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Settings> {
        return NSFetchRequest<Settings>(entityName: "Settings")
    }
    
    @NSManaged public var independentsTics: Bool
    @NSManaged public var legendPosX: Double
    @NSManaged public var legendPosY: Double
    @NSManaged public var sAxisTitle: NSAttributedString?
    @NSManaged public var sMajor: Int64
    @NSManaged public var sMinor: Int64
    @NSManaged public var title: NSAttributedString?
    @NSManaged public var useSecondary: Bool
    @NSManaged public var xAxisTitle: NSAttributedString?
    @NSManaged public var xMajor: Int64
    @NSManaged public var xMax: Double
    @NSManaged public var xMin: Double
    @NSManaged public var xMinor: Int64
    @NSManaged public var yAxisTitle: NSAttributedString?
    @NSManaged public var yMajor: Int64
    @NSManaged public var yMax: Double
    @NSManaged public var yMin: Double
    @NSManaged public var yMinor: Int64
    @NSManaged public var sMax: Double
    @NSManaged public var sMin: Double
    @NSManaged public var sizeMajor: Double
    @NSManaged public var sizeMinor: Double
    @NSManaged public var autoScale: Bool
    @NSManaged public var showLegend: Bool
    @NSManaged public var format: String?
}

extension Settings : Identifiable {
    
}

