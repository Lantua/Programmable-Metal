//
//  ListViewController.swift
//  Via
//
//  Created by Lantua on 8/30/2560 BE.
//  Copyright © 2560 Natchanon Luangsomboon. All rights reserved.
//

import Foundation
import CoreData
import PersistentMetal

class ListViewController: UITableViewController, DocumentSubviewController, NSFetchedResultsControllerDelegate {
    var document: Document! { return (navigationController as! DocumentSubviewController?)?.document }

    var controller: NSFetchedResultsController<NSManagedObject>!
    var entityName: String { fatalError("Must override this") }
    var sortPrecedence: [String] { fatalError("Must override this") }
    func decorate(_ cell: UITableViewCell, with value: NSFetchRequestResult) { fatalError("Must Override this function") }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        (segue.destination as? DocumentPivotalSubviewController)?.document = document
        
        if segue.identifier == "Edit" || segue.identifier == "Add" {
            let destination: DetailViewController
            if let currentDest = segue.destination as? UINavigationController {
                destination = currentDest.topViewController! as! DetailViewController
            } else {
                destination = segue.destination as! DetailViewController
            }
            if segue.identifier == "Edit" {
                let index = tableView.indexPath(for: sender as! UITableViewCell)!
                destination.target = controller.object(at: index)
            } else {
                destination.target = NSEntityDescription.insertNewObject(forEntityName: entityName, into: controller.managedObjectContext)
            }
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) { tableView.beginUpdates() }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert: tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete: tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .move: break
        case .update: break
        }
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert: tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete: tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update: tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move: tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) { tableView.endUpdates() }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return controller.sections![section].numberOfObjects }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Entry")!
        decorate(cell, with: controller.object(at: indexPath))
        
        return cell
    }
    override func numberOfSections(in tableView: UITableView) -> Int { return controller.sections!.count }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { return controller.sections![section].name }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { return true }
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        assert(editingStyle == .delete)
        controller.managedObjectContext.delete(controller.object(at: indexPath))
    }
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "Save" {
            do {
                try controller.managedObjectContext.save()
            } catch {
                alert(message: error.localizedDescription, title: "Unable to Save", current: self)
                return false
            }
        }
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }

    func initController(context: NSManagedObjectContext, fetchRequest: NSFetchRequest<NSManagedObject>) {
        fetchRequest.sortDescriptors = sortPrecedence.map { NSSortDescriptor(key: $0, ascending: true) }
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: sortPrecedence.first!, cacheName: nil)
        controller.delegate = self
        
        self.controller = controller
        try! controller.performFetch()
    }
}

extension ComputationListViewController {
    func initController(context: NSManagedObjectContext, function: FunctionID) {
        initController(context: context, fetchRequest: FetchRequestHelper.computations(using: function))
    }
    func initController(context: NSManagedObjectContext, texture: Texture) {
        initController(context: context, fetchRequest: FetchRequestHelper.computations(using: texture))
    }
    func initController(context: NSManagedObjectContext, buffer: Buffer) {
        initController(context: context, fetchRequest: FetchRequestHelper.computations(using: buffer))
    }
}
extension TextureListViewController {
    func initController(context: NSManagedObjectContext, requirement: TextureRequirement) {
        self.requirement = requirement
        initController(context: context, fetchRequest: FetchRequestHelper.textures(ofType: requirement.type))
    }
}
extension BufferListViewController {
    func initController(context: NSManagedObjectContext, requirement: BufferRequirement) {
        self.requirement = requirement
        initController(context: context, fetchRequest: FetchRequestHelper.buffers(ofLength: requirement.length))
    }
}
