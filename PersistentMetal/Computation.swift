//
//  Computation.swift
//  PersistentMetal
//
//  Created by Lantua on 9/20/2560 BE.
//  Copyright © 2560 Lantua. All rights reserved.
//

import CoreData
import Metal

public extension Computation {
    var threadgroupSize: MTLSize {
        get { return MTLSize(width: Int(tgWidth), height: Int(tgHeight), depth: Int(tgDepth)) }
        set {
            tgWidth = Int16(newValue.width)
            tgHeight = Int16(newValue.height)
            tgDepth = Int16(newValue.depth)
        }
    }
    var gridSize: MTLSize {
        get { return MTLSize(width: Int(gWidth), height: Int(gHeight), depth: Int(gDepth)) }
        set {
            gWidth = Int16(newValue.width)
            gHeight = Int16(newValue.height)
            gDepth = Int16(newValue.depth)
        }
    }
}

struct EncoderState {
    var buffers: [Int16: BufferEntry] = [:]
    var textures: [Int16: TextureEntry] = [:]
    var function: FunctionID?
}

class UnmanagedComputation {
    fileprivate let pipelineState: MTLComputePipelineState?
    fileprivate let threadgroupSize, gridSize: MTLSize, indirectBuffer: UnmanagedBufferEntry?
    fileprivate let bufferGroups: [BufferGroup], textureGroups: [TextureGroup], bufferOffsets: [(Int, Int)]
    fileprivate let buffers: [UnmanagedBufferEntry], textures: [UnmanagedTextureEntry]
    
    init(managed: Computation, state: inout EncoderState, library: UnmanagedLibrary) {
        if state.function != managed.functionID {
            pipelineState = library.unmanaged(managed.functionID!)
            state.function = managed.functionID
        } else { pipelineState = nil }
        threadgroupSize = managed.threadgroupSize
        gridSize = managed.gridSize
        
        do {
            var dirty = Array(managed.textureEntries as! Set<TextureEntry>).filter { state.textures[$0.index]?.texture != $0.texture! }
            let groupableCount = dirty.partition { $0.texture!.isTransient }
            textureGroups = TextureGroup.group(textures: dirty.prefix(upTo: groupableCount), library: library)
            textures = dirty.suffix(from: groupableCount).map { UnmanagedTextureEntry(entry: $0, library: library) }
            
            for entry in dirty { state.textures[entry.index] = entry }
        }
        do {
            if let indirect = (managed.bufferEntries as! Set<BufferEntry>).first(where: { $0.index == -1 }) {
                indirectBuffer = UnmanagedBufferEntry(managed: indirect, library: library)
            } else { indirectBuffer = nil }
            
            var dirty = Array(managed.bufferEntries as! Set<BufferEntry>).filter {
                let old = state.buffers[$0.index]
                return $0.index != -1 && (old?.buffer != $0.buffer! || old?.offset != $0.offset)
            }
            let fullDirtyCount = dirty.partition { state.buffers[$0.index]?.buffer == $0.buffer! }
            var fullDirty = dirty.prefix(upTo: fullDirtyCount)
            bufferOffsets = dirty.suffix(from: fullDirtyCount).map { (Int($0.index), Int($0.offset)) }
            let groupableCount = fullDirty.partition { $0.buffer!.isTransient }
            buffers = fullDirty.suffix(from: groupableCount).map { UnmanagedBufferEntry(managed: $0, library: library) }
            bufferGroups = BufferGroup.group(buffers: fullDirty.prefix(upTo: groupableCount), library: library)
            
            for entry in dirty { state.buffers[entry.index] = entry }
        }
    }
}
extension MTLComputeCommandEncoder {
    func encode(_ computation: UnmanagedComputation) {
        if let pipelineState = computation.pipelineState { setComputePipelineState(pipelineState) }
        
        for group in computation.bufferGroups { setBuffers(group.buffers, offsets: group.offsets, range: group.range) }
        for group in computation.textureGroups { setTextures(group.textures, range: group.range) }
        for entry in computation.buffers { setBuffer(entry.buffer, offset: entry.offset, index: entry.index) }
        for entry in computation.textures { setTexture(entry.texture, index: entry.index) }
        for (index, offset) in computation.bufferOffsets { setBufferOffset(offset, index: index) }
        
        if let entry = computation.indirectBuffer {
            dispatchThreadgroups(indirectBuffer: entry.buffer, indirectBufferOffset: entry.offset, threadsPerThreadgroup: computation.threadgroupSize)
        } else {
            dispatchThreads(computation.gridSize, threadsPerThreadgroup: computation.threadgroupSize)
        }
    }
}
