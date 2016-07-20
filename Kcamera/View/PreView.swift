//
//  PreView.swift
//  Kcamera
//
//  Created by Scarecrow on 16/7/13.
//  Copyright © 2016年 XB. All rights reserved.
//

import UIKit
import AVFoundation

protocol PreViewDelegate {
    //兴趣点对焦
    func focuxAtPoint(point:CGPoint)->Void
}


let BOX_BOUNDS = CGRect(x: 0, y: 0, width: 150, height: 150)

class PreView: UIView {

    var delegate:PreViewDelegate?
    
    var session:AVCaptureSession!{
        get{
            return (self.layer as! AVCaptureVideoPreviewLayer).session
        }
        set{
            (self.layer as! AVCaptureVideoPreviewLayer).session = newValue
        }
    }
    
    //对焦框UI
    lazy var focusBox:UIView = {
        let view = UIView(frame: BOX_BOUNDS)
        view.backgroundColor = UIColor.clearColor()
        view.layer.borderColor = UIColor(colorLiteralRed: 0.102, green: 0.636, blue: 1.000, alpha: 1.000).CGColor
        view.layer.borderWidth = 5.0
        view.hidden = true
        return view
    }()
    
    override class func layerClass()->AnyClass
    {
        return AVCaptureVideoPreviewLayer.self
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    func setupView() -> Void {
        //1. 添加点击事件
        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        self.addGestureRecognizer(singleTapRecognizer)
        //2. 添加对焦框矩形UI
        self.addSubview(self.focusBox)
    }
    
    //对焦功能的实现
    func handleSingleTap(tap:UITapGestureRecognizer) -> Void {
        //1. 点击坐标
        let point = tap.locationInView(self)
        //2. 动画
        self.runBoxAnimationOnView(self.focusBox, point: point)
        //3. 通知代理
        self.delegate?.focuxAtPoint(self.captureDevicePointForPoint(point))
        
    }
    
    //矩形框缩放动画
    func runBoxAnimationOnView(view:UIView,point:CGPoint) -> Void {
        view.center = point
        view.hidden = false
        UIView.animateWithDuration(0.15, delay: 0, options: .CurveEaseInOut, animations: { 
            view.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1)
            }) { (_) in
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
                dispatch_after(time, dispatch_get_main_queue(), { 
                    view.hidden = true
                    view.layer.transform = CATransform3DIdentity
                })
                
                
        }
    }
    
    
    //将屏幕坐标系上的触控点转换为摄像头设备坐标系上的点
    func captureDevicePointForPoint(point:CGPoint) -> CGPoint{
        let layer = self.layer as! AVCaptureVideoPreviewLayer
        return layer.captureDevicePointOfInterestForPoint(point)
    }

}
