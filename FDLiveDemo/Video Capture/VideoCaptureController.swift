//
//  VideoCaptureController.swift
//  FDLiveDemo
//
//  Created by EXLTYUser on 22/04/19.
//  Copyright © 2019 dreamworks. All rights reserved.
//

import UIKit

import Foundation
import UIKit

class VideoCaptureController: UIViewController {
    var videoCapture: VideoCapture?
    
    override func viewDidLoad() {
        videoCapture = VideoCapture()
    }
    
    override func didReceiveMemoryWarning() {
        stopCapturing()
    }
    
    func startCapturing() {
        do {
            try videoCapture!.startCapturing(previewView: self.view)
        }
        catch {
            // Error
        }
    }
    
    func stopCapturing() {
        videoCapture!.stopCapturing()
    }
    
    @IBAction func touchDown(sender: AnyObject) {
        let button = sender as! UIButton
        button.setTitle("Stop", for: UIControl.State.normal)
        
        startCapturing()
    }
    
    @IBAction func touchUp(sender: AnyObject) {
        let button = sender as! UIButton
        button.setTitle("Start", for: UIControl.State.normal)
        
        stopCapturing()
    }
    
}
