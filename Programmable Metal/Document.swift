//
//  Document.swift
//  Programmable Metal
//
//  Created by Lantua on 28/9/2560 BE.
//  Copyright © 2560 Lantua. All rights reserved.
//

import UIKit
import PersistentMetal
import CoreData

class Document: UIManagedDocument {
    override var managedObjectModel: NSManagedObjectModel { return PersistentMetalHelper.model }
    override func persistentStoreType(forFileType fileType: String) -> String { return NSSQLiteStoreType }
    
    override func handleError(_ error: Error, userInteractionPermitted: Bool) {
        print(error)
    }
    
    lazy var cache = FunctionCache(document: self)
}
extension Document {
    var metalLibrariesURL: URL { return fileURL.appendingPathComponent("Metal Libraries") }
}

class FunctionCache {
    let url: URL
    private(set) var libraries: [String: MTLLibrary]
    
    private var pipelineStates: [NSManagedObjectID: MTLComputePipelineState] = [:]
    private var bufferReqs: [NSManagedObjectID: [BufferRequirement]] = [:]
    private var textureReqs: [NSManagedObjectID: [TextureRequirement]] = [:]
    
    init(document: Document) {
        url = document.metalLibrariesURL
        let urls = try! FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])
        
        libraries = Dictionary(uniqueKeysWithValues: urls.map { ($0.deletingPathExtension().lastPathComponent, try! MTLHelper.device.makeLibrary(URL: $0)) })
    }
    
    func pipelineState(for id: FunctionID) -> MTLComputePipelineState! {
        loadFunction(id: id)
        return pipelineStates[id.objectID]
    }
    func bufferRequirement(for id: FunctionID) -> [BufferRequirement] {
        loadFunction(id: id)
        return bufferReqs[id.objectID]!
    }
    func textureRequirement(for id: FunctionID) -> [TextureRequirement] {
        loadFunction(id: id)
        return textureReqs[id.objectID]!
    }
    
    private func loadFunction(id: FunctionID) {
        guard let library = libraries[id.group!] else { return }
        let functionName = id.name!
        let id = id.objectID
        guard pipelineStates[id] == nil else { return }
        
        let function = library.makeFunction(name: functionName)!
        var reflection: MTLComputePipelineReflection?
        let pipelineState = try! MTLHelper.device.makeComputePipelineState(function: function, options: .argumentInfo, reflection: &reflection)
        
        let arguments = reflection!.arguments
        let bufferReq = [BufferRequirement(indirectCall: ())] + arguments.filter({ $0.type == .buffer }).map(BufferRequirement.init)
        let textureReq = arguments.filter({ $0.type == .texture }).map(TextureRequirement.init)
        
        pipelineStates[id] = pipelineState
        bufferReqs[id] = bufferReq
        textureReqs[id] = textureReq
    }
    
    func reset() {
        let urls = try! FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])
        
        libraries = Dictionary(uniqueKeysWithValues: urls.map { ($0.deletingPathExtension().lastPathComponent, try! MTLHelper.device.makeLibrary(URL: $0)) })
        
        pipelineStates = [:]
        bufferReqs = [:]
        textureReqs = [:]
    }
}
