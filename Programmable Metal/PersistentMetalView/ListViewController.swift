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

class ListViewController: UITableViewController, DocumentSubviewController {
    var document: Document! { return (navigationController as! DocumentSubviewController?)?.document }

    private var fetchRequest: NSFetchRequest<NSManagedObject>!
    var controller: NSFetchedResultsController<NSManagedObject>!
    var isFiltered: Bool { return fetchRequest.predicate != nil }
    
    var entity: NSEntityDescription { fatalError("Must override this") }
    var sortPrecedence: [String] { fatalError("Must override this") }
    func decorate(_ cell: UITableViewCell, with value: NSManagedObject) { fatalError("Must Override this function") }
    
    override func viewDidLoad() {
        controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: sortPrecedence.first!, cacheName: nil)
        controller.delegate = self
        try! controller.performFetch()
        super.viewDidLoad()
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        (segue.destination as? DocumentPivotalSubviewController)?.document = document
        
        if segue.identifier == "Edit" || segue.identifier == "Add" {
            let destination = (segue.destination as? DetailViewController) ?? (segue.destination as! UINavigationController).topViewController! as! DetailViewController
            if segue.identifier == "Edit" {
                let index = tableView.indexPath(for: sender as! UITableViewCell)!
                destination.target = controller.object(at: index)
            } else {
                destination.target = NSManagedObject(entity: entity, insertInto: nil)
            }
        }
    }
    
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
    func initFetchRequest(_ fetchRequest: NSFetchRequest<NSManagedObject>) {
        fetchRequest.sortDescriptors = sortPrecedence.map { NSSortDescriptor(key: $0, ascending: true) }
        self.fetchRequest = fetchRequest
    }
}

extension ListViewController: NSFetchedResultsControllerDelegate {
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert: tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete: tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update: tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move: if view.window == nil || !isEditing { tableView.moveRow(at: indexPath!, to: newIndexPath!) }
        }
    }
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert: tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete: tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default: fatalError()
        }
    }
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) { tableView.beginUpdates() }
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) { tableView.endUpdates() }
}

extension ComputationListViewController {
    func initFetchRequest(function: FunctionID) { initFetchRequest(FetchRequestHelper.computations(using: function)) }
    func initFetchRequest(texture: Texture) { initFetchRequest(FetchRequestHelper.computations(using: texture)) }
    func initFetchRequest(buffer: Buffer) { initFetchRequest(FetchRequestHelper.computations(using: buffer)) }
}
extension TextureListViewController {
    func initFetchRequest(requirement: TextureRequirement) {
        self.requirement = requirement
        initFetchRequest(FetchRequestHelper.textures(ofType: requirement.type))
    }
}
extension BufferListViewController {
    func initFetchRequest(requirement: BufferRequirement) {
        self.requirement = requirement
        initFetchRequest(FetchRequestHelper.buffers(ofLength: requirement.length))
    }
}
