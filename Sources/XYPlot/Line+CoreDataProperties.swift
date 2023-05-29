//
//  Line+CoreDataProperties.swift
//  XYPlot CoreData
//
//  Created by Joseph Levy on 12/11/22.
//
//

import Foundation
import CoreData


extension Line {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Line> {
        return NSFetchRequest<Line>(entityName: "Line")
    }
    
    @NSManaged public var lineColor: Int64
    @NSManaged public var lineName: String?
    @NSManaged public var lineStyle: Int64
    @NSManaged public var lineWidth: Double
    @NSManaged public var symbolColor: Int64
    @NSManaged public var symbolFilled: Bool
    @NSManaged public var symbolShape: String?
    @NSManaged public var symbolSize: Double
    @NSManaged public var useRightAxis: Bool
    @NSManaged public var lineCap: Int32
    @NSManaged public var lineJoin: Int32
    @NSManaged public var miterLimit: Float
    @NSManaged public var dashPhase: Float
    @NSManaged public var dash: [CGFloat]?
    @NSManaged public var symbolAngle: Double
    
}

extension Line : Identifiable {

}
