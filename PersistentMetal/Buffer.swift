//
//  Buffer.swift
//  PersistentMetal
//
//  Created by Lantua on 9/20/2560 BE.
//  Copyright © 2560 Lantua. All rights reserved.
//

import CoreData
import Metal

public extension Buffer {
    var isTransient: Bool { return length == 0 }
    var resourceOptions: MTLResourceOptions {
        get { return MTLResourceOptions(rawValue: UInt(rawResourceOptions)) }
        set { rawResourceOptions = Int64(newValue.rawValue) }
    }
}

public extension UnmanagedLibrary {
    func load(buffer: Buffer, encoder: MTLBlitCommandEncoder) {
        guard let data = buffer.data else { return }
        let length = Int(buffer.length)
        assert(data.count == length)
        
        let tempBuffer = encoder.device.makeBuffer(length: length, options: .storageModeShared)!
        data.copyBytes(to: tempBuffer.contents().assumingMemoryBound(to: UInt8.self), count: length)
        encoder.copy(from: tempBuffer, sourceOffset: 0, to: unmanaged(buffer), destinationOffset: 0, size: length)
    }
    func save(buffer: Buffer, encoder: MTLBlitCommandEncoder, commandBuffer: MTLCommandBuffer) {
        guard buffer.data != nil else { return }
        let length = Int(buffer.length)
        
        let tempBuffer = encoder.device.makeBuffer(length: length, options: .storageModeShared)!
        encoder.copy(from: unmanaged(buffer), sourceOffset: 0, to: tempBuffer, destinationOffset: 0, size: length)
        commandBuffer.addCompletedHandler {
            _ in buffer.data = Data(bytes: tempBuffer.contents(), count: length)
        }
    }
}

typealias UnmanagedBuffer = MTLBuffer

struct UnmanagedBufferEntry {
    let offset, index: Int, id: ID
    unowned let library: UnmanagedLibrary
    init(managed: BufferEntry, library: UnmanagedLibrary) {
        offset = Int(managed.offset)
        index = Int(managed.index)
        id = managed.buffer!.objectID
        self.library = library
    }
}

struct BufferGroup {
    var buffers: [MTLBuffer?], offsets: [Int], range: Range<Int>
    
    static func group<S: Sequence>(buffers: S, library: UnmanagedLibrary) -> [BufferGroup] where S.Element == BufferEntry {
        let buffers: [BufferEntry?] = buffers.sorted(by: { $0.index < $1.index }) + [nil]
        guard let first = buffers.first! else { return [] }
        var currentGroup: [BufferEntry] = [first]
        var result: [BufferGroup] = []
        
        for entry in buffers.dropFirst() {
            assert(currentGroup.last!.index != entry?.index)
            if entry?.index != currentGroup.last!.index + 1 {
                let buffers = currentGroup.map { library.unmanaged($0.buffer!) }
                let offsets = currentGroup.map { Int($0.offset) }
                let range = Int(currentGroup.first!.index)...Int(currentGroup.last!.index)
                
                result.append(BufferGroup(buffers: buffers, offsets: offsets, range: Range(range)))
            }
            if let entry = entry {
                currentGroup.append(entry)
            }
        }
        
        return result
    }
}
