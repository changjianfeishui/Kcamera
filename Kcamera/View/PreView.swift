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
    
    //曝光
    func exposeAtPoint(point:CGPoint)->Void
    
    //重置连续对焦和曝光模式
    func resetFocusAndExposureModes()->Void
    
    //缩放
    func zoomVedio(factor:CGFloat) -> Void
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
    
    //曝光框UI
    lazy var exposureBox:UIView = {
        let view = UIView(frame: BOX_BOUNDS)
        view.backgroundColor = UIColor.clearColor()
        view.layer.borderColor = UIColor(colorLiteralRed: 1.000, green: 0.421, blue: 0.054, alpha: 1.000).CGColor
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
        //1. 添加对焦点击事件
        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        self.addGestureRecognizer(singleTapRecognizer)
        //2. 添加对焦框矩形UI
        self.addSubview(self.focusBox)
        
        //3. 添加曝光点击事件
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        singleTapRecognizer.requireGestureRecognizerToFail(doubleTapRecognizer)
        self.addGestureRecognizer(doubleTapRecognizer)
        
        //4. 添加曝光矩形框UI
        self.addSubview(self.exposureBox)
        
        
        //5. 添加重置回连续对焦和曝光模式的手势
        let doubleDoubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handDoubledoubleTap(_:)))
        doubleDoubleTapRecognizer.numberOfTapsRequired = 2
        doubleDoubleTapRecognizer.numberOfTouchesRequired = 2
        self.addGestureRecognizer(doubleDoubleTapRecognizer)
        
        //6. 添加缩放手势
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        self.addGestureRecognizer(pinchRecognizer)
    }
    
    //视频缩放
    func handlePinch(pinch:UIPinchGestureRecognizer) -> Void {
        self.delegate?.zoomVedio(pinch.scale)
    }
    
    //对焦功能的触发
    func handleSingleTap(tap:UITapGestureRecognizer) -> Void {
        //1. 点击坐标
        let point = tap.locationInView(self)
        //2. 动画
        self.runBoxAnimationOnView(self.focusBox, point: point)
        //3. 通知代理
        self.delegate?.focuxAtPoint(self.captureDevicePointForPoint(point))
        
    }
    
    //曝光功能的触发
    func handleDoubleTap(tap:UITapGestureRecognizer) -> Void {
        //1. 点击坐标
        let point = tap.locationInView(self)
        //2. 动画
        self.runBoxAnimationOnView(self.exposureBox, point: point)
        //3. 通知代理
        self.delegate?.exposeAtPoint(self.captureDevicePointForPoint(point))
    }
    
    func handDoubledoubleTap(tap:UITapGestureRecognizer) -> Void {
        //1. 动画
        let center = (self.layer as! AVCaptureVideoPreviewLayer).pointForCaptureDevicePointOfInterest(CGPoint(x: 0.5, y: 0.5))
        self.focusBox.center = center
        self.exposureBox.center = center
        self.exposureBox.transform = CGAffineTransformMakeScale(1.2, 1.2)
        self.focusBox.hidden = false
        self.exposureBox.hidden = false
        UIView.animateWithDuration(0.15, delay: 0, options:.CurveEaseInOut, animations: { 
            self.focusBox.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0)
            self.exposureBox.layer.transform = CATransform3DMakeScale(0.7, 0.7, 1.0)
            }) { (_) in
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
                dispatch_after(time, dispatch_get_main_queue(), {
                    self.focusBox.hidden = true
                    self.exposureBox.hidden = true
                    self.focusBox.transform = CGAffineTransformIdentity
                    self.exposureBox.transform = CGAffineTransformIdentity
                })
        }
        //2. 通知代理
        self.delegate?.resetFocusAndExposureModes()
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
