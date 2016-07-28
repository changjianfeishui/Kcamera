//
//  ControlView.swift
//  Kcamera
//
//  Created by Scarecrow on 16/7/13.
//  Copyright © 2016年 XB. All rights reserved.
//

import UIKit

class ControlView: UIView {
    
    @IBOutlet weak var statusView: StatusView!
    @IBOutlet weak var modeView: CameraModeView!
    
    //屏蔽除了statusView和modeView区域外的点击事件
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        if self.statusView.pointInside(self.convertPoint(point, toView: self.statusView), withEvent: event) || self.modeView.pointInside(self.convertPoint(point, toView: self.modeView), withEvent: event){
            return true
        }
        return false
    }
    
    
}
