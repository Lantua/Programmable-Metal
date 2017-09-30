//
//  TextureView.swift
//  Via
//
//  Created by Lantua on 8/30/2560 BE.
//  Copyright © 2560 Natchanon Luangsomboon. All rights reserved.
//

import Foundation
import CoreData
import PersistentMetal

class TextureListViewController: ListViewController {
    var requirement: TextureRequirement?
    @IBAction func editedTexture(_ segue: UIStoryboardSegue) {
        if requirement != nil {
            performSegue(withIdentifier: "Select", sender: (segue.source as! TextureDetailViewController).temp!)
        }
    }
    
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        (segue as? TextureSegue)?.texture = (sender as? Texture) ?? controller.object(at: tableView.indexPathForSelectedRow!) as! Texture
        
        if let requirement = requirement, segue.identifier == "Add" || segue.identifier == "Edit" {
            let destination = segue.destination as! TextureDetailViewController
            destination.requirement = requirement
        }
    }
    override var entityName: String { return Texture.entity().name! }
    override var sortPrecedence: [String] { return ["group", "name"] }
    override func initFetchRequest(_ fetchRequest: NSFetchRequest<NSManagedObject>) {
        fetchRequest.relationshipKeyPathsForPrefetching = ["entries"]
        super.initFetchRequest(fetchRequest)
    }
    override func decorate(_ cell: UITableViewCell, with texture: NSManagedObject) {
        let texture = texture as! Texture
        cell.textLabel!.text = texture.name
        cell.detailTextLabel?.text = String(texture.entries!.count)
    }
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return (controller.object(at: indexPath) as! Texture).entries!.count == 0
    }
}

class TextureDetailViewController: UITableViewController, DetailViewController {
    var document: Document! { return (navigationController as! DocumentNavigationController?)?.document }
    
    var requirement: TextureRequirement?, temp: Texture!
    var target: NSFetchRequestResult! {
        get { return temp }
        set { temp = newValue as! Texture }
    }

    @IBOutlet weak var group: UITextField!
    @IBOutlet weak var name: UITextField!
    
    @IBOutlet weak var width: UITextField!
    @IBOutlet weak var height: UITextField!
    @IBOutlet weak var depth: UITextField!
    
    @IBOutlet weak var type: UITextField!
    @IBOutlet weak var typePicker: UIPickerView!
    @IBOutlet weak var pixelFormat: UITextField!
    @IBOutlet weak var pixelFormatPicker: UIPickerView!
    @IBOutlet weak var storageMode: UITextField!
    @IBOutlet weak var storageModePicker: UIPickerView!
    
    @IBOutlet var shaderRead: UISwitch!
    @IBOutlet var shaderWrite: UISwitch!
    @IBOutlet var renderTarget: UISwitch!
    @IBOutlet var pixelFormatView: UISwitch!
    
    @IBOutlet var mipmap: UITextField!
    @IBOutlet var sampleCount: UITextField!
    @IBOutlet var arrayLength: UITextField!
    
    @IBOutlet var doneToolbar: UIToolbar!
    
    @IBAction func donePicking(_ sender: UIButton) { view.endEditing(false) }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let requirement = requirement {
            type.isEnabled = false
            type.text = String(TextureTypeDelegate.index(of: requirement.type))
            temp.textureType = requirement.type
        }
        type.inputView = typePicker
        type.inputAccessoryView = doneToolbar
        pixelFormat.inputView = pixelFormatPicker
        pixelFormat.inputAccessoryView = doneToolbar
        storageMode.inputView = storageModePicker
        storageMode.inputAccessoryView = doneToolbar
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        title = temp.name
        group.text = temp.group
        name.text = temp.name
        do {
            let size = temp.size
            width.text = String(size.width)
            height.text = String(size.height)
            depth.text = String(size.depth)
        }
        type.text = TextureTypeDelegate.text(of: temp.textureType)
        typePicker.selectRow(TextureTypeDelegate.index(of: temp.textureType), inComponent: 0, animated: false)
        storageMode.text = StorageModePickerDelegate.text(resourceOptions: temp.resourceOptions)
        storageModePicker.selectRow(StorageModePickerDelegate.index(of: temp.resourceOptions), inComponent: 0, animated: false)
        pixelFormat.text = PixelFormatDelegate.text(of: temp.pixelFormat)
        pixelFormatPicker.selectRow(PixelFormatDelegate.index(of: temp.pixelFormat), inComponent: 0, animated: false)
        
