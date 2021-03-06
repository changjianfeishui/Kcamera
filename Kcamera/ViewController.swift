//
//  ViewController.swift
//  CameraModel
//
//  Created by XB on 16/7/7.
//  Copyright © 2016年 XB. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController,PreViewDelegate {

    var cameraModel:CameraModel! = .video
    var captureModel:CaptureModel!
    
    @IBOutlet weak var preView: PreView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //初始化捕捉会话
        self.captureModel = CaptureModel()
        if self.captureModel.setupSession() {
            self.preView.session = self.captureModel.captureSession
            self.preView.delegate = self
            self.captureModel.faceDelegate = self.preView
            self.captureModel.startSession()
        }
    }

    override var prefersStatusBarHidden : Bool {
        return true
    }


    //拍摄模式切换(Video || Photo)
    @IBAction func cameraModelChanged(_ sender: CameraModeView) {
        print("\(sender.cameraModel)")
        self.cameraModel = sender.cameraModel
    }
    
    //点击拍摄按钮
    @IBAction func captureBtnDidClicked(_ sender: CaptureButton) {
        if self.cameraModel == CameraModel.video{
            sender.isSelected = !sender.isSelected
            //录制视频
            if sender.isSelected {
                self.captureModel.startRecording()
            }else{
                self.captureModel.stopRecording()
            }
        }else{
            //拍摄图片
            self.captureModel.captureStillImage()
        }
    }
    
    //切换摄像头
    @IBAction func switchCamera(_ sender: UIButton) {
        self.captureModel.switchCameras()
    }
    
    //切换闪光灯和手电筒模式
    @IBAction func switchFlash(_ sender: UISegmentedControl) {
        let modeIndex = sender.selectedSegmentIndex
        if self.cameraModel == .video {
            let mode = AVCaptureTorchMode(rawValue: modeIndex)
            self.captureModel.switchTorch(mode!)
        }else{
            let mode = AVCaptureFlashMode(rawValue: modeIndex)
            self.captureModel.switchFlash(mode!)
        }
    }

    

    //MARK: - PreViewDelegate
    func focuxAtPoint(_ point:CGPoint)->Void{
        self.captureModel.focusAtPoint(point)
    }
    
    func exposeAtPoint(_ point: CGPoint) {
        self.captureModel.exposeAtPoint(point)
    }
    
    func resetFocusAndExposureModes() {
        self.captureModel.resetFocusAndExposureModes()
    }
    func zoomVedio(_ factor: CGFloat) {
        self.captureModel.zoomVedio(factor)
    }
}

