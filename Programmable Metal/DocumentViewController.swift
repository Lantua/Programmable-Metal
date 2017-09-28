//
//  DocumentViewController.swift
//  Programmable Metal
//
//  Created by Lantua on 28/9/2560 BE.
//  Copyright © 2560 Lantua. All rights reserved.
//

import UIKit

class DocumentViewController: UIViewController, UIDocumentPickerDelegate {
    
    @IBOutlet weak var documentNameLabel: UILabel!
    @IBAction func save(_ segue: UIStoryboardSegue) { }
    @IBAction func importMetalLibraries(_ sender: Any) {
        let pickerViewController = UIDocumentPickerViewController(documentTypes: ["com.unnon.metal-library"], in: .import)
        pickerViewController.delegate = self
        pickerViewController.title = "Add Metal Libraries"
        
        present(pickerViewController, animated: true) {
            pickerViewController.allowsMultipleSelection = true
        }
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if controller.title == "Add Metal Libraries" {
            let directory = self.document.metalLibrariesURL
            let semaphore = DispatchSemaphore(value: 1), queue = DispatchQueue(label: "Add Metal Queue")
            enum Action: String {
                case replace = "Replace", ignore = "Ignore"
                func perform(source: URL, destination: URL) {
                    switch self {
                    case .replace: _ = try! FileManager.default.replaceItemAt(destination, withItemAt: source)
                    case .ignore: try! FileManager.default.removeItem(at: source)
                    }
                }
            }
            var defaultAction: Action?
            
            for source in urls {
                let destination = directory.appendingPathComponent(source.lastPathComponent)
                
                guard FileManager.default.fileExists(atPath: destination.path) else {
                    Action.replace.perform(source: source, destination: destination)
                    continue
                }
                
                let shortName = destination.deletingPathExtension().lastPathComponent
                queue.async {
                    semaphore.wait()
                    if let defaultAction = defaultAction {
                        semaphore.signal()
                        defaultAction.perform(source: source, destination: destination)
                        return
                    }
                    
                    var actions: [UIAlertAction] = []
                    for all in [false, true] {
                        for action in [Action.replace, .ignore] {
                            actions.append(UIAlertAction(title: "\(action.rawValue) \(all ? "all" : shortName)", style: .default) { _ in
                                if all { defaultAction = action }
                                semaphore.signal()
                                action.perform(source: source, destination: destination)
                            })
                        }
                    }
                    
                    DispatchQueue.main.sync {
                        alert(message: "\(shortName) already existed.", title: "Files existed", actions: actions, current: self)
                    }
                }
            }
        }
    }
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { }
    
    var document: Document!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Access the document
        document?.open(completionHandler: { (success) in
            if success {
                // Display the content of the document, e.g.:
                self.documentNameLabel.text = self.document?.fileURL.lastPathComponent
            } else {
                // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
            }
        })
    }
    
    @IBAction func dismissDocumentViewController() {
        dismiss(animated: true) {
            self.document?.close(completionHandler: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        (segue.destination as? DocumentPivotalSubviewController)?.document = document
    }
}