        let usage = temp.usage
        shaderRead.isOn = usage.contains(.shaderRead)
        shaderWrite.isOn = usage.contains(.shaderWrite)
        renderTarget.isOn = usage.contains(.renderTarget)
        pixelFormatView.isOn = usage.contains(.pixelFormatView)
        
        mipmap.text = String(temp.mipmapLevelCount)
        sampleCount.text = String(temp.sampleCount)
        arrayLength.text = String(temp.arrayLength)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let identifier = segue.identifier else { return }
        switch identifier {
        case "ListComputation":
            let destination = segue.destination as! ComputationListViewController
            destination.initFetchRequest(texture: temp)
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

extension TextureDetailViewController {
    @IBAction func groupDidChange(_ sender: UITextField) { temp.group = sender.text }
    @IBAction func nameDidChange(_ sender: UITextField) {
        temp.name = sender.text
        title = temp.name
    }
    @IBAction func widthDidChange(_ sender: UITextField) {
        synchronize(source: Int32(sender.text!), destination: &temp.width) { sender.text = String($0) }
    }
    @IBAction func heightDidChange(_ sender: UITextField) {
        synchronize(source: Int32(sender.text!), destination: &temp.height) { sender.text = String($0) }
    }
    @IBAction func depthDidChange(_ sender: UITextField) {
        synchronize(source: Int32(sender.text!), destination: &temp.depth) { sender.text = String($0) }
    }

    @IBAction func typeDidChange(_ sender: UITextField) { temp.textureType = TextureTypeDelegate.type(at: typePicker.selectedRow(inComponent: 0)) }
    @IBAction func pixelFormatDidChange(_ sender: UITextField) { temp.pixelFormat = PixelFormatDelegate.format(at: pixelFormatPicker.selectedRow(inComponent: 0)) }
    
    @IBAction func shaderReadDidChange(_ sender: UISwitch) {
        if sender.isOn {
            temp.usage.insert(.shaderRead)
        } else {
            temp.usage.remove(.shaderRead)
        }
        tableView.endEditing(true)
    }
    @IBAction func shaderWriteDidChange(_ sender: UISwitch) {
        if sender.isOn {
            temp.usage.insert(.shaderWrite)
        } else {
            temp.usage.remove(.shaderWrite)
        }
        tableView.endEditing(true)
    }
    @IBAction func pixelFormatViewDidChange(_ sender: UISwitch) {
        if sender.isOn {
            temp.usage.insert(.pixelFormatView)
        } else {
            temp.usage.remove(.pixelFormatView)
        }
        tableView.endEditing(true)
    }
    @IBAction func renderTargetDidChange(_ sender: UISwitch) {
        if sender.isOn {
            temp.usage.insert(.renderTarget)
        } else {
            temp.usage.remove(.renderTarget)
        }
        tableView.endEditing(true)
    }
    
    @IBAction func storageModeChanged(_ sender: UITextField) {
        temp.resourceOptions.remove([.storageModeShared, .storageModePrivate, .storageModeMemoryless])
        temp.resourceOptions.insert(StorageModePickerDelegate.resourceOptions(at: storageModePicker.selectedRow(inComponent: 0)))
    }
    
    @IBAction func mipmapDidChange(_ sender: UITextField) {
        synchronize(source: Int16(sender.text!), destination: &temp.mipmapLevelCount) { sender.text = String($0) }
    }
    @IBAction func sampleCountDidChange(_ sender: UITextField) {
        synchronize(source: Int16(sender.text!), destination: &temp.sampleCount) { sender.text = String($0) }
    }
    @IBAction func arrayLengthDidChange(_ sender: UITextField) {
        synchronize(source: Int16(sender.text!), destination: &temp.arrayLength) { sender.text = String($0) }
    }
}

extension TextureDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if tableView.viewWithTag(textField.tag + 1)?.becomeFirstResponder() != true {
            textField.resignFirstResponder()
        }
        return false
    }
}
