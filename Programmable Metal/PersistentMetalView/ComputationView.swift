//
//  ComputationsView.swift
//  Via
//
//  Created by Lantua on 8/28/2560 BE.
//  Copyright © 2560 Natchanon Luangsomboon. All rights reserved.
//

import Foundation
import CoreData
import PersistentMetal

class BufferCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var offset: UITextField!
}

private enum Section: Int {
    enum SettingEntry: Int {
        case group = 0, name, function
        static var count: Int { return function.rawValue + 1 }
    }
    enum SizeEntry: Int {
        case threadgroup = 0, grid
        static var count: Int { return grid.rawValue + 1 }
    }
    case settings = 0, size, texture, buffer
    static var count: Int { return buffer.rawValue + 1 }
}

class ComputationListViewController: ListViewController {
    @IBAction func editedComputation(_ segue: UIStoryboardSegue) { }
    @IBAction func toggleEditing(_ sender: Any) {
        setEditing(!isEditing, animated: true)
    }
    
    override var entityName: String { return Computation.entity().name! }
    override var sortPrecedence: [String] { return ["group", "order"] }
    override func initFetchRequest(_ fetchRequest: NSFetchRequest<NSManagedObject>) {
        fetchRequest.relationshipKeyPathsForPrefetching = ["functionID"]
        super.initFetchRequest(fetchRequest)
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let computation = controller.object(at: indexPath) as! Computation
        if computation.order != indexPath.row {
            computation.order = Int16(indexPath.row)
        }
        let result = super.tableView(tableView, cellForRowAt: indexPath)
        return result
    }
    override func decorate(_ cell: UITableViewCell, with computation: NSFetchRequestResult) {
        let computation = computation as! Computation
        cell.textLabel!.text = computation.name
        if let function = computation.functionID {
            cell.detailTextLabel!.text = "\(function.name!):\(function.group!)"
        }
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool { return true }
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        switch (sourceIndexPath.section, proposedDestinationIndexPath.section) {
        case let (s, d) where s < d: return IndexPath(row: self.tableView(tableView, numberOfRowsInSection: s) - 1, section: s)
        case let (s, d) where s > d: return IndexPath(row: 0, section: s)
        case let (s, d) where s == d: return proposedDestinationIndexPath
        default: fatalError()
        }
    }
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        assert(sourceIndexPath.section == destinationIndexPath.section)
        let section = sourceIndexPath.section
        let sourceRow = sourceIndexPath.row, destinationRow = destinationIndexPath.row
        let range = min(sourceRow, destinationRow)...max(sourceRow, destinationRow)
        var computations = range.map { controller.object(at: IndexPath(row: $0, section: section)) as! Computation }
        
        if sourceRow < destinationRow {
            computations = Array(computations.dropFirst()) + [computations.first!]
        } else {
            computations = [computations.last!] + Array(computations.dropLast())
        }
        
        for (row, computation) in zip(range, computations) {
            computation.order = Int16(row)
        }
        
        try! controller.performFetch()
    }
}

class ComputationDetailViewController: UITableViewController, DetailViewController {
    var document: Document! { return (navigationController as! DocumentNavigationController?)?.document }
    
    var temp: Computation!
    var context: NSManagedObjectContext! { return temp?.managedObjectContext }
    var target: NSFetchRequestResult! {
        get { return temp }
        set { temp = newValue as! Computation }
    }
    
    @IBOutlet var groupCell: UITableViewCell!
    @IBOutlet var nameCell: UITableViewCell!
    @IBOutlet var functionCell: UITableViewCell!
    
    @IBOutlet var threadgroupCell: UITableViewCell!
    @IBOutlet var gridCell: UITableViewCell!
    
    @IBOutlet weak var group: UITextField!
    @IBOutlet weak var name: UITextField!
    
    @IBOutlet weak var threadgroupWidth: UITextField!
    @IBOutlet weak var threadgroupHeight: UITextField!
    @IBOutlet weak var threadgroupDepth: UITextField!
    
    @IBOutlet weak var gridWidth: UITextField!
    @IBOutlet weak var gridHeight: UITextField!
    @IBOutlet weak var gridDepth: UITextField!
    
    @IBAction func selectComputation(_ segue: UIStoryboardSegue) {}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        group.text = temp.group
        name.text = temp.name
        if let function = temp.functionID {
            functionCell.detailTextLabel!.text = "\(function.name!):\(function.group!)"
        } else {
            functionCell.detailTextLabel!.text = ""
        }
        
