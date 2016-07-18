//
//  ViewController.swift
//  CameraModel
//
//  Created by XB on 16/7/7.
//  Copyright © 2016年 XB. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var cameraModel:CameraModel! = .Video
    var captureModel:CaptureModel!
    
    @IBOutlet weak var preView: PreView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //初始化捕捉会话
        self.captureModel = CaptureModel()
        if self.captureModel.setupSession() {
            self.preView.session = self.captureModel.captureSession
            self.captureModel.startSession()
        }
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }


    //拍摄模式切换(Video || Photo)
    @IBAction func cameraModelChanged(sender: CameraModeView) {
        print("\(sender.cameraModel)")
        self.cameraModel = sender.cameraModel
    }
    
    //点击拍摄按钮
    @IBAction func captureBtnDidClicked(sender: CaptureButton) {
        if self.cameraModel == CameraModel.Video{
            sender.selected = !sender.selected
            //录制视频
            if sender.selected {
                self.captureModel.startRecording()
            }else{
                self.captureModel.stopRecording()
            }
        }else{
            //拍摄图片
            self.captureModel.captureStillImage()
        }
    }
    
}

