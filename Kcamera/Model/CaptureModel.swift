//
//  CameraModel.swift
//  Kcamera
//
//  Created by XB on 16/7/14.
//  Copyright © 2016年 XB. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary



class CaptureModel: NSObject, AVCaptureFileOutputRecordingDelegate {
    
    //捕捉会话
    var captureSession:AVCaptureSession!
    //由于捕捉会话的启动是一个同步调用,所以需要异步调用
    let globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    
    //AVCaptureOutput子类,用于捕捉输出静态图片
    var imageOutput:AVCaptureStillImageOutput!
    
    //用户捕捉输出视频
    var movieOutput:AVCaptureMovieFileOutput!
    
    //记录当前的捕捉输入对象
    var activeVideoInput:AVCaptureDeviceInput!
    
    //视频的输出地址
    var outputURL:NSURL!

    
    //MARK: - 设置捕捉会话
    //初始化捕捉会话
    func setupSession() -> Bool {
        //0. 判断权限
        let videoAuthStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        if videoAuthStatus == .Denied || videoAuthStatus == .Restricted {
            UIAlertView(title: "提示", message: "请在iPhone的“设置-隐私-相机”选项中，允许访问相机 ", delegate: nil, cancelButtonTitle: "确定").show()
            
            return false
        }
        let audioAuthStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        if audioAuthStatus == .Denied || audioAuthStatus == .Restricted {
            UIAlertView(title: "提示", message: "请在iPhone的“设置-隐私-相机”选项中，允许访问麦克风 ", delegate: nil, cancelButtonTitle: "确定").show()
            return false
        }
        
        //1. 创建捕捉会话
        self.captureSession = AVCaptureSession()
        //2. 设置视频采集质量
        self.captureSession.sessionPreset = AVCaptureSessionPresetHigh
        //3. 设置视频采集设备(默认返回后置摄像头)
        let videoDevice = AVCaptureDevice .defaultDeviceWithMediaType(AVMediaTypeVideo)
        //4. 把采集设备封装为一个AVCaptureDeviceInput对象
        let videoInput = try? AVCaptureDeviceInput(device: videoDevice)
        self.activeVideoInput = videoInput

        //5. 在捕捉会话中添加AVCaptureDeviceInput对象
        if  videoInput != nil {
            if self.captureSession.canAddInput(videoInput) {
                self.captureSession.addInput(videoInput)
            }
        }else{
            return false
        }
        
        //6. 参照设置视频采集输入的步骤,将音频采集输入添加到捕捉会话中
        let audioDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        let audioInput = try? AVCaptureDeviceInput(device: audioDevice)
        if audioInput != nil {
            if self.captureSession .canAddInput(audioInput) {
                self.captureSession.addInput(audioInput)
            }
        }else{
            return false
        }
        
        //7. 创建图片输出对象并添加到捕捉会话中
        self.imageOutput = AVCaptureStillImageOutput()
        self.imageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
        if self.captureSession .canAddOutput(self.imageOutput) {
            self.captureSession.addOutput(self.imageOutput)
        }
        
        //8. 创建视频输出对象并添加到捕捉会话中
        self.movieOutput = AVCaptureMovieFileOutput()
        if self.captureSession.canAddOutput(self.movieOutput){
            self.captureSession.addOutput(self.movieOutput)
        }
        
        return true
        
    }
    
    //启动捕捉会话
    func startSession() -> Void {
        if !self.captureSession.running{
            dispatch_sync(self.globalQueue, { 
                self.captureSession.startRunning()
            })
        }
    }
    
    //停止捕捉会话
    func stopSession() -> Void {
        if self.captureSession.running {
            dispatch_sync(self.globalQueue, { 
                self.captureSession.stopRunning()
            })
        }
    }
    
    //MARK: - 捕捉图片
    //捕捉静态图片
    func captureStillImage() -> Void {
        //1. 建立输入和输出的连接
        let connection = self.imageOutput.connectionWithMediaType(AVMediaTypeVideo)
        //2. 设置照片方向
        if connection.supportsVideoOrientation {
            connection.videoOrientation = self.currentVideoOrientation()
        }
        
        //3. 拍摄照片
        self.imageOutput.captureStillImageAsynchronouslyFromConnection(connection) { (sampleBuffer, error) in
            if sampleBuffer != nil{
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                let image = UIImage(data: imageData)
                //4. 写入照片
                self.writeImageToAssetsLibrary(image!)
            }else{
                print(error.localizedDescription)
            }
        }
    }
    //将捕捉到的图片写入到相册
    func writeImageToAssetsLibrary(image:UIImage) -> Void {
        //1. 判断相册访问权限
        let authStatus = ALAssetsLibrary.authorizationStatus()
        if authStatus == .Denied || authStatus == .Restricted {
            UIAlertView(title: "提示", message: "请打开相册访问权限", delegate: nil, cancelButtonTitle: "确定").show()
            return
        }
        
        //2. 存储图片
        let library = ALAssetsLibrary()
        let orientation = ALAssetOrientation(rawValue: image.imageOrientation.rawValue)
        library.writeImageToSavedPhotosAlbum(image.CGImage, orientation: orientation!) { (assetURL, error) in
            if error != nil{
                print(error.localizedDescription)
            }
        }
    }
    
