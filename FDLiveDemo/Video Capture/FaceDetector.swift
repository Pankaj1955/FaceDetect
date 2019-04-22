//
//  FaceDetector.swift
//  FDLiveDemo
//
//  Created by EXLTYUser on 22/04/19.
//  Copyright © 2019 dreamworks. All rights reserved.
//

import Foundation
import CoreImage
import AVFoundation

class FaceDetector {
    var detector: CIDetector?
    var options: [String : AnyObject]?
    var context: CIContext?
    
    init() {
        context = CIContext()
        
        options = [String : AnyObject]()
        options![CIDetectorAccuracy] = CIDetectorAccuracyLow as AnyObject
        
        detector = CIDetector(ofType: CIDetectorTypeFace, context: context!, options: options!)
    }
    
    func getFacialFeaturesFromImage(image: CIImage, options: [String : AnyObject]) -> [CIFeature] {
        return self.detector!.features(in: image, options: options)
    }
}
