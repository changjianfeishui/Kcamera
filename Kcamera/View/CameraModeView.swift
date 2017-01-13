//
//  CameraModeView.swift
//  CameraModel
//
//  Created by XB on 16/7/7.
//  Copyright © 2016年 XB. All rights reserved.
//

import UIKit

enum CameraModel {
    case photo
    case video
}


class CameraModeView: UIControl {
    
    var labelContainerView:UIView!
    var videoTextLayer:CATextLayer!
    var photoTextLayer:CATextLayer!
    var foregroundColor:UIColor!
    
    var cameraModel:CameraModel? = .video{
        didSet{
            self.sendActions(for: .valueChanged)
        }
    }


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    func setupView() -> Void {
        self.backgroundColor = UIColor(white: 0, alpha: 0.5)
//        self.backgroundColor = UIColor.blueColor()
        
        //1. 文本容器
        self.labelContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 20))
        self.addSubview(self.labelContainerView)
        
        //2. 选中态的颜色
        self.foregroundColor = UIColor(colorLiteralRed: 1, green: 0.734, blue: 0.006, alpha: 1)
        
        //3. 生成文本
        self.videoTextLayer = self.textLayerWithTitle("Vedio")
        self.videoTextLayer.frame = CGRect(x: 0, y: 0, width: 60, height: 20)
        self.videoTextLayer.foregroundColor = self.foregroundColor.cgColor
        self.labelContainerView.layer.addSublayer(self.videoTextLayer)
        
        self.photoTextLayer = self.textLayerWithTitle("Photo")
        self.photoTextLayer.frame = CGRect(x: 60, y: 0, width: 60, height: 20)
        self.labelContainerView.layer.addSublayer(self.photoTextLayer)
        
        //4. 增加滑动手势
        let right = UISwipeGestureRecognizer(target: self, action: #selector(switchModel(_:)))
        let left = UISwipeGestureRecognizer(target: self, action: #selector(switchModel(_:)))
        left.direction = .left
        self.addGestureRecognizer(right)
        self.addGestureRecognizer(left)
    }
    
    func switchModel(_ recognizer:UISwipeGestureRecognizer) -> Void {
        //1. 判断手势滑动方向
        if recognizer.direction == .left {
            UIView.animate(withDuration: 0.28, animations: {
                //2. 动画切换文本位置
                self.labelContainerView.center.x = self.center.x - 30
                }, completion: { (flag) in
                    //3. 更新状态及展示
                    if self.cameraModel != .photo{
                        self.cameraModel = .photo
                        self.photoTextLayer.foregroundColor = self.foregroundColor.cgColor
                        self.videoTextLayer.foregroundColor = UIColor.white.cgColor
                    }
            })
            
        }else{
            UIView.animate(withDuration: 0.28, animations: {
                self.labelContainerView.center.x = self.center.x + 30
                
                }, completion: { (flag) in
                    if self.cameraModel != .video{
                        self.cameraModel = .video
                        self.videoTextLayer.foregroundColor = self.foregroundColor.cgColor
                        self.photoTextLayer.foregroundColor = UIColor.white.cgColor
                    }
            })
        }
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.labelContainerView.center.x = self.center.x + 30
        self.labelContainerView.frame.origin.y = 8
    }
    
    
    func textLayerWithTitle(_ title:String) -> CATextLayer {
        let layer = CATextLayer()
        let font = UIFont(name: "AvenirNextCondensed-DemiBold", size: 17)
        layer.font = font?.fontName as CFTypeRef?
        layer.fontSize = 17
        layer.string = title
        layer.alignmentMode = "center"
        layer.contentsScale = UIScreen.main.scale
        return layer
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(self.foregroundColor.cgColor)
        
        let circleRect = CGRect(x: rect.midX - 3, y: 2, width: 6, height: 6)
        context?.fillEllipse(in: circleRect)
    }

}
