//
//  RCTBaiDuOcrModule.m
//  RCTBaiDuOcrModule
//
//  Created by qiepeipei on 2018/9/19.
//  Copyright © 2018年 qiepeipei. All rights reserved.
//

#import "RCTBaiDuOcrModule.h"
#import "ZZYQRCode/UIImage+ZZYQRImageExtension.h"
#import "MMViewController.h"

@implementation RCTBaiDuOcrModule

@synthesize bridge = _bridge;
RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"BaiDuOcrEmitter"];
}

-(instancetype) init{
    self = [super init];
    
    //添加监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getMessageContent:) name:@"Scan_Send_Message" object:nil];
    
    return self;
}


//接收二维码监听回调
- (void)getMessageContent:(NSNotification *)notifi{
    NSString *notfiStr = (NSString *)notifi.object;
    NSDictionary *dict = @{
                           @"type":@"QRCODE",
                           @"data":notfiStr,
                           };
    [self sendEventWithName:@"BaiDuOcrEmitter" body:dict];
}

    
- (void) setConfiguration:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject {
    self.resolve = resolve;
    self.reject = reject;
}

- (UIViewController*) getRootVC {
    UIViewController *root = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    while (root.presentedViewController != nil) {
        root = root.presentedViewController;
    }
    return root;
}


//初始化
RCT_EXPORT_METHOD(initOcr:(NSString*)ak  sk:(NSString*)sk  callback:(RCTResponseSenderBlock)callback)
{
    NSLog(@"ak=%@ sk=%@", ak, sk);
    [[AipOcrService shardService] authWithAK:ak andSK:sk];
    callback(@[[NSNumber numberWithInt:0]]);
}

+(NSString *)getNowTimeTimestamp{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"]; // ----------设置你想要的格式,hh与HH的区别:分别表示12小时制,24小时制
    //设置时区,这个对于时间的处理有时很重要
    NSTimeZone* timeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
    [formatter setTimeZone:timeZone];
    NSDate *datenow = [NSDate date];//现在时间,你可以输出来看下是什么格式
    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[datenow timeIntervalSince1970]];
    return timeSp;
}

//调用相机
RCT_EXPORT_METHOD(callCamera)
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
   picker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self getRootVC] presentViewController:picker animated:YES completion:nil];
    });
}


//调用相册
RCT_EXPORT_METHOD(callAlbum)
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self getRootVC] presentViewController:picker animated:YES completion:nil];
    });
}

//点击相册中的图片 货照相机照完后点击use  后触发的方法
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *chosenImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    //JEPG格式
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString*  img_name = [[NSString alloc] initWithFormat:@"img_%@.jpg", [RCTBaiDuOcrModule getNowTimeTimestamp]];
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:img_name];
    [UIImageJPEGRepresentation(chosenImage, 0.6) writeToFile:filePath atomically:YES];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:10];
        [dictionary setObject:@"DEFAULT" forKey:@"type"];
        [dictionary setObject:filePath forKey:@"url"];
        [dictionary setObject:filePath forKey:@"filePath"];
        [self sendEventWithName:@"BaiDuOcrEmitter" body:dictionary];
         [[self getRootVC].presentingViewController dismissViewControllerAnimated:YES completion:nil ];
    });
}

//点击cancel 调用的方法
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSLog(@"点击取消回调执行");
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self getRootVC].presentingViewController dismissViewControllerAnimated:YES completion:nil ];
    });
}

//二维码扫描
RCT_EXPORT_METHOD(callQRCode)
{
    NSLog(@"二维码扫描执行");
    dispatch_async(dispatch_get_main_queue(), ^{
        MMViewController* vc = [[MMViewController alloc] init];
        [[self getRootVC] presentViewController: vc animated:YES completion:nil];
    });
   
}

//二维码生成
RCT_EXPORT_METHOD(createQRCode:(NSString*)jsonStr)
{
    NSLog(@"二维码创建执行");
    UIImage* img = [UIImage createQRCodeWithSize:150 dataString:@"hello"];
    //JEPG格式
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString*  img_name = [[NSString alloc] initWithFormat:@"img_%@.jpg", [RCTBaiDuOcrModule getNowTimeTimestamp]];
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:img_name];
    [UIImageJPEGRepresentation(img, 1.0) writeToFile:filePath atomically:YES];
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:10];
    [dictionary setObject:@"DEFAULT" forKey:@"type"];
    [dictionary setObject:filePath forKey:@"url"];
    [dictionary setObject:filePath forKey:@"filePath"];
    [self sendEventWithName:@"BaiDuOcrEmitter" body:dictionary];
}

//通用识别
RCT_EXPORT_METHOD(callOcr:(NSString*)type)
{
    if([type isEqualToString:@"BUSINESS_LICENSE"]){  //营业执照
        [self businessLicenseIdentification];
    }else if([type isEqualToString:@"CAMERA"]){ //银行卡
         [self BankCardIdentification];
    }else if([type isEqualToString:@"CARD_FRONT"]){ //身份证 正面
        [self identityIdentificationPositive];
    }else if([type isEqualToString:@"CARD_BACK"]){ //身份证 反面
        [self identityIdentificationNegative];
    }else if([type isEqualToString:@"PLATE_LICENSE"]){ //车牌识别
        [self plateLicenseIdentification];
    }else if([type isEqualToString:@"DRIVER_LICENSE"]){ //驾驶证识别
        [self driverLicenseIdentification];
    }else if([type isEqualToString:@"DRIVING_LICENSE"]){ //行驶证识别
        [self drivingLicenseIdentification];
    }else if([type isEqualToString:@"GENERAL_BILL"]){ //通用票据识别
        [self generalBillLicenseIdentification];
    }else if([type isEqualToString:@"GENERAL_TEXT"]){ //通用文字识别
        [self generalBillLicenseIdentification];
    }
    
}

