//
//  Texture.swift
//  PersistentMetal
//
//  Created by Lantua on 9/20/2560 BE.
//  Copyright © 2560 Lantua. All rights reserved.
//

import CoreData
import Metal

public extension Texture {
    var isTransient: Bool { return pixelFormat == .invalid }
    var pixelFormat: MTLPixelFormat {
        get { return MTLPixelFormat(rawValue: UInt(rawPixelFormat))! }
        set { rawPixelFormat = Int64(newValue.rawValue) }
    }
    var resourceOptions: MTLResourceOptions {
        get { return MTLResourceOptions(rawValue: UInt(rawResourceOptions)) }
        set { rawResourceOptions = Int64(newValue.rawValue) }
    }
    var textureType: MTLTextureType {
        get { return MTLTextureType(rawValue: UInt(rawType))! }
        set { rawType = Int64(newValue.rawValue) }
    }
    var usage: MTLTextureUsage {
        get { return MTLTextureUsage(rawValue: UInt(rawUsage)) }
        set { rawUsage = Int64(newValue.rawValue) }
    }
    var size: MTLSize {
        get { return MTLSize(width: Int(width), height: Int(height), depth: Int(depth)) }
        set {
            width = Int32(newValue.width)
            height = Int32(newValue.height)
            depth = Int32(newValue.depth)
        }
    }
    var descriptor: MTLTextureDescriptor {
        get {
            let value = MTLTextureDescriptor()
            value.width = Int(width)
            value.height = Int(height)
            value.depth = Int(depth)
            
            value.arrayLength = Int(arrayLength)
            value.mipmapLevelCount = Int(mipmapLevelCount)
            value.sampleCount = Int(sampleCount)
            
            value.pixelFormat = pixelFormat
            value.resourceOptions = resourceOptions
            value.textureType = textureType
            value.usage = usage
            
            return value
        }
        set {
            width = Int32(newValue.width)
            height = Int32(newValue.height)
            depth = Int32(newValue.depth)
            
            arrayLength = Int16(newValue.arrayLength)
            mipmapLevelCount = Int16(newValue.mipmapLevelCount)
            sampleCount = Int16(newValue.sampleCount)
            
            pixelFormat = newValue.pixelFormat
            resourceOptions = newValue.resourceOptions
            textureType = newValue.textureType
            usage = newValue.usage
        }
    }
}

typealias UnmanagedTexture = MTLTexture

struct UnmanagedTextureEntry {
    let index: Int, id: ID
    unowned let library: UnmanagedLibrary
    init(entry: TextureEntry, library: UnmanagedLibrary) {
        id = entry.texture!.objectID
        index = Int(entry.index)
        self.library = library
    }
}

struct TextureGroup {
    var textures: [MTLTexture?], range: Range<Int>
    
    static func group<S: Sequence>(textures: S, library: UnmanagedLibrary) -> [TextureGroup] where S.Element == TextureEntry {
        let textures: [TextureEntry?] = textures.sorted(by: { $0.index < $1.index }) + [nil]
        guard let first = textures.first! else { return [] }
        var currentGroup: [TextureEntry] = [first]
        var result: [TextureGroup] = []
        
        for entry in textures.dropFirst() {
            assert(currentGroup.last!.index != entry?.index)
            if entry?.index != currentGroup.last!.index.advanced(by: 1) {
                let textures = currentGroup.map { library.unmanaged($0.texture!) }
                let range = Int(currentGroup.first!.index)...Int(currentGroup.last!.index)
                
                result.append(TextureGroup(textures: textures, range: Range(range)))
                currentGroup = []
            }
            if let entry = entry {
                currentGroup.append(entry)
            }
        }
        
        return result
    }}
