//
//  PMVProtocols.swift
//  Via
//
//  Created by Lantua on 8/30/2560 BE.
//  Copyright © 2560 Natchanon Luangsomboon. All rights reserved.
//

import Foundation
import CoreData
import PersistentMetal

protocol DocumentSubviewController: class {
    var document: Document! { get }
}
protocol DocumentPivotalSubviewController: DocumentSubviewController {
    var document: Document! { get set }
}
protocol DetailViewController: class, DocumentSubviewController {
    var target: NSFetchRequestResult! { get set }
}

extension DocumentSubviewController {
    var functionCache: FunctionCache { return document.cache }
    var context: NSManagedObjectContext { return document.managedObjectContext }
}

class DocumentNavigationController: UINavigationController, DocumentPivotalSubviewController {
    var document: Document!
}
class DocumentTabBarController: UITabBarController, DocumentPivotalSubviewController {
    var document: Document!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for navigationController in viewControllers! as! [DocumentNavigationController] {
            navigationController.document = document

            let listController = navigationController.topViewController! as! ListViewController
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: listController.entity.name!)
            fetchRequest.resultType = .managedObjectResultType
            fetchRequest.returnsObjectsAsFaults = true
            listController.initFetchRequest(fetchRequest)
        }
    }
}

class FunctionSegue: UIStoryboardSegue { var functionID: FunctionID! }
class TextureSegue: UIStoryboardSegue { var texture: Texture! }
class BufferSegue: UIStoryboardSegue { var buffer: Buffer! }
