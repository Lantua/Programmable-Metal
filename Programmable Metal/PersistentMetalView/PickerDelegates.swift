//
//  PickerDelegates.swift
//  Via
//
//  Created by Lantua on 8/30/2560 BE.
//  Copyright © 2560 Natchanon Luangsomboon. All rights reserved.
//

import Foundation
import PersistentMetal

class StorageModePickerDelegate: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet var outputTextField: UITextField?
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        assert(component == 0)
        outputTextField?.text = self.pickerView(pickerView, titleForRow: row, forComponent: component)
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { return 3 }
    func pickerView(_: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let options = StorageModePickerDelegate.resourceOptions(at: row)
        return StorageModePickerDelegate.text(resourceOptions: options)
    }
    
    static func text(resourceOptions: MTLResourceOptions) -> String {
        if resourceOptions.contains(.storageModeMemoryless) { return "Memoryless" }
        if resourceOptions.contains(.storageModePrivate) { return "Private" }
        return "Shared"
    }
    static func index(of options: MTLResourceOptions) -> Int {
        if options.contains(.storageModeMemoryless) { return 0 }
        if options.contains(.storageModePrivate) { return 1 }
        return 2
    }
    static func resourceOptions(at index: Int) -> MTLResourceOptions {
        switch index {
        case 0: return .storageModeMemoryless
        case 1: return .storageModePrivate
        case 2: return .storageModeShared
        default: fatalError()
        }
    }
}

class TextureTypeDelegate: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet var outputTextField: UITextField?
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        assert(component == 0)
        outputTextField?.text = self.pickerView(pickerView, titleForRow: row, forComponent: component)
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { return 7 }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        assert(component == 0)
        let type = TextureTypeDelegate.type(at: row)
        return TextureTypeDelegate.text(of: type)
    }
    
    static func text(of type: MTLTextureType) -> String {
        switch type {
        case .type1D:           return "1D"
        case .type1DArray:      return "1D Array"
        case .type2D:           return "2D"
        case .type2DArray:      return "2D Array"
        case .type2DMultisample:return "2D Multisample"
        case .type3D:           return "3D"
        case .typeCube:         return "Cube"
        default: fatalError()
        }
    }
    static func index(of type: MTLTextureType) -> Int {
        switch type {
        case .type1D:           return 0
        case .type1DArray:      return 1
        case .type2D:           return 2
        case .type2DArray:      return 3
        case .type2DMultisample:return 4
        case .type3D:           return 5
        case .typeCube:         return 6
        default: fatalError()
        }
    }
    static func type(at index: Int) -> MTLTextureType {
        switch index {
        case 0: return .type1D
        case 1: return .type1DArray
        case 2: return .type2D
        case 3: return .type2DArray
        case 4: return .type2DMultisample
        case 5: return .type3D
        case 6: return .typeCube
        default: fatalError()
        }
    }
}

class PixelFormatDelegate: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
    static var supportedValues: [(MTLPixelFormat, String)] = [
        (.invalid, "invalid"),
        (.rgba8Snorm, "RGBA8 Snorm"),
        (.r16Float, "R16Float")
    ]
    @IBOutlet var outputTextField: UITextField?
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        assert(component == 0)
        outputTextField?.text = self.pickerView(pickerView, titleForRow: row, forComponent: component)
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { return PixelFormatDelegate.supportedValues.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return PixelFormatDelegate.supportedValues[row].1
    }
    
    static func text(of format: MTLPixelFormat) -> String {
        for (current, text) in PixelFormatDelegate.supportedValues {
            if current == format {
                return text
            }
        }
        fatalError("Unsupported Pixel Format \(format)")
    }
    static func index(of format: MTLPixelFormat) -> Int {
        for (i, (current, _)) in PixelFormatDelegate.supportedValues.enumerated() {
            if current == format {
                return i
            }
        }
        fatalError("Unsupported Pixel Format \(format)")
    }
    static func format(at index: Int) -> MTLPixelFormat {
        return supportedValues[index].0
    }
}
