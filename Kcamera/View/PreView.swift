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
    func focuxAtPoint(_ point:CGPoint)->Void
    
    //曝光
    func exposeAtPoint(_ point:CGPoint)->Void
    
    //重置连续对焦和曝光模式
    func resetFocusAndExposureModes()->Void
    
    //缩放
    func zoomVedio(_ factor:CGFloat) -> Void
}


let BOX_BOUNDS = CGRect(x: 0, y: 0, width: 150, height: 150)

class PreView: UIView, FaceDetectionDelegate {

    var delegate:PreViewDelegate?
    
    //存储最新的人脸检测faceID
    var latestFaces = Set<Int>()
    
    
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
        view.backgroundColor = UIColor.clear
        view.layer.borderColor = UIColor(colorLiteralRed: 0.102, green: 0.636, blue: 1.000, alpha: 1.000).cgColor
        view.layer.borderWidth = 5.0
        view.isHidden = true
        return view
    }()
    
    //曝光框UI
    lazy var exposureBox:UIView = {
        let view = UIView(frame: BOX_BOUNDS)
        view.backgroundColor = UIColor.clear
        view.layer.borderColor = UIColor(colorLiteralRed: 1.000, green: 0.421, blue: 0.054, alpha: 1.000).cgColor
        view.layer.borderWidth = 5.0
        view.isHidden = true
        return view
    }()
    
    
    override class var layerClass:AnyClass
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
        singleTapRecognizer.require(toFail: doubleTapRecognizer)
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
    func handlePinch(_ pinch:UIPinchGestureRecognizer) -> Void {
        self.delegate?.zoomVedio(pinch.scale)
    }
    
    //对焦功能的触发
    func handleSingleTap(_ tap:UITapGestureRecognizer) -> Void {
        //1. 点击坐标
        let point = tap.location(in: self)
        //2. 动画
        self.runBoxAnimationOnView(self.focusBox, point: point)
        //3. 通知代理
        self.delegate?.focuxAtPoint(self.captureDevicePointForPoint(point))
        
    }
    
    //曝光功能的触发
    func handleDoubleTap(_ tap:UITapGestureRecognizer) -> Void {
        //1. 点击坐标
        let point = tap.location(in: self)
        //2. 动画
        self.runBoxAnimationOnView(self.exposureBox, point: point)
        //3. 通知代理
        self.delegate?.exposeAtPoint(self.captureDevicePointForPoint(point))
    }
    
    func handDoubledoubleTap(_ tap:UITapGestureRecognizer) -> Void {
        //1. 动画
        let center = (self.layer as! AVCaptureVideoPreviewLayer).pointForCaptureDevicePoint(ofInterest: CGPoint(x: 0.5, y: 0.5))
        self.focusBox.center = center
        self.exposureBox.center = center
        self.exposureBox.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        self.focusBox.isHidden = false
        self.exposureBox.isHidden = false
        UIView.animate(withDuration: 0.15, delay: 0, options:UIViewAnimationOptions(), animations: { 
            self.focusBox.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0)
            self.exposureBox.layer.transform = CATransform3DMakeScale(0.7, 0.7, 1.0)
            }) { (_) in
                let time = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time, execute: {
                    self.focusBox.isHidden = true
                    self.exposureBox.isHidden = true
                    self.focusBox.transform = CGAffineTransform.identity
                    self.exposureBox.transform = CGAffineTransform.identity
                })
        }
        //2. 通知代理
        self.delegate?.resetFocusAndExposureModes()
    }
    
    //矩形框缩放动画
    func runBoxAnimationOnView(_ view:UIView,point:CGPoint) -> Void {
        view.center = point
        view.isHidden = false
        UIView.animate(withDuration: 0.15, delay: 0, options: UIViewAnimationOptions(), animations: { 
            view.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1)
            }) { (_) in
                let time = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time, execute: { 
                    view.isHidden = true
                    view.layer.transform = CATransform3DIdentity
                })
        }
    }
    
    //将屏幕坐标系上的触控点转换为摄像头设备坐标系上的点
    func captureDevicePointForPoint(_ point:CGPoint) -> CGPoint{
        let layer = self.layer as! AVCaptureVideoPreviewLayer
        return layer.captureDevicePointOfInterest(for: point)
    }
    
    //MARK: - FaceDetectionDelegate
    func didDetectFaces(_ faces: [AnyObject]) {

        //1. 创建一个数组用于保存转换后的人脸数据
        var transformedFaces = [AVMetadataObject]()

        //2. 遍历传入的人脸数据进行转换
        for face in faces {
            //3. 元数据对象就会被转化成图层的坐标
            let transformedFace = (self.layer as! AVCaptureVideoPreviewLayer).transformedMetadataObject(for: face as! AVMetadataObject)
            transformedFaces.append(transformedFace!)
        }

        //4.遍历新检测到的人脸信息
        var faces = Set<Int>()
        for face in transformedFaces {
            let faceID =  (face as! AVMetadataFaceObject).faceID
            faces.insert(faceID)
            //5. 如果为新检测出的人脸信息
            if !self.latestFaces.contains(faceID) {
                //6. 可视化检测结果
                let view = UIView(frame: face.bounds)
                view.layer.borderColor = UIColor(colorLiteralRed: 1.000, green: 0.421, blue: 0.054, alpha: 1.000).cgColor
                view.layer.borderWidth = 2
                self.addSubview(view)
                UIView.animate(withDuration: 1, animations: {
                    view.alpha = 0
                    }, completion: { (_) in
                        view.removeFromSuperview()
                })
            }
        }
        //7. 更新保存最新的人脸信息
        self.latestFaces = faces
    }

}
