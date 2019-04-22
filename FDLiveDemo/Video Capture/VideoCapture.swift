//
//  VideoCapture.swift
//  FDLiveDemo
//
//  Created by EXLTYUser on 22/04/19.
//  Copyright © 2019 dreamworks. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import CoreMotion
import ImageIO

class VideoCapture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    var isCapturing: Bool = false
    var session: AVCaptureSession?
    var device: AVCaptureDevice?
    var input: AVCaptureInput?
    var preview: CALayer?
    var faceDetector: FaceDetector?
    var dataOutput: AVCaptureVideoDataOutput?
    var dataOutputQueue: dispatch_queue_main_t?
    var previewView: UIView?

    enum VideoCaptureError: Error{
        case SessionPresetNotAvailable
        case InputDeviceNotAvailable
        case InputCouldNotBeAddedToSession
        case DataOutputCouldNotBeAddedToSession
    }
    
    override init() {
        super.init()
        
        device = VideoCaptureDevice.create()
        
        faceDetector = FaceDetector()
    }
    
    private func setSessionPreset() throws {
        if (session!.canSetSessionPreset(AVCaptureSession.Preset.vga640x480)) {
            session!.sessionPreset = AVCaptureSession.Preset.vga640x480
        }
        else {
            throw VideoCaptureError.SessionPresetNotAvailable
        }
    }
    
    private func setDeviceInput() throws {
        do {
            self.input = try AVCaptureDeviceInput(device: self.device!)
        }
        catch {
            throw VideoCaptureError.InputDeviceNotAvailable
        }
    }
    
    private func addInputToSession() throws {
        if (session!.canAddInput(self.input!)) {
            session!.addInput(self.input!)
        }
        else {
            throw VideoCaptureError.InputCouldNotBeAddedToSession
        }
    }
    
    private func addPreviewToView(view: UIView) {
        self.preview = AVCaptureVideoPreviewLayer(session: session!)
        self.preview!.frame = view.bounds
        
        view.layer.addSublayer(self.preview!)
    }
    
    private func stopSession() {
        if let runningSession = session {
            runningSession.stopRunning()
        }
    }
    
    private func removePreviewFromView() {
        if let previewLayer = preview {
            previewLayer.removeFromSuperlayer()
        }
    }
    
    private func setDataOutput() {
        self.dataOutput = AVCaptureVideoDataOutput()
        
        var videoSettings = [NSObject : AnyObject]()
        videoSettings[kCVPixelBufferPixelFormatTypeKey] = Int(CInt(kCVPixelFormatType_32BGRA)) as AnyObject
        
        self.dataOutput!.videoSettings = videoSettings as! [String : Any]
        self.dataOutput!.alwaysDiscardsLateVideoFrames = true
        self.dataOutputQueue = dispatch_queue_main_t(label: "VideoDataOutputQueue")
        self.dataOutput!.setSampleBufferDelegate(self, queue: self.dataOutputQueue!)
    }
    
    private func addDataOutputToSession() throws {
        if (self.session!.canAddOutput(self.dataOutput!)) {
            self.session!.addOutput(self.dataOutput!)
        }
        else {
            throw VideoCaptureError.DataOutputCouldNotBeAddedToSession
        }
    }
    
    private func getImageFromBuffer(buffer: CMSampleBuffer) -> CIImage {
        let pixelBuffer = CMSampleBufferGetImageBuffer(buffer)
        
        let attachments = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault, target: buffer, attachmentMode: kCMAttachmentMode_ShouldPropagate)
        
        let image = CIImage(cvPixelBuffer: pixelBuffer!, options: attachments as? [CIImageOption : Any])
        return image
    }
    
    private func getFacialFeaturesFromImage(image: CIImage) -> [CIFeature] {
        let imageOptions = [CIDetectorImageOrientation : 6]
        
        return self.faceDetector!.getFacialFeaturesFromImage(image: image, options: imageOptions as [String : AnyObject])
    }
    
    private func transformFacialFeaturePosition(xPosition: CGFloat, yPosition: CGFloat, videoRect: CGRect, previewRect: CGRect, isMirrored: Bool) -> CGRect {
        
        var featureRect = CGRect(origin: CGPoint(x: xPosition, y: yPosition), size: CGSize(width: 0, height: 0))
        let widthScale = previewRect.size.width / videoRect.size.height
        let heightScale = previewRect.size.height / videoRect.size.width
        
        let transform = isMirrored ? CGAffineTransform(a: 0, b: heightScale, c: -widthScale, d: 0, tx: previewRect.size.width, ty: 0) : CGAffineTransform(a: 0, b: heightScale, c: widthScale, d: 0, tx: 0, ty: 0)
        featureRect = featureRect.applying(transform)
        
        featureRect = featureRect.offsetBy(dx: previewRect.origin.x, dy: previewRect.origin.y)
                
        return featureRect
    }
    
    
    private func getFeatureView() -> UIView {
        let heartView = Bundle.main.loadNibNamed("HeartView", owner: self, options: nil)?[0] as? UIView
        heartView!.backgroundColor = UIColor.clear
        heartView!.layer.removeAllAnimations()
        heartView!.tag = 1001
        
        return heartView!
    }
    
    private func removeFeatureViews() {
        if let pv = previewView {
            for view in pv.subviews {
                if (view.tag == 1001) {
                    view.removeFromSuperview()
                }
            }
        }
    }
    
    private func addEyeViewToPreview(xPosition: CGFloat, yPosition: CGFloat, cleanAperture: CGRect) {
        let eyeView = getFeatureView()
        let isMirrored = preview!.contentsAreFlipped()
        let previewBox = preview!.frame
        
        previewView!.addSubview(eyeView)
        
        var eyeFrame = transformFacialFeaturePosition(xPosition: xPosition, yPosition: yPosition, videoRect: cleanAperture, previewRect: previewBox, isMirrored: isMirrored)
        
        eyeFrame.origin.x -= 37
        eyeFrame.origin.y -= 37
        
        eyeView.frame = eyeFrame
    }
    
    private func alterPreview(features: [CIFeature], cleanAperture: CGRect) {
        removeFeatureViews()
        
        if (features.count == 0 || cleanAperture == CGRect.zero || !isCapturing) {
            return
        }
        
        for feature in features {
            let faceFeature = feature as? CIFaceFeature
            
            if (faceFeature!.hasLeftEyePosition) {
                
                addEyeViewToPreview(xPosition: faceFeature!.leftEyePosition.x, yPosition: faceFeature!.leftEyePosition.y, cleanAperture: cleanAperture)
            }
            
            if (faceFeature!.hasRightEyePosition) {
                
                addEyeViewToPreview(xPosition: faceFeature!.rightEyePosition.x, yPosition: faceFeature!.rightEyePosition.y, cleanAperture: cleanAperture)
            }
            
        }
        
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        let image = getImageFromBuffer(buffer: sampleBuffer)
        
        let features = getFacialFeaturesFromImage(image: image)
        
        let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
        
        let cleanAperture = CMVideoFormatDescriptionGetCleanAperture(formatDescription!, originIsAtTopLeft: false)
        
        DispatchQueue.main.async {
            self.alterPreview(features: features, cleanAperture: cleanAperture)

        }
    }
    
    func startCapturing(previewView: UIView) throws {
        isCapturing = true
        
        self.previewView = previewView
        
        self.session = AVCaptureSession()
        
        try setSessionPreset()
        
        try setDeviceInput()
        
        try addInputToSession()
        
        setDataOutput()
        
        try addDataOutputToSession()
        
        addPreviewToView(view: self.previewView!)
        
        session!.startRunning()
    }
    
    func stopCapturing() {
        isCapturing = false
        
        stopSession()
        
        removePreviewFromView()
        
        removeFeatureViews()
        
        preview = nil
        dataOutput = nil
        dataOutputQueue = nil
        session = nil
        previewView = nil
    }
}