//通用文字识别
-(void) generalTextLicenseIdentification{
    UIViewController * vc =
    [AipGeneralVC ViewControllerWithHandler:^(UIImage *image) {
        UIImage *smallImage = [UIImage imageWithCGImage:[image CGImage]];
        //JEPG格式
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString*  img_name = [[NSString alloc] initWithFormat:@"img_%@.jpg", [RCTBaiDuOcrModule getNowTimeTimestamp]];
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:img_name];
        [UIImageJPEGRepresentation(smallImage, 0.6) writeToFile:filePath atomically:YES];
        [[AipOcrService shardService] detectTextBasicFromImage:image
                                                 withOptions:nil
                                              successHandler:^(id result){
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:14];
                                                      [dictionary setObject:@0 forKey:@"error"];
                                                      [dictionary setObject:@"GENERAL_TEXT" forKey:@"type"];
                                                      [dictionary setObject:filePath forKey:@"url"];
                                                      [dictionary setObject:filePath forKey:@"filePath"];
                                                      [dictionary setObject:result forKey:@"data"];
                                                      
                                                      [self sendEventWithName:@"BaiDuOcrEmitter" body:dictionary];
                                                      [[self getRootVC].presentingViewController dismissViewControllerAnimated:YES completion:nil ];
                                                  });
                                              }
                                                 failHandler:^(NSError *error){
                                                     NSLog(@"识别失败回调= %@", error);
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         NSDictionary *dict = @{
                                                                                @"error":@-1,
                                                                                @"type":@"GENERAL_TEXT",
                                                                                @"url":filePath,
                                                                                @"filePath":filePath,
                                                                                @"msg":error.localizedDescription
                                                                                };
                                                         [self sendEventWithName:@"BaiDuOcrEmitter" body:dict];
                                                         [[self getRootVC].presentingViewController dismissViewControllerAnimated:YES completion:nil ];
                                                     });
                                                 }];
    }];
    [[self getRootVC] presentViewController: vc animated:YES completion:nil];
}

//通用票据识别
-(void) generalBillLicenseIdentification{
    UIViewController * vc =
    [AipGeneralVC ViewControllerWithHandler:^(UIImage *image) {
        UIImage *smallImage = [UIImage imageWithCGImage:[image CGImage]];
        //JEPG格式
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString*  img_name = [[NSString alloc] initWithFormat:@"img_%@.jpg", [RCTBaiDuOcrModule getNowTimeTimestamp]];
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:img_name];
        [UIImageJPEGRepresentation(smallImage, 0.6) writeToFile:filePath atomically:YES];
        [[AipOcrService shardService] detectReceiptFromImage:image
                                                        withOptions:nil
                                                     successHandler:^(id result){
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                             NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:14];
                                                             [dictionary setObject:@0 forKey:@"error"];
                                                             [dictionary setObject:@"GENERAL_BILL" forKey:@"type"];
                                                             [dictionary setObject:filePath forKey:@"url"];
                                                             [dictionary setObject:filePath forKey:@"filePath"];
                                                             [dictionary setObject:result forKey:@"data"];
                                                             
                                                             [self sendEventWithName:@"BaiDuOcrEmitter" body:dictionary];
                                                             [[self getRootVC].presentingViewController dismissViewControllerAnimated:YES completion:nil ];
                                                         });
                                                     }
                                                        failHandler:^(NSError *error){
                                                            NSLog(@"识别失败回调= %@", error);
                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                NSDictionary *dict = @{
                                                                                       @"error":@-1,
                                                                                       @"type":@"GENERAL_BILL",
                                                                                       @"url":filePath,
                                                                                       @"filePath":filePath,
                                                                                       @"msg":error.localizedDescription
                                                                                       };
                                                                [self sendEventWithName:@"BaiDuOcrEmitter" body:dict];
                                                                [[self getRootVC].presentingViewController dismissViewControllerAnimated:YES completion:nil ];
                                                            });
                                                        }];
    }];
    [[self getRootVC] presentViewController: vc animated:YES completion:nil];
}

