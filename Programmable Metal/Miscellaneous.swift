//
//  Miscellaneous.swift
//  Via
//
//  Created by Lantua on 7/24/2560 BE.
//  Copyright © 2560 Natchanon Luangsomboon. All rights reserved.
//

import Foundation
import Metal
import CoreData
import PersistentMetal

class MultiBuffer<T> {
    let length: Int
    
    private var buffers: [T]
    private var currentFrame = 0
    
    init(initialValues: [T]) {
        buffers = initialValues
        length = buffers.count
    }
    
    subscript(index: Int) -> T {
        get { return buffers[(index + currentFrame) % length] }
        set { buffers[(index + currentFrame) % length] = newValue }
    }
    
    func advance() {
        currentFrame = currentFrame + 1
        if currentFrame == length { currentFrame = 0 }
        assert(currentFrame < length && currentFrame > 0)
    }
}

public class MTLHelper {
    public static let device = MTLCreateSystemDefaultDevice()!
    private static let commandQueue = device.makeCommandQueue()!
    
    public static func makeCommandBuffer() -> MTLCommandBuffer! {
        return commandQueue.makeCommandBuffer()
    }
}

func validate(_ validate: () throws -> (), from controller: UIViewController) -> Bool {
    do {
        try validate()
    } catch {
        let error = error as NSError
        if let errors = error.userInfo[NSDetailedErrorsKey] as! [Error]? {
            let message = (errors.map { $0.localizedDescription }).joined(separator: "\n")
            alert(message: message, title: "Validation Fail", current: controller)
        } else {
            alert(message: error.localizedDescription, title: "Validation Fail", current: controller)
        }
        return false
    }
    return true
}

func synchronize<T: Equatable>(source: T?, destination: inout T, validate: ((T) -> T)? = nil, failHandler: (T) -> ()) {
    var succeed = false
    defer { if !succeed { failHandler(destination) } }
    
    guard let source = source else {
        return
    }
    let validatedSource = validate?(source) ?? source
    if validatedSource != destination {
        destination = validatedSource
    }
    if validatedSource != source {
        failHandler(destination)
    }
}

func alert(message: String, title: String = "", actions: [UIAlertAction] = [UIAlertAction(title: "OK", style: .default, handler: nil)], current: UIViewController) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    actions.forEach(alertController.addAction)
    current.present(alertController, animated: true, completion: nil)
}

struct BufferRequirement {
    var index: Int16, name: String
    var length: Int32
    
    init(indirectCall: Void) {
        index = -1
        name = "Indirect Buffer"
        length = 12
    }
    
    init(argument: MTLArgument) {
        assert(argument.type == .buffer)
        index = Int16(argument.index)
        name = argument.name
        length = Int32(argument.bufferDataSize)
    }
}

struct TextureRequirement {
    var index: Int16, name: String
    var type: MTLTextureType
    
    init(argument: MTLArgument) {
        assert(argument.type == .texture)
        index = Int16(argument.index)
        name = argument.name
        type = argument.textureType
    }
}

func ==(lhs: MTLSize, rhs: MTLSize) -> Bool { return lhs.width == rhs.width && lhs.height == rhs.height && lhs.depth == rhs.depth }
func !=(lhs: MTLSize, rhs: MTLSize) -> Bool { return lhs.width != rhs.width || lhs.height != rhs.height || lhs.depth != rhs.depth }
