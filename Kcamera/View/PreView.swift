//
//  PreView.swift
//  Kcamera
//
//  Created by Scarecrow on 16/7/13.
//  Copyright © 2016年 XB. All rights reserved.
//

import UIKit
import AVFoundation

class PreView: UIView {

    var session:AVCaptureSession!{
        get{
            return (self.layer as! AVCaptureVideoPreviewLayer).session
        }
        set{
            (self.layer as! AVCaptureVideoPreviewLayer).session = newValue
        }
    }
    
    override class func layerClass()->AnyClass
    {
        return AVCaptureVideoPreviewLayer.self
    }

}