        threadgroupWidth.text = String(temp.tgWidth)
        threadgroupHeight.text = String(temp.tgHeight)
        threadgroupDepth.text = String(temp.tgDepth)
        
        gridWidth.text = String(temp.gWidth)
        gridHeight.text = String(temp.gHeight)
        gridDepth.text = String(temp.gDepth)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
        case "ListTexture":
            let indexPath = tableView.indexPath(for: sender as! UITableViewCell)!
            let (requirement, _) = textureEntry(at: indexPath.row)
            let destination = segue.destination as! TextureListViewController
            destination.initFetchRequest(requirement: requirement)
            destination.navigationItem.title = "Select \(requirement.name)"
        case "ListBuffer":
            let indexPath = tableView.indexPath(for: sender as! UITableViewCell)!
            let (requirement, _) = bufferEntry(at: indexPath.row)
            let destination = segue.destination as! BufferListViewController
            destination.initFetchRequest(requirement: requirement)
            destination.navigationItem.title = "Select \(requirement.name)"
         case "ListFunction":
            let destination = segue.destination as! FunctionListViewController
            destination.initFetchRequest(FunctionID.fetchRequest() as NSFetchRequest<FunctionID> as! NSFetchRequest<NSManagedObject>)
        case "Done": break
        default: fatalError()
        }
    }
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        tableView.endEditing(true)
        if identifier == "Done" && !validateForUpdate(temp, from: self) { return false }
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }
    @IBAction func selectFunction(_ segue: FunctionSegue) {
        let newFunction = segue.functionID!
        if temp.functionID != newFunction {
            temp.functionID = newFunction
            let context = self.context
            for entry in temp.textureEntries! as! Set<TextureEntry> {
                context!.delete(entry)
            }
            for entry in temp.bufferEntries! as! Set<BufferEntry> {
                context!.delete(entry)
            }
            tableView.reloadData()
        }
    }
    @IBAction func selectTexture(_ segue: TextureSegue) {
        let data = segue.texture!, indexPath = tableView.indexPathForSelectedRow!
        let (requirement, entry) = textureEntry(at: indexPath.row)
        if let entry = entry {
            if entry.texture != data {
                entry.texture = data
            } else { return }
        } else {
            let entry = TextureEntry(context: context)
            entry.computation = temp
            entry.index = requirement.index
            entry.texture = data
        }
        tableView.reloadData()
    }
    @IBAction func selectBuffer(_ segue: BufferSegue) {
        let data = segue.buffer!, indexPath = tableView.indexPathForSelectedRow!
        let (requirement, currentEntry) = bufferEntry(at: indexPath.row)
        let entry: BufferEntry
        if let currentEntry = currentEntry {
            entry = currentEntry
        } else {
            entry = BufferEntry(context: context)
            entry.computation = temp
            entry.index = requirement.index
            entry.offset = 0
        }
        if entry.buffer != data {
            entry.buffer = data
        }
        tableView.reloadData()
    }
}