//行驶证识别
-(void) drivingLicenseIdentification{
    UIViewController * vc =
    [AipGeneralVC ViewControllerWithHandler:^(UIImage *image) {
        UIImage *smallImage = [UIImage imageWithCGImage:[image CGImage]];
        //JEPG格式
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString*  img_name = [[NSString alloc] initWithFormat:@"img_%@.jpg", [RCTBaiDuOcrModule getNowTimeTimestamp]];
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:img_name];
        [UIImageJPEGRepresentation(smallImage, 0.6) writeToFile:filePath atomically:YES];
        [[AipOcrService shardService] detectVehicleLicenseFromImage:image
                                                        withOptions:nil
                                                     successHandler:^(id result){
                                                         NSDictionary* dict = [result objectForKey:(@"words_result")];
                                                         NSLog(@"识别成功回调= %@", dict);
//                                                         NSArray* keys = [dict allKeys];
//                                                         for(int i=0;i<keys.count;i++){
//                                                             NSString* key = keys[i];
//                                                             NSLog(@"%@=%@",key,[dict objectForKey:key]);
//                                                         }
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                             NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:14];
                                                             [dictionary setObject:@0 forKey:@"error"];
                                                             [dictionary setObject:@"DRIVING_LICENSE" forKey:@"type"];
                                                             [dictionary setObject:filePath forKey:@"url"];
                                                             [dictionary setObject:filePath forKey:@"filePath"];
                                                             
                                                             if(![dict objectForKey:(@"发动机号码")]){
                                                                 [dictionary setObject:@"" forKey:@"engineNum"];
                                                             }else{
                                                                 NSDictionary* cDict = [dict objectForKey:@"发动机号码"];
                                                                 if(![cDict objectForKey:(@"words")]){
                                                                     [dictionary setObject:@"" forKey:@"engineNum"];
                                                                 }else{
                                                                     [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"engineNum"];
                                                                 }
                                                             }
                                                             
                                                             if(![dict objectForKey:(@"号牌号码")]){
                                                                 [dictionary setObject:@"" forKey:@"carNum"];
                                                             }else{
                                                                 NSDictionary* cDict = [dict objectForKey:@"号牌号码"];
                                                                 if(![cDict objectForKey:(@"words")]){
                                                                     [dictionary setObject:@"" forKey:@"carNum"];
                                                                 }else{
                                                                     [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"carNum"];
                                                                 }
                                                             }
                                                             
                                                             if(![dict objectForKey:(@"所有人")]){
                                                                 [dictionary setObject:@"" forKey:@"allPeople"];
                                                             }else{
                                                                 NSDictionary* cDict = [dict objectForKey:@"所有人"];
                                                                 if(![cDict objectForKey:(@"words")]){
                                                                     [dictionary setObject:@"" forKey:@"allPeople"];
                                                                 }else{
                                                                     [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"allPeople"];
                                                                 }
                                                             }
                                                             
                                                             if(![dict objectForKey:(@"使用性质")]){
                                                                 [dictionary setObject:@"" forKey:@"useNature"];
                                                             }else{
                                                                 NSDictionary* cDict = [dict objectForKey:@"使用性质"];
                                                                 if(![cDict objectForKey:(@"words")]){
                                                                     [dictionary setObject:@"" forKey:@"useNature"];
                                                                 }else{
                                                                     [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"useNature"];
                                                                 }
                                                             }
                                                             
                                                             if(![dict objectForKey:(@"住址")]){
                                                                 [dictionary setObject:@"" forKey:@"address"];
                                                             }else{
                                                                 NSDictionary* cDict = [dict objectForKey:@"住址"];
                                                                 if(![cDict objectForKey:(@"words")]){
                                                                     [dictionary setObject:@"" forKey:@"address"];
                                                                 }else{
                                                                     [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"address"];
                                                                 }
                                                             }
                                                             
                                                             if(![dict objectForKey:(@"注册登记日期")]){
                                                                 [dictionary setObject:@"" forKey:@"regDate"];
                                                             }else{
                                                                 NSDictionary* cDict = [dict objectForKey:@"注册登记日期"];
                                                                 if(![cDict objectForKey:(@"words")]){
                                                                     [dictionary setObject:@"" forKey:@"regDate"];
                                                                 }else{
                                                                     [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"regDate"];
                                                                 }
                                                             }
                                                             
                                                             if(![dict objectForKey:(@"车辆识别代号")]){
                                                                 [dictionary setObject:@"" forKey:@"carIdentificationNum"];
                                                             }else{
                                                                 NSDictionary* cDict = [dict objectForKey:@"车辆识别代号"];
                                                                 if(![cDict objectForKey:(@"words")]){
                                                                     [dictionary setObject:@"" forKey:@"carIdentificationNum"];
                                                                 }else{
                                                                     [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"carIdentificationNum"];
                                                                 }
                                                             }
                                                             
                                                             if(![dict objectForKey:(@"品牌型号")]){
                                                                 [dictionary setObject:@"" forKey:@"brandType"];
                                                             }else{
                                                                 NSDictionary* cDict = [dict objectForKey:@"品牌型号"];
                                                                 if(![cDict objectForKey:(@"words")]){
                                                                     [dictionary setObject:@"" forKey:@"brandType"];
                                                                 }else{
                                                                     [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"brandType"];
                                                                 }
                                                             }
                                                             
                                                             if(![dict objectForKey:(@"车辆类型")]){
                                                                 [dictionary setObject:@"" forKey:@"carType"];
                                                             }else{
                                                                 NSDictionary* cDict = [dict objectForKey:@"车辆类型"];
                                                                 if(![cDict objectForKey:(@"words")]){
                                                                     [dictionary setObject:@"" forKey:@"carType"];
                                                                 }else{
                                                                     [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"carType"];
                                                                 }
                                                             }
                                                             
                                                             if(![dict objectForKey:(@"发证日期")]){
                                                                 [dictionary setObject:@"" forKey:@"startCardDate"];
                                                             }else{
                                                                 NSDictionary* cDict = [dict objectForKey:@"发证日期"];
                                                                 if(![cDict objectForKey:(@"words")]){
                                                                     [dictionary setObject:@"" forKey:@"startCardDate"];
                                                                 }else{
                                                                     [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"startCardDate"];
                                                                 }
                                                             }

                                                             [self sendEventWithName:@"BaiDuOcrEmitter" body:dictionary];
                                                             [[self getRootVC].presentingViewController dismissViewControllerAnimated:YES completion:nil ];
                                                         });
                                                     }
                                                        failHandler:^(NSError *error){
                                                            NSLog(@"识别失败回调= %@", error);
                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                NSDictionary *dict = @{
                                                                                       @"error":@-1,
                                                                                       @"type":@"DRIVING_LICENSE",
                                                                                       @"url":filePath,
                                                                                       @"filePath":filePath,
                                                                                       @"msg":error.localizedDescription
                                                                                       };
                                                                [self sendEventWithName:@"BaiDuOcrEmitter" body:dict];
                                                                [[self getRootVC].presentingViewController dismissViewControllerAnimated:YES completion:nil ];
                                                            });
                                                        }];
    }];
    [[self getRootVC] presentViewController: vc animated:YES completion:nil];
}



