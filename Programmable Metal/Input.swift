//
//  Input.swift
//  Via
//
//  Created by Natchanon Luangsomboon on 8/30/2559 BE.
//  Copyright © 2559 Natchanon Luangsomboon. All rights reserved.
//

import CoreFoundation
import Foundation
import Metal
import AVFoundation
import PersistentMetal

protocol InputDelegate {
    func capture(videoFrame: MTLTexture, from: Input)
    func skipVideoFrame(from: Input)
    
    func capture(audioFrame: MTLBuffer, from: Input)
}

class Input: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    var delegate: InputDelegate!
    
    private let session = AVCaptureSession()
    private let videoCache: CVMetalTextureCache
    private let audioCache: MTLBuffer
    
    init!(camera: AVCaptureDevice, microphone: AVCaptureDevice) throws {
        var videoCache: CVMetalTextureCache?
        let result = CVMetalTextureCacheCreate(nil, nil, MTLHelper.device, nil, &videoCache)
        assert(result == kCVReturnSuccess)
        self.videoCache = videoCache!
        audioCache = MTLHelper.device.makeBuffer(length: 2048, options: .storageModeShared)!

        super.init()
        
        let camera = try AVCaptureDeviceInput(device: camera)
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]

        let microphone = try AVCaptureDeviceInput(device: microphone)
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        
        guard session.canAddInput(camera),
            session.canAddInput(microphone),
            session.canAddOutput(videoOutput),
            session.canAddOutput(audioOutput) else { return nil }
        
        session.beginConfiguration()
        session.addInput(camera)
        session.addInput(microphone)
        session.addOutput(videoOutput)
        session.addOutput(audioOutput)
        session.sessionPreset = .hd1280x720
        session.commitConfiguration()
    }
    
    private func capture(audioBuffer: CMSampleBuffer) {
        let numSamples = CMSampleBufferGetNumSamples(audioBuffer)
        let size = MemoryLayout<Int16>.stride * numSamples
        guard size == audioCache.length else {
            return
        }

        let genericDescription = CMSampleBufferGetFormatDescription(audioBuffer)!
        assert(CMFormatDescriptionGetMediaType(genericDescription) == kCMMediaType_Audio)
        let description = CMAudioFormatDescriptionGetStreamBasicDescription(genericDescription)!.pointee
        
        // We're handling a very simple 44100Hz one-channel lpcm. Asserting as such
        assert(description.mSampleRate == 44100)
        assert(description.mFormatID == kAudioFormatLinearPCM)
        assert(description.mBytesPerPacket == 2)
        assert(description.mFramesPerPacket == 1)
        assert(description.mBytesPerFrame == 2)
        assert(description.mChannelsPerFrame == 1)
        assert(description.mBitsPerChannel == 16)
        // We're handling 16-bit native packed signed-integer
        assert(description.mFormatFlags & kLinearPCMFormatFlagIsBigEndian == kAudioFormatFlagsNativeEndian)
        assert(description.mFormatFlags & kLinearPCMFormatFlagIsSignedInteger != 0)
        assert(description.mFormatFlags & kLinearPCMFormatFlagIsPacked != 0)
        
        let dataBuffer = CMSampleBufferGetDataBuffer(audioBuffer)!
        CMBlockBufferCopyDataBytes(dataBuffer, 0, size, audioCache.contents())
        
        delegate.capture(audioFrame: audioCache, from: self)
    }
    private func capture(videoBuffer: CMSampleBuffer) {
        var success = false
        defer { if !success { delegate.skipVideoFrame(from: self) } }
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(videoBuffer) else { return }
        let width = CVPixelBufferGetWidth(imageBuffer), height = CVPixelBufferGetHeight(imageBuffer)
        var texture: CVMetalTexture?
        let result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, videoCache, imageBuffer, nil, .bgra8Unorm, width, height, 0, &texture)
        
        guard result == kCVReturnSuccess, texture != nil, let cameraData = CVMetalTextureGetTexture(texture!) else {
            return
        }
        
        delegate.capture(videoFrame: cameraData, from: self)
        success = true
    }
    
    @objc func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        autoreleasepool {
            switch captureOutput {
            case is AVCaptureVideoDataOutput: capture(videoBuffer: sampleBuffer)
            case is AVCaptureAudioDataOutput: capture(audioBuffer: sampleBuffer)
            default: fatalError("Unrecognized AVCaptureOutput")
            }
        }
    }
    
    @objc func captureOutput(_ captureOutput: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        autoreleasepool {
            delegate.skipVideoFrame(from: self)
        }
    }
    
    var isRunning: Bool { return session.isRunning }
    func start() { session.startRunning() }
    func stop() { session.stopRunning() }
}
