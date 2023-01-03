//
//  XYPlotCoreDataManager.swift
//  for XYPlot settings and line settings
//  
//
//  Created by Joseph Levy on 12/11/22.
//

import Foundation
import CoreData

extension XYPlot { //use XYPlot namespace
    //public static var coreDataManager: CoreDataManager { CoreDataManager.shared }
    public class CoreDataManager {
        public static let shared = CoreDataManager() // singleton
        let persistentContainer: NSPersistentContainer
        init(inMemory: Bool = false) {
            persistentContainer = NSPersistentContainer(name: "XYPlot")
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
        
        public func getID(_ object: NSManagedObject) -> NSManagedObjectID { object.objectID }
        
        public func save() {
            do { try moc.save() }
            catch {
                moc.rollback()
                print(error.localizedDescription)
            }
        }
    }
}

extension PlotSettings {
    mutating public func copySettingsFromCoreData(id: NSManagedObjectID) {
        guard let settings = XYPlot.CoreDataManager.shared.getSettingsById(id: id) else { return }
        title = settings.title ?? title
        xAxis = AxisParameters(min: settings.xMin, max: settings.xMax, majorTics: Int(settings.xMajor), minorTics: Int(settings.xMinor), title: settings.xAxisTitle )
        yAxis = AxisParameters(min: settings.yMin, max: settings.yMax, majorTics: Int(settings.yMajor), minorTics: Int(settings.yMinor), title: settings.yAxisTitle )
        sAxis = AxisParameters(min: settings.sMin, max: settings.sMax, majorTics: Int(settings.sMajor), minorTics: Int(settings.sMinor), title: settings.sAxisTitle )
        sizeMinor = settings.sizeMinor
        sizeMajor = settings.sizeMajor
        format = settings.format ?? ""
        autoScale = settings.autoScale
        independentTics = settings.independentsTics
        legendPos = CGPoint(x: settings.legendPosX,y: settings.legendPosY)
        legend = settings.showLegend
    }
    
    mutating public func copyPlotSettingsToCoreData() {
        let coreDataManager = XYPlot.CoreDataManager.shared
        var settings: Settings
        if settingsID == nil  {
            print("Creating new Settings entity")
            // Create new CoreData Entity
            settings = Settings(context: coreDataManager.moc)
            settingsID = settings.objectID
        } else { settings = coreDataManager.getSettingsById(id: settingsID!)!}
        print("ID: \(String(describing: settingsID))")
        //let settings = newSettings//// ?? newSettings
        print("ID: \(String(describing: settings.objectID))")
        //guard let settings = settings else { return }
        print("Copying settings to Coredata")
        settings.title = title
        settings.xAxisTitle = xAxis?.title
        settings.yAxisTitle = yAxis?.title
        settings.sAxisTitle = sAxis?.title
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
        }
        if let axis = yAxis {
            settings.yMajor = Int64(axis.majorTics)
            settings.yMinor = Int64(axis.minorTics)
            settings.yMax = axis.max
            settings.yMin = axis.min
        }
        if let axis = sAxis {
            settings.sMajor = Int64(axis.majorTics)
            settings.sMinor = Int64(axis.minorTics)
            settings.sMax = axis.max
            settings.sMin = axis.min
        }
        settings.useSecondary = showSecondaryAxis
        coreDataManager.save()
    }
}
