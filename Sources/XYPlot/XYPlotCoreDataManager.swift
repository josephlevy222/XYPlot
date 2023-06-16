//
//  XYPlotCoreDataManager.swift
//  for XYPlot settings and line settings
//
//
//  Created by Joseph Levy on 12/11/22.
//

import Foundation
import CoreData
import SwiftUI

extension XYPlot { //use XYPlot namespace
    //public static var coreDataManager: CoreDataManager { CoreDataManager.shared }
    public class CoreDataManager {
        public static let shared = CoreDataManager() // singleton
        let persistentContainer: NSPersistentContainer
        init(inMemory: Bool = false) {
            persistentContainer = NSPersistentContainer(name: "XYPlot.xcdatamodeld/PlotDataModel")
            if inMemory {
                persistentContainer.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            }
            persistentContainer.loadPersistentStores { (description, error) in
                if let error = error as NSError? {
                    fatalError("Unable to initialize core data: \(error), \(error.userInfo)")
                }
            }
            persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        }
        
        public var moc: NSManagedObjectContext { persistentContainer.viewContext }
        
        public func getSettings() -> [Settings] {
            let request: NSFetchRequest<Settings> = NSFetchRequest<Settings>(entityName: "Settings")
            do { return try moc.fetch(request) }
            catch { return [] }
        }
        
        public func getLines() -> [Line] {
            let request: NSFetchRequest<Line> = NSFetchRequest<Line>(entityName: "Line")
            do { return try moc.fetch(request)}
            catch { return [] }
        }
        
        public func getLineById(id: NSManagedObjectID) -> Line? {
            do {
                return try moc.existingObject(with: id) as? Line
            } catch {
                return nil
            }
        }
        
        public func getSettingsById(id: NSManagedObjectID) -> Settings? {
            do {
                return try moc.existingObject(with: id) as? Settings
            } catch {
                return nil
            }
        }
        
        public func save() {
            do { try moc.save() }
            catch {
                moc.rollback()
                print(error.localizedDescription)
            }
        }
    }
}

func decodeToAttributedString(_ data: Data?) -> AttributedString {
    var output: AttributedString
    do { output = try JSONDecoder().decode(AttributedString.self, from: data ?? Data() ) }
    catch { output = AttributedString("Could not decode to AttributedString")}
    return output.styledHeaders()
}

func encodeAttributedString(_ attrString: AttributedString? ) -> Data? {
    try? JSONEncoder().encode(attrString) }

extension PlotSettings {
    mutating public func copySettingsFromCoreData(id: NSManagedObjectID) {
        guard let settings = XYPlot.CoreDataManager.shared.getSettingsById(id: id) else { print("No Coredata to retrieve"); return }
        settingsID = id
        title = decodeToAttributedString(settings.title)
        xAxis = AxisParameters(min: settings.xMin, max: settings.xMax, majorTics: Int(settings.xMajor), minorTics: Int(settings.xMinor), title: decodeToAttributedString(settings.xAxisTitle))
        yAxis = AxisParameters(min: settings.yMin, max: settings.yMax, majorTics: Int(settings.yMajor), minorTics: Int(settings.yMinor), title: decodeToAttributedString(settings.yAxisTitle))
        sAxis = AxisParameters(min: settings.sMin, max: settings.sMax, majorTics: Int(settings.sMajor), minorTics: Int(settings.sMinor), title: decodeToAttributedString(settings.sAxisTitle))
        sizeMinor = settings.sizeMinor
        sizeMajor = settings.sizeMajor
        format = settings.format ?? ""
        autoScale = settings.autoScale
        independentTics = settings.independentsTics
        legendPos = CGPoint(x: settings.legendPosX,y: settings.legendPosY)
        legend = settings.showLegend
        showSecondaryAxis = settings.useSecondary
        
    }
    
