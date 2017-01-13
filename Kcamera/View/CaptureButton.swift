//
//  CaptureButton.swift
//  Kcamera
//
//  Created by XB on 16/7/8.
//  Copyright © 2016年 XB. All rights reserved.
//

import UIKit

let LineWidth:CGFloat = 6.0

class CaptureButton: UIButton {

    var circleLayer:CALayer!
    var mode:CameraModel = .video
    
    override func awakeFromNib() {
        self.circleLayer = CALayer()
        self.circleLayer.backgroundColor = UIColor.red.cgColor
        self.backgroundColor = UIColor.clear
        self.tintColor = UIColor.clear
        self.circleLayer.frame = self.bounds.insetBy(dx: 8, dy: 8)
        self.circleLayer.cornerRadius = self.circleLayer.frame.width * 0.5
        self.layer.addSublayer(self.circleLayer)    }
        
    
    override var isSelected: Bool{
        didSet{
            if self.mode == .video{
                let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
                let radiusAnimation = CABasicAnimation(keyPath: "cornerRadius")
                if isSelected {
                    scaleAnimation.toValue = 0.6
                    radiusAnimation.toValue = self.circleLayer.bounds.width/4.0
                }else{
                    scaleAnimation.toValue = 1.0
                    radiusAnimation.toValue = self.circleLayer.bounds.width/2.0
                }
                let animationGroup = CAAnimationGroup()
                animationGroup.animations = [scaleAnimation,radiusAnimation];
                animationGroup.beginTime = CACurrentMediaTime() + 0.2
                animationGroup.duration = 0.35
                
                self.circleLayer.setValue(scaleAnimation.toValue, forKeyPath: "transform.scale")
                self.circleLayer.setValue(radiusAnimation.toValue, forKeyPath: "cornerRadius")
                self.circleLayer.add(animationGroup, forKey: "animationGroup")

            }
            
        }
    }
    

    override var isHighlighted: Bool{
        didSet{
            let fadeAnimation = CABasicAnimation(keyPath: "opacity")
            fadeAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            fadeAnimation.duration = 0.2
            if isHighlighted {
                fadeAnimation.toValue = 0
            }else{
                fadeAnimation.toValue = 1
            }
            self.circleLayer.isOpaque = (fadeAnimation.toValue as AnyObject).int32Value == 0 ? false : true
            self.circleLayer.add(fadeAnimation, forKey: "fadeAnimation")
        }
    }
    
    override func draw(_ rect: CGRect) {
        //1. 获取上下文
        let context = UIGraphicsGetCurrentContext()
        //2. 设置圆环
        context?.setStrokeColor(UIColor.white.cgColor)
        //3. 设置线宽,即圆环宽度
        context?.setLineWidth(LineWidth)
        //4. 设置圆环大小
        let circleRect = rect.insetBy(dx: 3, dy: 3)
        //5. 绘制
        context?.strokeEllipse(in: circleRect)
    }

}