//驾驶证识别
-(void) driverLicenseIdentification{
    UIViewController * vc =
    [AipGeneralVC ViewControllerWithHandler:^(UIImage *image) {
        UIImage *smallImage = [UIImage imageWithCGImage:[image CGImage]];
        //JEPG格式
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString*  img_name = [[NSString alloc] initWithFormat:@"img_%@.jpg", [RCTBaiDuOcrModule getNowTimeTimestamp]];
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:img_name];
        [UIImageJPEGRepresentation(smallImage, 0.6) writeToFile:filePath atomically:YES];
        [[AipOcrService shardService] detectDrivingLicenseFromImage:image
                                                     withOptions:nil
                                                  successHandler:^(id result){
                                                      NSDictionary* dict = [result objectForKey:(@"words_result")];
                                                      NSLog(@"识别成功回调= %@", dict);
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:14];
                                                          [dictionary setObject:@0 forKey:@"error"];
                                                          [dictionary setObject:@"DRIVER_LICENSE" forKey:@"type"];
                                                          [dictionary setObject:filePath forKey:@"url"];
                                                          [dictionary setObject:filePath forKey:@"filePath"];
                                                          
                                                          if(![dict objectForKey:(@"准驾车型")]){
                                                              [dictionary setObject:@"" forKey:@"carType"];
                                                          }else{
                                                              NSDictionary* cDict = [dict objectForKey:@"准驾车型"];
                                                              if(![cDict objectForKey:(@"words")]){
                                                                  [dictionary setObject:@"" forKey:@"carType"];
                                                              }else{
                                                                  [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"carType"];
                                                              }
                                                          }
                                                          
                                                          if(![dict objectForKey:(@"证号")]){
                                                              [dictionary setObject:@"" forKey:@"cardNum"];
                                                          }else{
                                                              NSDictionary* cDict = [dict objectForKey:@"证号"];
                                                              if(![cDict objectForKey:(@"words")]){
                                                                  [dictionary setObject:@"" forKey:@"cardNum"];
                                                              }else{
                                                                  [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"cardNum"];
                                                              }
                                                          }
                                                          
                                                          if(![dict objectForKey:(@"住址")]){
                                                              [dictionary setObject:@"" forKey:@"address"];
                                                          }else{
                                                              NSDictionary* cDict = [dict objectForKey:@"住址"];
                                                              if(![cDict objectForKey:(@"words")]){
                                                                  [dictionary setObject:@"" forKey:@"address"];
                                                              }else{
                                                                  [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"address"];
                                                              }
                                                          }
                                                          
                                                          if(![dict objectForKey:(@"姓名")]){
                                                              [dictionary setObject:@"" forKey:@"name"];
                                                          }else{
                                                              NSDictionary* cDict = [dict objectForKey:@"姓名"];
                                                              if(![cDict objectForKey:(@"words")]){
                                                                  [dictionary setObject:@"" forKey:@"name"];
                                                              }else{
                                                                  [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"name"];
                                                              }
                                                          }
                                                          
                                                          if(![dict objectForKey:(@"至")]){
                                                              [dictionary setObject:@"" forKey:@"to"];
                                                          }else{
                                                              NSDictionary* cDict = [dict objectForKey:@"至"];
                                                              if(![cDict objectForKey:(@"words")]){
                                                                  [dictionary setObject:@"" forKey:@"to"];
                                                              }else{
                                                                  [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"to"];
                                                              }
                                                          }
                                                          
                                                          if(![dict objectForKey:(@"性别")]){
                                                              [dictionary setObject:@"" forKey:@"sex"];
                                                          }else{
                                                              NSDictionary* cDict = [dict objectForKey:@"性别"];
                                                              if(![cDict objectForKey:(@"words")]){
                                                                  [dictionary setObject:@"" forKey:@"sex"];
                                                              }else{
                                                                  [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"sex"];
                                                              }
                                                          }
                                                          
                                                          if(![dict objectForKey:(@"出生日期")]){
                                                              [dictionary setObject:@"" forKey:@"birthDate"];
                                                          }else{
                                                              NSDictionary* cDict = [dict objectForKey:@"出生日期"];
                                                              if(![cDict objectForKey:(@"words")]){
                                                                  [dictionary setObject:@"" forKey:@"birthDate"];
                                                              }else{
                                                                  [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"birthDate"];
                                                              }
                                                          }
                                                          
                                                          if(![dict objectForKey:(@"初次领证日期")]){
                                                              [dictionary setObject:@"" forKey:@"firstReceiveDate"];
                                                          }else{
                                                              NSDictionary* cDict = [dict objectForKey:@"初次领证日期"];
                                                              if(![cDict objectForKey:(@"words")]){
                                                                  [dictionary setObject:@"" forKey:@"firstReceiveDate"];
                                                              }else{
                                                                  [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"firstReceiveDate"];
                                                              }
                                                          }
                                                          
                                                          if(![dict objectForKey:(@"国籍")]){
                                                              [dictionary setObject:@"" forKey:@"nationality"];
                                                          }else{
                                                              NSDictionary* cDict = [dict objectForKey:@"国籍"];
                                                              if(![cDict objectForKey:(@"words")]){
                                                                  [dictionary setObject:@"" forKey:@"nationality"];
                                                              }else{
                                                                  [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"nationality"];
                                                              }
                                                          }
                                                          
                                                          if(![dict objectForKey:(@"有效期限")]){
                                                              [dictionary setObject:@"" forKey:@"validDate"];
                                                          }else{
                                                              NSDictionary* cDict = [dict objectForKey:@"有效期限"];
                                                              if(![cDict objectForKey:(@"words")]){
                                                                  [dictionary setObject:@"" forKey:@"validDate"];
                                                              }else{
                                                                  [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"validDate"];
                                                              }
                                                          }
                                                          
                                                          [self sendEventWithName:@"BaiDuOcrEmitter" body:dictionary];
                                                          [[self getRootVC].presentingViewController dismissViewControllerAnimated:YES completion:nil ];
                                                      });
                                                  }
                                                     failHandler:^(NSError *error){
                                                         NSLog(@"识别失败回调= %@", error);
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                             NSDictionary *dict = @{
                                                                                    @"error":@-1,
                                                                                    @"type":@"DRIVER_LICENSE",
                                                                                    @"url":filePath,
                                                                                    @"filePath":filePath,
                                                                                    @"msg":error.localizedDescription
                                                                                    };
                                                             [self sendEventWithName:@"BaiDuOcrEmitter" body:dict];
                                                             [[self getRootVC].presentingViewController dismissViewControllerAnimated:YES completion:nil ];
                                                         });
                                                     }];
    }];
    [[self getRootVC] presentViewController: vc animated:YES completion:nil];
}



