//
//  FunctionView.swift
//  Via
//
//  Created by Lantua on 9/14/2560 BE.
//  Copyright © 2560 Natchanon Luangsomboon. All rights reserved.
//

import Foundation
import UIKit
import Metal
import CoreData

import PersistentMetal

class FunctionListViewController: ListViewController {
    @IBAction func editedFunction(_ segue: UIStoryboardSegue) { }
    @IBAction func refresh(_ sender: UIBarButtonItem) {
        functionCache.reset()
        let libraries = functionCache.libraries
        let database = controller.fetchedObjects! as! [FunctionID]
        let context = controller.managedObjectContext
        var toDelete: [FunctionID] = []
        for (group, library) in libraries {
            let database = database.filter { $0.group == group }
            let expected = Set(library.functionNames.filter { library.makeFunction(name: $0)!.functionType == .kernel })
            
            for missing in expected.subtracting(database.map { $0.name! }) {
                let newFunction = FunctionID(context: context)
                newFunction.name = missing
                newFunction.group = group
            }
            toDelete.append(contentsOf: database.filter { !expected.contains($0.name!) })
        }
        let keys = Set(libraries.keys)
        toDelete.append(contentsOf: database.filter { !keys.contains($0.group!) })
        let undeletableCount = toDelete.partition { ($0.computations! as! Set<Computation>).isEmpty }
        let undeletable = toDelete.prefix(upTo: undeletableCount)
        let deletable = toDelete.suffix(from: undeletableCount)
        deletable.forEach(context.delete)
        
        if !undeletable.isEmpty {
            undeletable.forEach { $0.group = "*" }
            alert(message: "Functions in used are moved to `*` group.", title: "Unable to delete \(undeletableCount) functions", current: self)
        }
    }
    
    override var entity: NSEntityDescription { return FunctionID.entity() }
    override var sortPrecedence: [String] { return ["group", "name"] }
    override func initFetchRequest(_ fetchRequest: NSFetchRequest<NSManagedObject>) {
        fetchRequest.relationshipKeyPathsForPrefetching = ["computations"]
        super.initFetchRequest(fetchRequest)
    }
    override func decorate(_ cell: UITableViewCell, with function: NSManagedObject) {
        let function = function as! FunctionID
        cell.textLabel!.text = function.name
        cell.detailTextLabel!.text = String(function.computations!.count)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return (controller.object(at: indexPath) as! FunctionID).computations!.count == 0
    }
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let group = (controller.object(at: indexPath) as! FunctionID).group!
        super.tableView(tableView, commit: editingStyle, forRowAt: indexPath)
        if try! context.functionCount(of: group) == 0 {
            try! FileManager.default.removeItem(at: document.metalLibrariesURL.appendingPathComponent("\(group).metallib"))
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        (segue as? FunctionSegue)?.functionID = controller.object(at: tableView.indexPathForSelectedRow!) as! FunctionID
    }
}

class FunctionDetailViewController: UITableViewController, DetailViewController {
    var document: Document! { return (navigationController as! DocumentNavigationController?)?.document }
    
    var temp: FunctionID!
    var target: NSFetchRequestResult! {
        get { return temp }
        set { temp = newValue as! FunctionID }
    }

    @IBOutlet weak var group: UITableViewCell!
    @IBOutlet weak var name: UITableViewCell!
    @IBOutlet weak var threadExecutionWidthCell: UITableViewCell!
    @IBOutlet weak var maxThreadPerThreadGroupCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = temp.name
        group.detailTextLabel!.text = temp.group
        name.detailTextLabel!.text = temp.name
        if let unmanaged = functionCache.pipelineState(for: temp) {
            threadExecutionWidthCell.detailTextLabel!.text = String(unmanaged.maxTotalThreadsPerThreadgroup)
            maxThreadPerThreadGroupCell.detailTextLabel!.text = String(unmanaged.threadExecutionWidth)
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let identifier = segue.identifier else { return }
        switch identifier {
        case "ListComputation":
            let destination = segue.destination as! ComputationListViewController
            destination.initFetchRequest(function: temp)
        case "Done": break
        default: fatalError()
        }
    }
}
