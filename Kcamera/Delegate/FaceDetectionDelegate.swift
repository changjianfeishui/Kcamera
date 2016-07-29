//
//  FaceDetectionDelegate.swift
//  Kcamera
//
//  Created by XB on 16/7/28.
//  Copyright © 2016年 XB. All rights reserved.
//


protocol FaceDetectionDelegate {
    //检测到的人脸数组
    func didDetectFaces(faces:[AnyObject]) -> Void
}
