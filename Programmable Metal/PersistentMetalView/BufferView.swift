//
//  BufferView.swift
//  Via
//
//  Created by Lantua on 8/30/2560 BE.
//  Copyright © 2560 Natchanon Luangsomboon. All rights reserved.
//

import Foundation
import CoreData
import PersistentMetal
import Metal

class BufferListViewController: ListViewController {
    var requirement: BufferRequirement?
    @IBAction func editedBuffer(_ segue: UIStoryboardSegue) { }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        (segue as? BufferSegue)?.buffer = controller.object(at: tableView.indexPathForSelectedRow!) as! Buffer
        
        if let requirement = requirement, segue.identifier == "Add" || segue.identifier == "Edit" {
            let destination = segue.destination as! BufferDetailViewController
            destination.requirement = requirement
        }
    }
    override var entityName: String { return Buffer.entity().name! }
    override var sortPrecedence: [String] { return ["group", "name"] }
    override func initFetchRequest(_ fetchRequest: NSFetchRequest<NSManagedObject>) {
        fetchRequest.relationshipKeyPathsForPrefetching = ["entries"]
        super.initFetchRequest(fetchRequest)
    }
    override func decorate(_ cell: UITableViewCell, with buffer: NSFetchRequestResult) {
        let buffer = buffer as! Buffer
        cell.textLabel!.text = buffer.name
        cell.detailTextLabel?.text = String(buffer.entries!.count)
    }
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return (controller.object(at: indexPath) as! Buffer).entries!.count == 0
    }
}

class BufferDetailViewController: UITableViewController, DetailViewController {
    var document: Document! { return (navigationController as! DocumentNavigationController?)?.document }
    
    var requirement: BufferRequirement?, temp: Buffer!
    var target: NSFetchRequestResult! {
        get { return temp }
        set { temp = newValue as! Buffer }
    }

    @IBOutlet weak var group: UITextField!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var length: UITextField!
    @IBOutlet weak var persistence: UISwitch!
    @IBOutlet weak var storageMode: UITextField!
    @IBOutlet weak var storageModePicker: UIPickerView!
    @IBOutlet weak var cpuCacheModeWriteCombined: UISwitch!
    @IBOutlet weak var hazardTrackingModeUntracked: UISwitch!
    
    @IBOutlet weak var doneToolbar: UIToolbar!
    
    @IBAction func donePicking(_ sender: UIBarButtonItem) { view.endEditing(false) }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let requirement = requirement {
            temp.length = max(temp.length, requirement.length)
        }
        storageMode.inputView = storageModePicker
        storageMode.inputAccessoryView = doneToolbar
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        group.text = temp.group
        name.text = temp.name
        length.text = String(temp.length)
        cpuCacheModeWriteCombined.isOn = temp.resourceOptions.contains(.cpuCacheModeWriteCombined)
        hazardTrackingModeUntracked.isOn = temp.resourceOptions.contains(.hazardTrackingModeUntracked)
        persistence.isOn = temp.data != nil

        storageMode.text = StorageModePickerDelegate.text(resourceOptions: temp.resourceOptions)
        storageModePicker.selectRow(StorageModePickerDelegate.index(of: temp.resourceOptions), inComponent: 0, animated: false)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let identifier = segue.identifier else { return }
        switch identifier {
        case "ListComputation":
            let destination = segue.destination as! ComputationListViewController
            destination.initFetchRequest(buffer: temp)
        case "Done": break
        default: fatalError()
        }
    }
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        tableView.endEditing(true)
        if identifier == "Done" && !validateForUpdate(temp, from: self) { return false }
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }
}

extension BufferDetailViewController {
    @IBAction func groupChanged(_ sender: UITextField) { temp.group = sender.text }
    @IBAction func nameChanged(_ sender: UITextField) { temp.name = sender.text }
    @IBAction func lengthChanged(_ sender: UITextField) {        
        let validator: (Int32) -> Int32 = {
            if let requirement = self.requirement, requirement.length > $0 {
                return requirement.length
            }
            return $0
        }
        synchronize(source: Int32(sender.text!), destination: &temp.length, validate: validator) { sender.text = String($0) }
    }
    @IBAction func persistenceChanged(_ sender: UISwitch) {
        if sender.isOn != (temp.data != nil) {
            temp.data = sender.isOn ? Data.init(count: Int(temp.length)) : nil
        }
        tableView.endEditing(true)
    }
    @IBAction func storageModeChanged(_ sender: UITextField) {
        temp.resourceOptions.remove([.storageModeShared, .storageModePrivate, .storageModeMemoryless])
        temp.resourceOptions.insert(StorageModePickerDelegate.resourceOptions(at: storageModePicker.selectedRow(inComponent: 0)))
    }
    @IBAction func cpuCacheModeChanged(_ sender: UISwitch) {
        if sender.isOn {
            temp.resourceOptions.insert(.cpuCacheModeWriteCombined)
        } else {
            temp.resourceOptions.remove(.cpuCacheModeWriteCombined)
        }
        tableView.endEditing(true)
    }
    @IBAction func hazardTrackingModeChanged(_ sender: UISwitch) {
        if sender.isOn {
            temp.resourceOptions.insert(.hazardTrackingModeUntracked)
        } else {
            temp.resourceOptions.remove(.hazardTrackingModeUntracked)
        }
        tableView.endEditing(true)
    }
}

extension BufferDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if tableView.viewWithTag(textField.tag + 1)?.becomeFirstResponder() != true {
            textField.resignFirstResponder()
        }
        return false
    }
}
