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
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if self.statusView.point(inside: self.convert(point, to: self.statusView), with: event) || self.modeView.point(inside: self.convert(point, to: self.modeView), with: event){
            return true
        }
        return false
    }
    
    
}