//车牌识别
-(void) plateLicenseIdentification{
    UIViewController * vc =
    [AipGeneralVC ViewControllerWithHandler:^(UIImage *image) {
        UIImage *smallImage = [UIImage imageWithCGImage:[image CGImage]];
        //JEPG格式
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString*  img_name = [[NSString alloc] initWithFormat:@"img_%@.jpg", [RCTBaiDuOcrModule getNowTimeTimestamp]];
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:img_name];
        [UIImageJPEGRepresentation(smallImage, 0.6) writeToFile:filePath atomically:YES];
        [[AipOcrService shardService] detectPlateNumberFromImage:image
                                                         withOptions:nil
                                                      successHandler:^(id result){
                                                          NSDictionary* dict = [result objectForKey:(@"words_result")];
                                                          NSLog(@"识别成功回调= %@", dict);
                                                          dispatch_async(dispatch_get_main_queue(), ^{
                                                              NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:12];
                                                              [dictionary setObject:@0 forKey:@"error"];
                                                              [dictionary setObject:@"PLATE_LICENSE" forKey:@"type"];
                                                              [dictionary setObject:filePath forKey:@"url"];
                                                              [dictionary setObject:filePath forKey:@"filePath"];
                                                              
                                                              if(![dict objectForKey:(@"color")]){
                                                                  [dictionary setObject:@"" forKey:@"color"];
                                                              }else{
                                                                  [dictionary setObject:[dict objectForKey:@"color"] forKey:@"color"];
                                                              }
                                                              
                                                              if(![dict objectForKey:(@"number")]){
                                                                  [dictionary setObject:@"" forKey:@"number"];
                                                              }else{
                                                                  [dictionary setObject:[dict objectForKey:@"number"] forKey:@"number"];
                                                              }
                                                              
                                                              [self sendEventWithName:@"BaiDuOcrEmitter" body:dictionary];
                                                              [[self getRootVC].presentingViewController dismissViewControllerAnimated:YES completion:nil ];
                                                          });
                                                      }
                                                         failHandler:^(NSError *error){
                                                             NSLog(@"识别失败回调= %@", error);
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 NSDictionary *dict = @{
                                                                                        @"error":@-1,
                                                                                        @"type":@"PLATE_LICENSE",
                                                                                        @"url":filePath,
                                                                                        @"filePath":filePath,
                                                                                        @"msg":error.localizedDescription
                                                                                        };
                                                                 [self sendEventWithName:@"BaiDuOcrEmitter" body:dict];
                                                                 [[self getRootVC].presentingViewController dismissViewControllerAnimated:YES completion:nil ];
                                                             });
                                                         }];
    }];
    [[self getRootVC] presentViewController: vc animated:YES completion:nil];
}


