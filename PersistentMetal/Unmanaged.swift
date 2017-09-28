//
//  Unmanaged.swift
//  PersistentMetal
//
//  Created by Lantua on 9/20/2560 BE.
//  Copyright © 2560 Lantua. All rights reserved.
//

import CoreData
import Metal

public class UnmanagedLibrary {
    public let device: MTLDevice, libraries: [String: MTLLibrary]
    
    fileprivate var buffers: [ID: UnmanagedBuffer] = [:], textures: [ID: UnmanagedTexture] = [:]
    fileprivate var functions: [ID: UnmanagedFunction] = [:]
    
    public init(device: MTLDevice, libraries: [String: MTLLibrary]) {
        self.device = device
        self.libraries = libraries
    }
}

public extension UnmanagedLibrary {
    func computation(for group: String, context: NSManagedObjectContext) throws -> (MTLComputeCommandEncoder) -> () {
        var state = EncoderState()
        let computations = try context.fetchComputations(group: group).map {
            UnmanagedComputation(managed: $0, state: &state, library: self)
        }
        return { computations.forEach($0.encode) }
    }
    func set(buffer: MTLBuffer, to managed: Buffer) {
        precondition(managed.isTransient, "Only transient buffer can be set")
        buffers[managed.objectID] = buffer
    }
    func set(texture: MTLTexture, to managed: Texture) {
        precondition(managed.isTransient, "Only transient texture can be set")
        textures[managed.objectID] = texture
    }
    func pipelineState(for function: FunctionID) -> MTLComputePipelineState { return unmanaged(function) }
}

extension UnmanagedLibrary {
    func unmanaged(_ managed: Buffer) -> UnmanagedBuffer {
        let id = managed.objectID
        if let unmanaged = buffers[id] { return unmanaged }
        let unmanaged = device.makeBuffer(length: Int(managed.length), options: managed.resourceOptions)!
        buffers[id] = unmanaged
        return unmanaged
    }
    func unmanaged(_ managed: Texture) -> UnmanagedTexture {
        let id = managed.objectID
        if let texture = textures[id] { return texture }
        let unmanaged = device.makeTexture(descriptor: managed.descriptor)!
        textures[id] = unmanaged
        return unmanaged
    }
    func unmanaged(_ managed: FunctionID) -> UnmanagedFunction {
        let id = managed.objectID
        if let unmanaged = functions[managed.objectID] { return unmanaged }
        
        let function = libraries[managed.group!]!.makeFunction(name: managed.name!)!
        let unmanaged = try! device.makeComputePipelineState(function: function)
        functions[id] = unmanaged

        return unmanaged
    }
}

extension UnmanagedBufferEntry { var buffer: UnmanagedBuffer { return library.buffers[id]! } }
extension UnmanagedTextureEntry { var texture: MTLTexture { return library.textures[id]! } }
