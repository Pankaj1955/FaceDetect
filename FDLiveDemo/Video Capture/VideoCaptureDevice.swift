//
//  VideoCaptureDevice.swift
//  FDLiveDemo
//
//  Created by EXLTYUser on 22/04/19.
//  Copyright © 2019 dreamworks. All rights reserved.
//

import Foundation
import AVFoundation


class VideoCaptureDevice {
    
    static func create() -> AVCaptureDevice {
        var device: AVCaptureDevice?
        AVCaptureDevice.devices(for: AVMediaType.video).forEach { videoDevice in
            if (videoDevice.position == AVCaptureDevice.Position.front) {
                device = videoDevice as? AVCaptureDevice
            }
        }
        if (nil == device) {
            device = AVCaptureDevice.default(for: AVMediaType.video)
        }
        return device!
    }
}