//营业执照识别
-(void) businessLicenseIdentification{
    UIViewController * vc =
    [AipGeneralVC ViewControllerWithHandler:^(UIImage *image) {
                                     UIImage *smallImage = [UIImage imageWithCGImage:[image CGImage]];
                                     //JEPG格式
                                     NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                     NSString*  img_name = [[NSString alloc] initWithFormat:@"img_%@.jpg", [RCTBaiDuOcrModule getNowTimeTimestamp]];
                                     NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:img_name];
                                     [UIImageJPEGRepresentation(smallImage, 0.6) writeToFile:filePath atomically:YES];
                                     [[AipOcrService shardService] detectBusinessLicenseFromImage:image
                                                                            withOptions:nil
                                                                            successHandler:^(id result){
                                                                                NSDictionary* dict = [result objectForKey:(@"words_result")];
                                                                                NSLog(@"识别成功回调= %@", dict);
                                                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                                                    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:12];
                                                                                    [dictionary setObject:@0 forKey:@"error"];
                                                                                    [dictionary setObject:@"BUSINESS_LICENSE" forKey:@"type"];
                                                                                    [dictionary setObject:filePath forKey:@"url"];
                                                                                    [dictionary setObject:filePath forKey:@"filePath"];
                                                                                    
                                                                                    if(![dict objectForKey:(@"社会信用代码")]){
                                                                                        [dictionary setObject:@"" forKey:@"socialCreditCode"];
                                                                                    }else{
                                                                                        NSDictionary* cDict = [dict objectForKey:@"社会信用代码"];
                                                                                        if(![cDict objectForKey:(@"words")]){
                                                                                            [dictionary setObject:@"" forKey:@"socialCreditCode"];
                                                                                        }else{
                                                                                            [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"socialCreditCode"];
                                                                                        }
                                                                                    }
                                                                                    
                                                                                    if(![dict objectForKey:(@"法人")]){
                                                                                        [dictionary setObject:@"" forKey:@"principal"];
                                                                                    }else{
                                                                                        NSDictionary* cDict = [dict objectForKey:@"法人"];
                                                                                        if(![cDict objectForKey:(@"words")]){
                                                                                            [dictionary setObject:@"" forKey:@"principal"];
                                                                                        }else{
                                                                                            [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"principal"];
                                                                                        }
                                                                                    }
                                                                                    
                                                                                    if(![dict objectForKey:(@"单位名称")]){
                                                                                        [dictionary setObject:@"" forKey:@"unitName"];
                                                                                    }else{
                                                                                        NSDictionary* cDict = [dict objectForKey:@"单位名称"];
                                                                                        if(![cDict objectForKey:(@"words")]){
                                                                                            [dictionary setObject:@"" forKey:@"unitName"];
                                                                                        }else{
                                                                                            [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"unitName"];
                                                                                        }
                                                                                    }
                                                                                    
                                                                                    if(![dict objectForKey:(@"成立日期")]){
                                                                                        [dictionary setObject:@"" forKey:@"buildDate"];
                                                                                    }else{
                                                                                        NSDictionary* cDict = [dict objectForKey:@"成立日期"];
                                                                                        if(![cDict objectForKey:(@"words")]){
                                                                                            [dictionary setObject:@"" forKey:@"buildDate"];
                                                                                        }else{
                                                                                            [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"buildDate"];
                                                                                        }
                                                                                    }
                                                                                    
                                                                                    if(![dict objectForKey:(@"证件编号")]){
                                                                                        [dictionary setObject:@"" forKey:@"cardNum"];
                                                                                    }else{
                                                                                        NSDictionary* cDict = [dict objectForKey:@"证件编号"];
                                                                                        if(![cDict objectForKey:(@"words")]){
                                                                                            [dictionary setObject:@"" forKey:@"cardNum"];
                                                                                        }else{
                                                                                            [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"cardNum"];
                                                                                        }
                                                                                    }
                                                                                    
                                                                                    if(![dict objectForKey:(@"注册资本")]){
                                                                                        [dictionary setObject:@"" forKey:@"regCapital"];
                                                                                    }else{
                                                                                        NSDictionary* cDict = [dict objectForKey:@"注册资本"];
                                                                                        if(![cDict objectForKey:(@"words")]){
                                                                                            [dictionary setObject:@"" forKey:@"regCapital"];
                                                                                        }else{
                                                                                            [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"regCapital"];
                                                                                        }
                                                                                    }
                                                                                    
                                                                                    if(![dict objectForKey:(@"有效期")]){
                                                                                        [dictionary setObject:@"" forKey:@"effectiveDate"];
                                                                                    }else{
                                                                                        NSDictionary* cDict = [dict objectForKey:@"有效期"];
                                                                                        if(![cDict objectForKey:(@"words")]){
                                                                                            [dictionary setObject:@"" forKey:@"effectiveDate"];
                                                                                        }else{
                                                                                            [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"effectiveDate"];
                                                                                        }
                                                                                    }
                                                                                    
                                                                                    if(![dict objectForKey:(@"地址")]){
                                                                                        [dictionary setObject:@"" forKey:@"address"];
                                                                                    }else{
                                                                                        NSDictionary* cDict = [dict objectForKey:@"地址"];
                                                                                        if(![cDict objectForKey:(@"words")]){
                                                                                            [dictionary setObject:@"" forKey:@"address"];
                                                                                        }else{
                                                                                            [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"address"];
                                                                                        }
                                                                                    }
                                                                                    [self sendEventWithName:@"BaiDuOcrEmitter" body:dictionary];
                                                                                    [[self getRootVC].presentingViewController dismissViewControllerAnimated:YES completion:nil ];
                                                                                });
                                                                            }
                                                                               failHandler:^(NSError *error){
                                                                                   NSLog(@"识别失败回调= %@", error);
                                                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                                                       NSDictionary *dict = @{
                                                                                                              @"error":@-1,
                                                                                                              @"type":@"BUSINESS_LICENSE",
                                                                                                              @"url":filePath,
                                                                                                              @"filePath":filePath,
                                                                                                              @"msg":error.localizedDescription
                                                                                                              };
                                                                                       [self sendEventWithName:@"BaiDuOcrEmitter" body:dict];
                                                                                       [[self getRootVC].presentingViewController dismissViewControllerAnimated:YES completion:nil ];
                                                                                   });
                                                                               }];
                                 }];
    [[self getRootVC] presentViewController: vc animated:YES completion:nil];
}

