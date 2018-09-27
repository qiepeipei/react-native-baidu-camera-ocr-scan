//
//  MMViewController.m
//  馍馍测试
//
//  Created by qiepeipei on 2018/9/27.
//  Copyright © 2018年 qiepeipei. All rights reserved.
//

#import "MMViewController.h"
#import "AVCaptureSessionManager.h"

@interface MMViewController ()
@property (nonatomic, strong) CADisplayLink *link;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scanTop;

@property (nonatomic, strong) AVCaptureSessionManager *session;
@end

@implementation MMViewController

-(instancetype)init{
    
//    NSBundle *bundle = [NSBundle bundleWithPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"QRCodeResource.bundle"]];
//
//    self = [[bundle loadNibNamed:@"MMViewController" owner:self options:nil] lastObject];
    
    NSBundle* bundle = [NSBundle bundleWithPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"QRCodeResource.bundle"]];

    self = [super initWithNibName:@"MMViewController" bundle:bundle];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 添加跟屏幕刷新频率一样的定时器
    CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(scan)];
    self.link = link;
    
    // 获取读取读取二维码的会话
    self.session = [[AVCaptureSessionManager alloc]initWithAVCaptureQuality:AVCaptureQualityHigh
                                                              AVCaptureType:AVCaptureTypeQRCode
                                                                   scanRect:CGRectNull
                                                               successBlock:^(NSString *reuslt) {
                                                                   [self showResult: reuslt];
                                                               }];
    self.session.isPlaySound = YES;
    
    [self.session showPreviewLayerInView:self.view];
}

- (void)showResult:(NSString *)result {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Scan_Send_Message" object:result userInfo:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)retClick:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    //    [self.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

// 在页面将要显示的时候添加定时器
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.session start];
    [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

// 在页面将要消失的时候移除定时器
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.session stop];
    [self.link removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 扫描效果
- (void)scan{
    self.scanTop.constant -= 3;
    if (self.scanTop.constant <= -170) {
        self.scanTop.constant = 170;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
