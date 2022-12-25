//
//  CoreDataManager.swift
//  for XYPlot settings and line settings
//  
//
//  Created by Joseph Levy on 12/11/22.
//

import Foundation
import CoreData
extension XYPlot { //use XYPlot namespace
    public static var coreDataManager: CoreDataManager { CoreDataManager.shared }
    public class CoreDataManager {
        static let shared = CoreDataManager() // singleton
        let persistentContainer: NSPersistentContainer
        private init(inMemory: Bool = false) {
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
        
        var moc: NSManagedObjectContext { persistentContainer.viewContext }
        
        func getSettings() -> Settings {
            let request: NSFetchRequest<Settings> = Settings.fetchRequest()
            do { return try moc.fetch(request)[0] }
            catch {
                defer { save() }
                let newSettings = Settings(context: moc)
                return newSettings
            }
        }
        
        func getLines() -> [Line] {
            let request: NSFetchRequest<Line> = Line.fetchRequest()
            do { return try moc.fetch(request)}
            catch { return [] }
        }
        
        func getLineById(id: NSManagedObjectID) -> Line? {
            do {
                return try moc.existingObject(with: id) as? Line
            } catch {
                return nil
            }
        }
        
        func save() {
            do { try moc.save() }
            catch {
                moc.rollback()
                print(error.localizedDescription)
            }
        }
    }
}
