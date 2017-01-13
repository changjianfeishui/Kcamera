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


class CaptureModel: NSObject, AVCaptureFileOutputRecordingDelegate, AVCaptureMetadataOutputObjectsDelegate {
    var faceDelegate:FaceDetectionDelegate?
    
    //捕捉会话
    var captureSession:AVCaptureSession!
    //由于捕捉会话的启动是一个同步调用,所以需要异步调用
    let globalQueue = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default)
    
    //AVCaptureOutput子类,用于捕捉输出静态图片
    var imageOutput:AVCaptureStillImageOutput!
    
    //用户捕捉输出视频
    var movieOutput:AVCaptureMovieFileOutput!
    
    //记录当前的捕捉输入对象
    var activeVideoInput:AVCaptureDeviceInput!
    
    //视频的输出地址
    var outputURL:URL!
    
    //元数据输出,用于人脸检测
    var metadataOutput:AVCaptureMetadataOutput!
    
    //MARK: - 设置捕捉会话
    //初始化捕捉会话
    func setupSession() -> Bool {
        //0. 判断权限
        let videoAuthStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        if videoAuthStatus == .denied || videoAuthStatus == .restricted {
            UIAlertView(title: "提示", message: "请在iPhone的“设置-隐私-相机”选项中，允许访问相机 ", delegate: nil, cancelButtonTitle: "确定").show()
            
            return false
        }
        let audioAuthStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        if audioAuthStatus == .denied || audioAuthStatus == .restricted {
            UIAlertView(title: "提示", message: "请在iPhone的“设置-隐私-相机”选项中，允许访问麦克风 ", delegate: nil, cancelButtonTitle: "确定").show()
            return false
        }
        
        //1. 创建捕捉会话
        self.captureSession = AVCaptureSession()
        //2. 设置视频采集质量
        self.captureSession.sessionPreset = AVCaptureSessionPresetHigh
        //3. 设置视频采集设备(默认返回后置摄像头)
        let videoDevice = AVCaptureDevice .defaultDevice(withMediaType: AVMediaTypeVideo)
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
        let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
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
        
        //9. 创建用于人脸检测的元数据输出
        self.metadataOutput = AVCaptureMetadataOutput()
        if self.captureSession.canAddOutput(self.metadataOutput) {
            self.captureSession.addOutput(self.metadataOutput)
            self.metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeFace]
            self.metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        }
        
        
        return true
        
    }
    
    //启动捕捉会话
    func startSession() -> Void {
        if !self.captureSession.isRunning{
            self.globalQueue.sync(execute: { 
                self.captureSession.startRunning()
            })
        }
    }
    
    //停止捕捉会话
    func stopSession() -> Void {
        if self.captureSession.isRunning {
            self.globalQueue.sync(execute: { 
                self.captureSession.stopRunning()
            })
        }
    }
    
    //MARK: - 捕捉图片
    //捕捉静态图片
    func captureStillImage() -> Void {
        //1. 建立输入和输出的连接
        let connection = self.imageOutput.connection(withMediaType: AVMediaTypeVideo)
        //2. 设置照片方向
        if (connection?.isVideoOrientationSupported)! {
            connection?.videoOrientation = self.currentVideoOrientation()
        }
        
        //3. 拍摄照片
        self.imageOutput.captureStillImageAsynchronously(from: connection) { (sampleBuffer, error) in
            if sampleBuffer != nil{
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                let image = UIImage(data: imageData!)
                //4. 写入照片
                self.writeImageToAssetsLibrary(image!)
            }else{
                print(error?.localizedDescription)
            }
        }
    }
    //将捕捉到的图片写入到相册
    func writeImageToAssetsLibrary(_ image:UIImage) -> Void {
        //1. 判断相册访问权限
        let authStatus = ALAssetsLibrary.authorizationStatus()
        if authStatus == .denied || authStatus == .restricted {
            UIAlertView(title: "提示", message: "请打开相册访问权限", delegate: nil, cancelButtonTitle: "确定").show()
            return
        }
        
        //2. 存储图片
        let library = ALAssetsLibrary()
        let orientation = ALAssetOrientation(rawValue: image.imageOrientation.rawValue)
        library.writeImage(toSavedPhotosAlbum: image.cgImage, orientation: orientation!) { (assetURL, error) in
            if error != nil{
                print(error?.localizedDescription)
            }
        }
    }
    
    //获取当前视频方向
    func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation:AVCaptureVideoOrientation!
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = .portrait
        case .landscapeRight:
            orientation = .landscapeRight
        case .portraitUpsideDown:
            orientation = .portraitUpsideDown
        case .landscapeLeft:
            orientation = .landscapeLeft
        default:
            orientation = .portrait
        }
        return orientation
    }
    
    
    //MARK: - 捕捉视频
    //开始捕捉视频
    func startRecording() -> Void {
        //1. 判断是否正在录制
        if !self.movieOutput.isRecording {
            //2. 设置视频输入和输出的连接
            let videoConnection = self.movieOutput.connection(withMediaType: AVMediaTypeVideo)
            //3. 设置视频方向
            if (videoConnection?.isVideoOrientationSupported)! {
                videoConnection?.videoOrientation = self.currentVideoOrientation()
            }
            //4. 设置视频稳定性
            if (videoConnection?.isVideoStabilizationSupported)! {
//                videoConnection?.enablesVideoStabilizationWhenAvailable = true
                //8.0后使用
                videoConnection?.preferredVideoStabilizationMode = .auto
            }
            //5. 平滑对焦模式
            let device = self.activeVideoInput.device
            if  (device?.isSmoothAutoFocusSupported)! {
                if ((try? device?.lockForConfiguration()) != nil) {
                    device?.isSmoothAutoFocusEnabled = true
                    device?.unlockForConfiguration()
                }
            }
            //6. 获取要写入到的本地URL地址
            self.outputURL = self.uniqueURL()
            //7. 写入视频
            self.movieOutput.startRecording(toOutputFileURL: self.outputURL, recordingDelegate: self)
        }
    }
    
    //停止捕捉视频
    func stopRecording() -> Void {
        if self.movieOutput.isRecording {
            self.movieOutput.stopRecording()
        }
    }
    
    //生成本地文件地址
    func uniqueURL() -> URL {
        let dirPath = NSTemporaryDirectory() as NSString
        let date = Date()
        let dateformattre = DateFormatter()
        dateformattre.dateFormat = "yyyyMMddHHMMSS"
        var dateString = dateformattre.string(from: date)
        dateString = dateString + ".mov"
        let filePath = dirPath.appendingPathComponent(dateString)
        return URL(fileURLWithPath: filePath)
    }
    
    //MARK: - AVCaptureFileOutputRecordingDelegate
    //捕获并写入到本地完成
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        if (error == nil) {
            self.writeVideoToAssetsLibrary(self.outputURL)
        }
        self.outputURL = nil
    }
    
    //写入视频到本地文件系统
    func writeVideoToAssetsLibrary(_ videoURL:URL) -> Void {
        //1. 创建资源库
        let library = ALAssetsLibrary()
        //2. 检查视频是否可被写入
        if library.videoAtPathIs(compatibleWithSavedPhotosAlbum: videoURL) {
            library.writeVideoAtPath(toSavedPhotosAlbum: videoURL, completionBlock: { (assetURL, error) in
               
            })
        }
    }
    
    //MARK: - 切换摄像头
    //获取设备的摄像头数量
    func cameraCount() -> Int {
        return AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo).count
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
        if self.activeVideoInput.device.position == .back {
            device = self.cameraWithPosition(.front)!
        }else{
            device = self.cameraWithPosition(.back)!
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

            
        }else{
            return false
        }
        return true
        
    }
    
    //根据position返回可用的摄像头
    func cameraWithPosition(_ position:AVCaptureDevicePosition) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! [AVCaptureDevice]
        for device in devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
    
    //MARK: - 对焦
    //传入是摄像头设备坐标系下的point
    func focusAtPoint(_ point:CGPoint) -> Void {
        //1. 获取当前使用的摄像头
        let device = self.activeVideoInput.device
        //2. 判断当前设备是否支持兴趣点对焦和自动对焦模式
        /*比如前置摄像头就不支持对焦操作,因为设备和目标的距离不会太长*/
        if (device?.isFocusPointOfInterestSupported)! && (device?.isFocusModeSupported(.autoFocus))! {
            //3. 修改配置前需要先锁定设备(设备是多个应用程序通用的)
            if ((try? device?.lockForConfiguration()) != nil) {
                //4. 设置对焦点,修改对焦模式
                device?.focusPointOfInterest = point
                device?.focusMode = .autoFocus
                device?.unlockForConfiguration()
            }
        }else{
            //暂时忽略了对设备不支持情况的处理,比如前置摄像头
        }
    }
    
    //MARK: - 曝光
    func exposeAtPoint(_ point:CGPoint) -> Void {
        let device = self.activeVideoInput.device
        if (device?.isExposurePointOfInterestSupported)! && (device?.isExposureModeSupported(.continuousAutoExposure))! {
            if ((try? device?.lockForConfiguration()) != nil) {
                device?.exposurePointOfInterest = point
                device?.exposureMode = .autoExpose
                device?.unlockForConfiguration()
            }
        }
    }
    
    //MARK: - 重新设置对焦和曝光模式
    func resetFocusAndExposureModes() -> Void {
        let device = self.activeVideoInput.device
        let center = CGPoint(x: 0.5, y: 0.5)
        if ((try? device?.lockForConfiguration()) != nil) {
            if (device?.isFocusPointOfInterestSupported)! && (device?.isFocusModeSupported(.continuousAutoFocus))! {
                device?.focusMode = .continuousAutoFocus
                device?.focusPointOfInterest = center
            }
            if (device?.isExposurePointOfInterestSupported)! && (device?.isExposureModeSupported(.continuousAutoExposure))! {
                device?.exposureMode = .continuousAutoExposure
                device?.exposurePointOfInterest = center
            }
            device?.unlockForConfiguration()
        }
    }
    
    //MARK:- 拍照闪光灯
    func switchFlash(_ mode:AVCaptureFlashMode) -> Void {
        let device = self.activeVideoInput.device
        if (device?.isFlashModeSupported(mode))! {
            if ((try? device?.lockForConfiguration()) != nil) {
                device?.flashMode = mode
                device?.unlockForConfiguration()
            }
        }
    }
    //MARK: - 视频手电筒
    func switchTorch(_ mode:AVCaptureTorchMode) -> Void {
        let device = self.activeVideoInput.device
        if (device?.isTorchModeSupported(mode))! {
            if ((try? device?.lockForConfiguration()) != nil) {
                device?.torchMode = mode
                device?.unlockForConfiguration()
            }
        }
    }
    
    //MARK: - 视频缩放
    func zoomVedio(_ scale:CGFloat) -> Void {
        //1. 判断是否支持缩放
        if !self.cameraSupportsZoom() {
            return
        }
        //2. 判断缩放比例,最大的缩放比例为device.activeFormat.videoMaxZoomFactor,但这里只进行最多4倍缩放
        let device = self.activeVideoInput.device
        let zoomFactor = scale * (device?.videoZoomFactor)!
        if zoomFactor > 4 || zoomFactor < 1 {
            return
        }
        //3. 锁定配置并修改
        if ((try? device?.lockForConfiguration()) != nil) {
            device?.videoZoomFactor = zoomFactor
            //4. 解锁配置
            device?.unlockForConfiguration()
        }
        
    }
    
    //是否可以进行缩放
    func cameraSupportsZoom() -> Bool {
        return self.activeVideoInput.device.activeFormat.videoMaxZoomFactor > 1.0
    }
    
    
    //MARK: - AVCaptureMetadataOutputObjectsDelegate
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        self.faceDelegate?.didDetectFaces(metadataObjects as [AnyObject])

    }
    
}
