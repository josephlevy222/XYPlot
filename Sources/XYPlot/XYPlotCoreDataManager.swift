//
//  XYPlotCoreDataManager.swift
//  for XYPlot settings and line settings
//  
//
//  Created by Joseph Levy on 12/11/22.
//

import Foundation
import CoreData

@objc(Line)
public class Line: NSManagedObject { }
@objc(Settings)
public class Settings: NSManagedObject { }

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