    mutating public func copyPlotSettingsToCoreData() {
        let coreDataManager = XYPlot.CoreDataManager.shared
        var settings: Settings?
        if settingsID == nil  {
            print("Creating new Settings entity")
            // Create new CoreData Entity
            settings = Settings(context: coreDataManager.moc)
        } else { settings = coreDataManager.getSettingsById(id: settingsID!) }
        guard let settings = settings else { return }
        settingsID = settings.objectID
        print("Copying settings to Coredata")
        settings.title = encodeAttributedString(title)
        settings.autoScale = autoScale
        settings.format = format
        settings.independentsTics = independentTics
        settings.legendPosX = legendPos.x
        settings.legendPosY = legendPos.y
        settings.showLegend = legend
        settings.sizeMajor = sizeMajor
        settings.sizeMinor = sizeMinor
        if let axis = xAxis {
            settings.xMajor = Int64(axis.majorTics)
            settings.xMinor = Int64(axis.minorTics)
            settings.xMax = axis.max
            settings.xMin = axis.min
            settings.xAxisTitle = encodeAttributedString(axis.title)
        }
        if let axis = yAxis {
            settings.yMajor = Int64(axis.majorTics)
            settings.yMinor = Int64(axis.minorTics)
            settings.yMax = axis.max
            settings.yMin = axis.min
            settings.yAxisTitle = encodeAttributedString(axis.title)
        }
        if let axis = sAxis {
            settings.sMajor = Int64(axis.majorTics)
            settings.sMinor = Int64(axis.minorTics)
            settings.sMax = axis.max
            settings.sMin = axis.min
            settings.sAxisTitle = encodeAttributedString(axis.title)
        }
        settings.useSecondary = showSecondaryAxis
        coreDataManager.save()
    }
}

extension PlotLine {
    mutating public func copyLineSettingsToCoreData() {
        let coreDataManager = XYPlot.CoreDataManager.shared
        var line: Line
        if id == nil  {
            print("Creating new Line entity")
            // Create new CoreData Entity
            line = Line(context: coreDataManager.moc)
        } else { line = coreDataManager.getLineById(id: id!) ?? Line(context: coreDataManager.moc )}
        id = line.objectID
        ///   - lineColor: line color
        line.lineColor = Int64(lineColor.sARGB)
        ///   - lineStyle: line style
        line.lineWidth = lineStyle.lineWidth
        
        line.dash = lineStyle.dash // [CGFloat]
        line.dashPhase = Float(lineStyle.dashPhase)
        line.lineCap = lineStyle.lineCap.rawValue
        line.lineJoin = lineStyle.lineJoin.rawValue
        line.miterLimit = Float(lineStyle.miterLimit)
        
        ///   - pointColor: point symbol color
        line.symbolColor = Int64(pointColor.sARGB)
        ///   - pointShape: point symbol from ShapeParameters
        //line.symbolShape = pointShape
        line.symbolFilled = pointShape.filled
        line.symbolSize = pointShape.size
        line.symbolShape = pointShape.path(CGRect(origin: .zero, size:  CGSize(width: 1.0, height: 1.0))).description
        ///   - secondary: true if line should use secondary (right-side) axis
        line.useRightAxis = secondary
        ///   - legend: optional String of line name;
        line.lineName = legend
        line.symbolAngle = pointShape.angle.radians
        coreDataManager.save()
    }
    
    mutating public func copyLineSettingsFromCoreData(id: NSManagedObjectID?) {
        let coreDataManager = XYPlot.CoreDataManager.shared
        guard let id = id else { print("No Line entity");return }
        let line = coreDataManager.getLineById(id: id) ?? Line(context: coreDataManager.moc)
        self.id = line.objectID
        ///   - lineColor: line color
        lineColor = Color(sARGB: Int(line.lineColor))
        ///   - lineStyle: line style
        lineStyle.lineWidth = line.lineWidth
        lineStyle.dash = line.dash ?? []
        lineStyle.dashPhase = CGFloat(line.dashPhase)
        lineStyle.lineCap = CGLineCap(rawValue: line.lineCap) ?? .butt
        lineStyle.lineJoin = CGLineJoin(rawValue: line.lineJoin ) ?? .miter
        lineStyle.miterLimit =  CGFloat(line.miterLimit)
        ///   - pointColor: point symbol color
        pointShape.color = Color(sARGB: Int(line.symbolColor))
        ///   - pointShape: point symbol from ShapeParameters
        pointShape.filled = line.symbolFilled
        pointShape.size = line.symbolSize
        pointShape.path = { rect in
            Path(line.symbolShape ?? "")?
                .applying(CGAffineTransform(scaleX: rect.width, y: rect.height))
            ?? Polygon(sides: 4).path(in: rect)
        }
        ///   - secondary: true if line should use secondary (right-side) axis
        secondary = line.useRightAxis
        ///   - legend: optional String of line name;
        legend = line.lineName
        pointShape.angle = Angle(radians: line.symbolAngle)
    }
}

