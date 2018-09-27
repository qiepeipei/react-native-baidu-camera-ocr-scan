//
//  RCTBaiDuOcrModule.h
//  RCTBaiDuOcrModule
//
//  Created by qiepeipei on 2018/9/19.
//  Copyright © 2018年 qiepeipei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <AipOcrSdk/AipOcrSdk.h>
@interface RCTBaiDuOcrModule : RCTEventEmitter <RCTBridgeModule, UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property (nonatomic, strong) RCTPromiseResolveBlock resolve;
@property (nonatomic, strong) RCTPromiseRejectBlock reject;
@end
