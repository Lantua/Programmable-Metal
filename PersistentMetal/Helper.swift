//
//  Helper.swift
//  PersistentMetal
//
//  Created by Lantua on 9/20/2560 BE.
//  Copyright © 2560 Lantua. All rights reserved.
//

import CoreData

typealias ID = NSManagedObjectID
let bundle = Bundle(for: PersistentMetalHelper.self)
let model = PersistentMetalHelper.model

public class PersistentMetalHelper {
    public let container: NSPersistentContainer
    public static var model = NSManagedObjectModel(contentsOf: bundle.url(forResource: "WiringModel", withExtension: "momd")!)!
    private let loadingGroup = DispatchGroup()
    
    public init() {
        container = NSPersistentContainer(name: "WiringModel", managedObjectModel: PersistentMetalHelper.model)
        loadingGroup.enter()
        container.loadPersistentStores {
            (_, error) in
            assert(error == nil)
            self.loadingGroup.leave()
        }
    }
    
    public func loadContext(fileName: URL) throws -> NSManagedObjectContext {
        loadingGroup.wait()
        
        let context = container.viewContext
        let coordinator = context.persistentStoreCoordinator!
        
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: fileName, options: nil)
        
        return context
    }
}