//银行卡识别
-(void) BankCardIdentification{
    UIViewController * vc =
    [AipCaptureCardVC ViewControllerWithCardType:CardTypeBankCard
                                 andImageHandler:^(UIImage *image) {
                                     UIImage *smallImage = [UIImage imageWithCGImage:[image CGImage]];
                                     //JEPG格式
                                     NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                     NSString*  img_name = [[NSString alloc] initWithFormat:@"img_%@.jpg", [RCTBaiDuOcrModule getNowTimeTimestamp]];
                                     NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:img_name];
                                     [UIImageJPEGRepresentation(smallImage, 0.6) writeToFile:filePath atomically:YES];
                                     [[AipOcrService shardService] detectBankCardFromImage:image
                                                                               successHandler:^(id result){
                                                                                   NSDictionary* dict = [result objectForKey:(@"result")];
                                                                                   NSLog(@"识别成功回调= %@", dict);
                                                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                                                         NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:10];
                                                                                         [dictionary setObject:@0 forKey:@"error"];
                                                                                          [dictionary setObject:@"BANK_CARD" forKey:@"type"];
                                                                                          [dictionary setObject:filePath forKey:@"url"];
                                                                                          [dictionary setObject:filePath forKey:@"filePath"];
                                                                                         if(![dict objectForKey:(@"bank_card_type")]){
                                                                                             [dictionary setObject:@"" forKey:@"cardType"];
                                                                                         }else{
                                                                                             [dictionary setObject:[dict objectForKey:@"bank_card_type"] forKey:@"cardType"];
                                                                                         }
                                                                                         
                                                                                         if(![dict objectForKey:(@"bank_card_number")]){
                                                                                             [dictionary setObject:@"" forKey:@"cardNum"];
                                                                                         }else{
                                                                                             [dictionary setObject:[dict objectForKey:@"bank_card_number"] forKey:@"cardNum"];
                                                                                         }
                                                                                         
                                                                                         if(![dict objectForKey:(@"bank_name")]){
                                                                                             [dictionary setObject:@"" forKey:@"cardName"];
                                                                                         }else{
                                                                                             [dictionary setObject:[dict objectForKey:@"bank_name"] forKey:@"cardName"];
                                                                                         }
                                                                                         
                                                                                         if(![dict objectForKey:(@"valid_date")]){
                                                                                             [dictionary setObject:@"" forKey:@"validDate"];
                                                                                         }else{
                                                                                             [dictionary setObject:[dict objectForKey:@"valid_date"] forKey:@"validDate"];
                                                                                         }
                                                                                         
                                                                                          [self sendEventWithName:@"BaiDuOcrEmitter" body:dictionary];
                                                                                          [[self getRootVC].presentingViewController dismissViewControllerAnimated:YES completion:nil ];
                                                                                     });
                                                                               }
                                                                              failHandler:^(NSError *error){
                                                                                      NSLog(@"识别失败回调= %@", error);
                                                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                                                      NSDictionary *dict = @{
                                                                                                             @"error":@-1,
                                                                                                             @"type":@"BANK_CARD",
                                                                                                             @"url":filePath,
                                                                                                             @"filePath":filePath,
                                                                                                             @"msg":error.localizedDescription
                                                                                                             };
                                                                                           [self sendEventWithName:@"BaiDuOcrEmitter" body:dict];
                                                                                           [[self getRootVC].presentingViewController dismissViewControllerAnimated:YES completion:nil ];
                                                                                      });
                                                                                  }];
                                     
                                 }];
    [[self getRootVC] presentViewController: vc animated:YES completion:nil];
    
}

//身份证识别 正面
-(void) identityIdentificationPositive{
    UIViewController * vc =
    [AipCaptureCardVC ViewControllerWithCardType:CardTypeIdCardFont
                                 andImageHandler:^(UIImage *image) {
                                     
                                     UIImage *smallImage = [UIImage imageWithCGImage:[image CGImage]];
                                     //JEPG格式
                                     NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                     NSString*  img_name = [[NSString alloc] initWithFormat:@"img_%@.jpg", [RCTBaiDuOcrModule getNowTimeTimestamp]];
                                     NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:img_name];
                                     [UIImageJPEGRepresentation(smallImage, 0.6) writeToFile:filePath atomically:YES];
                                     [[AipOcrService shardService] detectIdCardFrontFromImage:image
                                                                                  withOptions:nil
                                                                               successHandler:^(id result){
                                                                                   NSDictionary* dict = [result objectForKey:(@"words_result")];
                                                                                   
//                                                                                    NSArray* keys = [dict allKeys];
//                                                                                    for(int i=0;i<keys.count;i++){
//                                                                                        NSString* key = keys[i];
//                                                                                        NSLog(@"%@=%@",key,[dict objectForKey:key]);
//                                                                                    }
                                                                                   
                                                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                                                       NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:10];
                                                                                       [dictionary setObject:@0 forKey:@"error"];
                                                                                       [dictionary setObject:@"CARD_FRONT" forKey:@"type"];
                                                                                       [dictionary setObject:filePath forKey:@"url"];
                                                                                       [dictionary setObject:filePath forKey:@"filePath"];
                                                                                       
                                                                                       if(![dict objectForKey:(@"姓名")]){
                                                                                           [dictionary setObject:@"" forKey:@"name"];
                                                                                       }else{
                                                                                           NSDictionary* cDict = [dict objectForKey:@"姓名"];
                                                                                           if(![cDict objectForKey:(@"words")]){
                                                                                               [dictionary setObject:@"" forKey:@"name"];
                                                                                           }else{
                                                                                               [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"name"];
                                                                                           }
                                                                                       }
                                                                                       
                                                                                       if(![dict objectForKey:(@"性别")]){
                                                                                           [dictionary setObject:@"" forKey:@"sex"];
                                                                                       }else{
                                                                                           NSDictionary* cDict = [dict objectForKey:@"性别"];
                                                                                           if(![cDict objectForKey:(@"words")]){
                                                                                               [dictionary setObject:@"" forKey:@"sex"];
                                                                                           }else{
                                                                                               [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"sex"];
                                                                                           }
                                                                                       }
                                                                                       
                                                                                       if(![dict objectForKey:(@"民族")]){
                                                                                           [dictionary setObject:@"" forKey:@"nation"];
                                                                                       }else{
                                                                                           NSDictionary* cDict = [dict objectForKey:@"民族"];
                                                                                           if(![cDict objectForKey:(@"words")]){
                                                                                               [dictionary setObject:@"" forKey:@"nation"];
                                                                                           }else{
                                                                                               [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"nation"];
                                                                                           }
                                                                                       }
                                                                                       
                                                                                       if(![dict objectForKey:(@"出生")]){
                                                                                           [dictionary setObject:@"" forKey:@"birthday"];
                                                                                       }else{
                                                                                           NSDictionary* cDict = [dict objectForKey:@"出生"];
                                                                                           if(![cDict objectForKey:(@"words")]){
                                                                                               [dictionary setObject:@"" forKey:@"birthday"];
                                                                                           }else{
                                                                                               [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"birthday"];
                                                                                           }
                                                                                       }
                                                                                       
                                                                                       if(![dict objectForKey:(@"住址")]){
                                                                                           [dictionary setObject:@"" forKey:@"address"];
                                                                                       }else{
                                                                                           NSDictionary* cDict = [dict objectForKey:@"住址"];
                                                                                           if(![cDict objectForKey:(@"words")]){
                                                                                               [dictionary setObject:@"" forKey:@"address"];
                                                                                           }else{
                                                                                               [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"address"];
                                                                                           }
                                                                                       }
                                                                                       
                                                                                       if(![dict objectForKey:(@"公民身份号码")]){
                                                                                           [dictionary setObject:@"" forKey:@"num"];
                                                                                       }else{
                                                                                           NSDictionary* cDict = [dict objectForKey:@"公民身份号码"];
                                                                                           if(![cDict objectForKey:(@"words")]){
                                                                                               [dictionary setObject:@"" forKey:@"num"];
                                                                                           }else{
                                                                                               [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"num"];
                                                                                           }
                                                                                       }
                                                                                        [self sendEventWithName:@"BaiDuOcrEmitter" body:dictionary];
                                                                                       [[self getRootVC].presentingViewController dismissViewControllerAnimated:YES completion:nil ];
                                                                                   });
                                                                               }
                                                                                  failHandler:^(NSError *error){
                                                                                      NSLog(@"识别失败回调= %@", error);
                                                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                                                          NSDictionary *dict = @{
                                                                                                                 @"error":@-1,
                                                                                                                 @"type":@"CARD_FRONT",
                                                                                                                 @"url":filePath,
                                                                                                                 @"filePath":filePath,
                                                                                                                 @"msg":error.localizedDescription
                                                                                                                 };
                                                                                          
                                                                                          [self sendEventWithName:@"BaiDuOcrEmitter" body:dict];
                                                                                          [[self getRootVC].presentingViewController dismissViewControllerAnimated:YES completion:nil ];
                                                                                      });
                                                                                  }];
                                     
                                 }];
    
    [[self getRootVC] presentViewController: vc animated:YES completion:nil];
}


