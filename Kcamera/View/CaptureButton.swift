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
    var mode:CameraModel = .Video
    
    override func awakeFromNib() {
        self.circleLayer = CALayer()
        self.circleLayer.backgroundColor = UIColor.redColor().CGColor
        self.backgroundColor = UIColor.clearColor()
        self.tintColor = UIColor.clearColor()
        self.circleLayer.frame = CGRectInset(self.bounds, 8, 8)
        self.circleLayer.cornerRadius = self.circleLayer.frame.width * 0.5
        self.layer.addSublayer(self.circleLayer)    }
        
    
    override var selected: Bool{
        didSet{
            if self.mode == .Video{
                let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
                let radiusAnimation = CABasicAnimation(keyPath: "cornerRadius")
                if selected {
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
                self.circleLayer.addAnimation(animationGroup, forKey: "animationGroup")

            }
            
        }
    }
    

    override var highlighted: Bool{
        didSet{
            let fadeAnimation = CABasicAnimation(keyPath: "opacity")
            fadeAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            fadeAnimation.duration = 0.2
            if highlighted {
                fadeAnimation.toValue = 0
            }else{
                fadeAnimation.toValue = 1
            }
            self.circleLayer.opaque = fadeAnimation.toValue?.intValue == 0 ? false : true
            self.circleLayer.addAnimation(fadeAnimation, forKey: "fadeAnimation")
        }
    }
    
    override func drawRect(rect: CGRect) {
        //1. 获取上下文
        let context = UIGraphicsGetCurrentContext()
        //2. 设置圆环
        CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().CGColor)
        //3. 设置线宽,即圆环宽度
        CGContextSetLineWidth(context, LineWidth)
        //4. 设置圆环大小
        let circleRect = CGRectInset(rect, 3, 3)
        //5. 绘制
        CGContextStrokeEllipseInRect(context, circleRect)
    }

}