extension ComputationDetailViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        if temp.functionID != nil && functionCache.pipelineState(for: temp.functionID!) != nil {
            return Section.count
        }
        return Section.size.rawValue + 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .settings: return Section.SettingEntry.count
        case .size: return Section.SizeEntry.count
        case .texture: return functionCache.textureRequirement(for: temp.functionID!).count
        case .buffer: return functionCache.bufferRequirement(for: temp.functionID!).count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .settings: return "Settings"
        case .size: return "Sizes"
        case .buffer: return "Buffers"
        case .texture: return "Textures"
        }
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.row, Section(rawValue: indexPath.section)!) {
        case (Section.SettingEntry.group.rawValue, .settings): return groupCell
        case (Section.SettingEntry.name.rawValue, .settings): return nameCell
        case (Section.SettingEntry.function.rawValue, .settings): return functionCell
        case (_, .settings): fatalError()
        case (Section.SizeEntry.threadgroup.rawValue, .size): return threadgroupCell
        case (Section.SizeEntry.grid.rawValue, .size): return gridCell
        case (_, .size): fatalError()
        case (let row, .texture):
            let (requirement, entry) = textureEntry(at: row)
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextureCell")!
            cell.textLabel!.text = "\(requirement.index)) \(requirement.name)"
            cell.detailTextLabel!.text = entry?.texture?.name
            return cell
        case  (let row, .buffer):
            let (requirement, entry) = bufferEntry(at: row)
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "BufferCell")! as! BufferCell
            cell.detailLabel!.text = entry?.buffer?.name
            cell.titleLabel!.text = "\(requirement.index)) \(requirement.name)"
            
            let offset = cell.offset!
            offset.tag = 9 + row
            offset.addTarget(self, action: #selector(bufferOffsetDidChange(_:)), for: .editingDidEnd)
            offset.delegate = self
            if let entry = entry {
                offset.isEnabled = true
                offset.text = String(entry.offset)
            } else {
                offset.isEnabled = false
                offset.text = "-"
            }
            return cell
        }
    }
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let section = Section(rawValue: indexPath.section)
        if section == .buffer {
            return bufferEntry(at: indexPath.row).1 != nil
        }
        if section == .texture {
            return textureEntry(at: indexPath.row).1 != nil
        }
        return false
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = Section(rawValue: indexPath.section)
        if section == .buffer { return 88 }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let cell = tableView.cellForRow(at: indexPath)
            
            let section = Section(rawValue: indexPath.section)!
            assert([Section.texture, .buffer].contains(Section(rawValue: indexPath.section)!))
     
            let entry: NSManagedObject?
            switch section {
            case .texture:
                entry = textureEntry(at: indexPath.row).1
                cell?.detailTextLabel?.text = ""
            case .buffer:
                entry = bufferEntry(at: indexPath.row).1
                if let cell = cell as! BufferCell? {
                    cell.offset.text = "-"
                    cell.offset.isEnabled = false
                    cell.detailLabel.text = ""
                }
            default: fatalError()
            }
            if let entry = entry {
                context.delete(entry)
            }
        }
        tableView.setEditing(false, animated: true)
    }
}
extension ComputationDetailViewController {
    func textureEntry(at row: Int) -> (TextureRequirement, TextureEntry?) {
        let requirement = functionCache.textureRequirement(for: temp.functionID!)[row]
        let first = (temp.textureEntries as! Set<TextureEntry>).first { $0.index == requirement.index }
        
        return (requirement, first)
    }
    func bufferEntry(at row: Int) -> (BufferRequirement, BufferEntry?) {
        let requirement = functionCache.bufferRequirement(for: temp.functionID!)[row]
        let first = (temp.bufferEntries as! Set<BufferEntry>).first { $0.index == requirement.index }
        
        return  (requirement, first)
    }
}

extension ComputationDetailViewController {
    @IBAction func groupDidChange(_ sender: UITextField) { temp.group = sender.text }
    @IBAction func nameDidChange(_ sender: UITextField) { temp.name = sender.text }
    @IBAction func bufferOffsetDidChange(_ offset: UITextField) {
        guard let index = tableView.indexPath(for: offset.superview!.superview! as! BufferCell) else {
            return
        }
        assert(Section(rawValue: index.section) == .buffer)
        let (_, entry) = bufferEntry(at: index.row)
        synchronize(source: Int32(offset.text!), destination: &entry!.offset) { offset.text = String($0) }
    }
}

extension ComputationDetailViewController {
    @IBAction func threadgroupWidthDidChange(_ sender: UITextField) {
        synchronize(source: Int16(sender.text!), destination: &temp.tgWidth) { sender.text = String($0) }
    }
    @IBAction func threadgroupHeightDidChange(_ sender: UITextField) {
        synchronize(source: Int16(sender.text!), destination: &temp.tgHeight) { sender.text = String($0) }
    }
    @IBAction func threadgroupDepthDidChange(_ sender: UITextField) {
        synchronize(source: Int16(sender.text!), destination: &temp.tgDepth) { sender.text = String($0) }
    }
    @IBAction func gridWidthDidChange(_ sender: UITextField) {
        synchronize(source: Int16(sender.text!), destination: &temp.gWidth) { sender.text = String($0) }
    }
    @IBAction func gridHeightDidChange(_ sender: UITextField) {
        synchronize(source: Int16(sender.text!), destination: &temp.gHeight) { sender.text = String($0) }
    }
    @IBAction func gridDepthDidChange(_ sender: UITextField) {
        synchronize(source: Int16(sender.text!), destination: &temp.gDepth) { sender.text = String($0) }
    }
}

extension ComputationDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if tableView.viewWithTag(textField.tag + 1)?.becomeFirstResponder() != true {
            textField.resignFirstResponder()
        }
        return false
    }
}