//身份证识别 反面
-(void) identityIdentificationNegative{
    UIViewController * vc =
    [AipCaptureCardVC ViewControllerWithCardType:CardTypeIdCardBack
                                 andImageHandler:^(UIImage *image) {
                                     UIImage *smallImage = [UIImage imageWithCGImage:[image CGImage]];
                                     //JEPG格式
                                     NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                     NSString*  img_name = [[NSString alloc] initWithFormat:@"img_%@.jpg", [RCTBaiDuOcrModule getNowTimeTimestamp]];
                                     NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:img_name];
                                     [UIImageJPEGRepresentation(smallImage, 0.6) writeToFile:filePath atomically:YES];
                                     [[AipOcrService shardService] detectIdCardBackFromImage:image
                                                                                  withOptions:nil
                                                                              successHandler:^(id result){
                                                                                  NSDictionary* dict = [result objectForKey:(@"words_result")];
                                                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                                                      
                                                                                      NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:10];
                                                                                      [dictionary setObject:@0 forKey:@"error"];
                                                                                      [dictionary setObject:@"CARD_BACK" forKey:@"type"];
                                                                                      [dictionary setObject:filePath forKey:@"url"];
                                                                                      [dictionary setObject:filePath forKey:@"filePath"];

                                                                                      if(![dict objectForKey:(@"签发日期")]){
                                                                                          [dictionary setObject:@"" forKey:@"signDate"];
                                                                                      }else{
                                                                                          NSDictionary* cDict = [dict objectForKey:@"签发日期"];
                                                                                          if(![cDict objectForKey:(@"words")]){
                                                                                              [dictionary setObject:@"" forKey:@"signDate"];
                                                                                          }else{
                                                                                              [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"signDate"];
                                                                                          }
                                                                                      }
                                                                                      
                                                                                      if(![dict objectForKey:(@"失效日期")]){
                                                                                          [dictionary setObject:@"" forKey:@"expiryDate"];
                                                                                      }else{
                                                                                          NSDictionary* cDict = [dict objectForKey:@"失效日期"];
                                                                                          if(![cDict objectForKey:(@"words")]){
                                                                                              [dictionary setObject:@"" forKey:@"expiryDate"];
                                                                                          }else{
                                                                                              [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"expiryDate"];
                                                                                          }
                                                                                      }
                                                                                      
                                                                                      if(![dict objectForKey:(@"签发机关")]){
                                                                                          [dictionary setObject:@"" forKey:@"signUnit"];
                                                                                      }else{
                                                                                          NSDictionary* cDict = [dict objectForKey:@"签发机关"];
                                                                                          if(![cDict objectForKey:(@"words")]){
                                                                                               [dictionary setObject:@"" forKey:@"signUnit"];
                                                                                          }else{
                                                                                               [dictionary setObject:[cDict objectForKey:@"words"] forKey:@"signUnit"];
                                                                                          }
                                                                                      }
                                                                                      
                                                                                      [self sendEventWithName:@"BaiDuOcrEmitter" body:dictionary];
                                                                                      [[self getRootVC].presentingViewController dismissViewControllerAnimated:YES completion:nil ];
                                                                                  });
                                                                              }
                                                                                 failHandler:^(NSError *error){
                                                                                     NSLog(@"识别失败回调= %@", error);
                                                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                                                         NSDictionary *dict = @{
                                                                                                                @"error":@-1,
                                                                                                                @"type":@"CARD_BACK",
                                                                                                                @"url":filePath,
                                                                                                                @"filePath":filePath,
                                                                                                                @"msg":error.localizedDescription
                                                                                                                };
                                                                                         [self sendEventWithName:@"BaiDuOcrEmitter" body:dict];
                                                                                         [[self getRootVC].presentingViewController dismissViewControllerAnimated:YES completion:nil ];
                                                                                     });
                                                                                 }];
                                     
                                 }];
    
    [[self getRootVC] presentViewController: vc animated:YES completion:nil];
}


@end