    //获取当前视频方向
    func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation:AVCaptureVideoOrientation!
        switch UIDevice.currentDevice().orientation {
        case .Portrait:
            orientation = .Portrait
        case .LandscapeRight:
            orientation = .LandscapeRight
        case .PortraitUpsideDown:
            orientation = .PortraitUpsideDown
        case .LandscapeLeft:
            orientation = .LandscapeLeft
        default:
            orientation = .Portrait
        }
        return orientation
    }
    
    
    //MARK: - 捕捉视频
    //开始捕捉视频
    func startRecording() -> Void {
        //1. 判断是否正在录制
        if !self.movieOutput.recording {
            //2. 设置视频输入和输出的连接
            let videoConnection = self.movieOutput.connectionWithMediaType(AVMediaTypeVideo)
            //3. 设置视频方向
            if videoConnection.supportsVideoOrientation {
                videoConnection.videoOrientation = self.currentVideoOrientation()
            }
            //4. 设置视频稳定性
            if videoConnection.supportsVideoStabilization {
                videoConnection.enablesVideoStabilizationWhenAvailable = true
            }
            //5. 平滑对焦模式
            let device = self.activeVideoInput.device
            if  device.smoothAutoFocusSupported {
                if ((try? device.lockForConfiguration()) != nil) {
                    device.smoothAutoFocusEnabled = true
                    device.unlockForConfiguration()
                }
            }
            //6. 获取要写入到的本地URL地址
            self.outputURL = self.uniqueURL()
            //7. 写入视频
            self.movieOutput.startRecordingToOutputFileURL(self.outputURL, recordingDelegate: self)
            
        }
    }
    
    //停止捕捉视频
    func stopRecording() -> Void {
        if self.movieOutput.recording {
            self.movieOutput.stopRecording()
        }
    }
    
    //生成本地文件地址
    func uniqueURL() -> NSURL {
        let dirPath = NSTemporaryDirectory() as NSString
        let date = NSDate()
        let dateformattre = NSDateFormatter()
        dateformattre.dateFormat = "yyyyMMddHHMMSS"
        var dateString = dateformattre.stringFromDate(date)
        dateString = dateString.stringByAppendingString(".mov")
        let filePath = dirPath.stringByAppendingPathComponent(dateString)
        return NSURL.fileURLWithPath(filePath)
    }
    
    //MARK: - AVCaptureFileOutputRecordingDelegate
    //捕获并写入到本地完成
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        if (error == nil) {
            self.writeVideoToAssetsLibrary(self.outputURL)
        }
        self.outputURL = nil
    }
    
    //写入视频到本地文件系统
    func writeVideoToAssetsLibrary(videoURL:NSURL) -> Void {
        //1. 创建资源库
        let library = ALAssetsLibrary()
        //2. 检查视频是否可被写入
        if library.videoAtPathIsCompatibleWithSavedPhotosAlbum(videoURL) {
            library.writeVideoAtPathToSavedPhotosAlbum(videoURL, completionBlock: { (assetURL, error) in
               
            })
        }
    }
    
    //MARK: - 切换摄像头
    
    //获取设备的摄像头数量
    func cameraCount() -> Int {
        return AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo).count
    }

    //只有摄像头数量大于1个时,才能进行切换
    func canSwitchCamera() -> Bool {
        return self.cameraCount() > 1
    }
    
    //切换摄像头
    func switchCameras() -> Bool {
        //1. 判断是否能够切换摄像头
        if !self.canSwitchCamera() {
            return false
        }
        //2. 获取闲置的摄像头
        var device:AVCaptureDevice
        if self.activeVideoInput.device.position == .Back {
            device = self.cameraWithPosition(.Front)!
        }else{
            device = self.cameraWithPosition(.Back)!
        }
        
        //3. 把采集设备封装为一个AVCaptureDeviceInput对象
        let videoInput = try? AVCaptureDeviceInput(device: device)
        
        if videoInput != nil {
            //4. 开始重新配置捕捉会话
            self.captureSession.beginConfiguration()
            //5. 移除当前的输入对象
            self.captureSession.removeInput(self.activeVideoInput)
            //6. 添加新的输入对象
            if self.captureSession.canAddInput(videoInput) {
                self.captureSession.addInput(videoInput)
                self.activeVideoInput = videoInput
            }else{
                //7. 如果添加失败,回滚配置
                self.captureSession.addInput(self.activeVideoInput)
            }
            
            //8. 提交配置
            self.captureSession.commitConfiguration()
            
            self.captureSession.
            
            if self.movieOutput.recording {
//                self.movieOutput.startRecordingToOutputFileURL(self.outputURL, recordingDelegate: self)
                self.captureSession.startRunning()

            }

            
        }else{
            return false
        }
        return true
        
    }
    
    //根据position返回可用的摄像头
    func cameraWithPosition(position:AVCaptureDevicePosition) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! [AVCaptureDevice]
        for device in devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
    
    
}
