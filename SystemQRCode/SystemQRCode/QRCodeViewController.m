//
//  QRCodeViewController.m
//  SystemQRCode
//
//  Created by Edwin on 16/3/21.
//  Copyright © 2016年 EdwinXiang. All rights reserved.
//

#import "QRCodeViewController.h"
#define kDeviceWidth [UIScreen mainScreen].bounds.size.width
#define kDeviceHeight [UIScreen mainScreen].bounds.size.height
@interface QRCodeViewController ()<UIAlertViewDelegate>
{
        AVCaptureDevice * _device;
        AVCaptureDeviceInput * _input;
        AVCaptureMetadataOutput * _output;
        AVCaptureVideoPreviewLayer * _preview;
        AVCaptureSession *_session;
        UIImageView      *_scanView;
        UIImageView      *_lineView;
        
        BOOL _ledStatu;
    
}
@end

@implementation QRCodeViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupCamera];
}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"二维码";
    self.view.backgroundColor = [UIColor lightGrayColor];
//    self.navigationItem.leftBarButtonItems = @[self.nagativeSeperator,self.returnBtn];
}


- (void)setupCamera
{
    [self initView];
    [self addReminderText];
}

#pragma mark AVCaptureMetadataOutputObjectsDelegate
- (void)initView {
    
    
    UIImage *scanImage = [UIImage imageNamed:@"scanscanBg"];
    CGFloat scanW = kDeviceWidth - 100;
    CGRect scanFrame = CGRectMake(50, (kDeviceHeight - scanW) / 2.0 - 70, scanW, scanW);
    _scanViewFrame = scanFrame;
    
    _scanView = [[UIImageView alloc] initWithImage:scanImage];
    _scanView.backgroundColor = [UIColor clearColor];
    _scanView.frame = scanFrame;
    [self.view addSubview:_scanView];
    
    
    
    // 初始化链接对象
    _session = [[AVCaptureSession alloc] init];
    //采集率
    _session.sessionPreset = AVCaptureSessionPresetHigh;
    
    // 获取摄像设备
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //创建输入流
    _input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:nil];
    if (_input) {
        [_session addInput:_input];
    } else {
        UIAlertView  *alert = [[UIAlertView alloc]initWithTitle:@"提示" message:@"无法使用相机" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
    }
    
    
    //创建输出流
    _output = [[AVCaptureMetadataOutput alloc] init];
    if (_output) {
        
        //设置代理 刷新线程
        [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        _output.rectOfInterest = [self rectOfInterestByScanViewRect:_scanViewFrame];
        [_session addOutput:_output];
        
        //设置扫码支持的编码格式
        NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:0];
        
        if ([_output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode]) {
            [array addObject:AVMetadataObjectTypeQRCode];
        }
        if ([_output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeEAN13Code]) {
            [array addObject:AVMetadataObjectTypeEAN13Code];
        }
        if ([_output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeEAN8Code]) {
            [array addObject:AVMetadataObjectTypeEAN8Code];
        }
        if ([_output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeCode128Code]) {
            [array addObject:AVMetadataObjectTypeCode128Code];
        }
        _output.metadataObjectTypes = array;
    }
    
    
    
    AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    layer.frame = self.view.bounds;
    [self.view.layer insertSublayer:layer above:0];
    
    [self.view bringSubviewToFront:_scanView];
    
    [self setOverView];
    
    [_session startRunning];
    [self loopDrawLine];
}



- (void)addReminderText {
    UILabel * labIntroudction= [[UILabel alloc] initWithFrame:CGRectMake(15, _scanViewFrame.origin.y + _scanViewFrame.size.height + 15, kDeviceWidth - 30, 20)];
    labIntroudction.backgroundColor = [UIColor clearColor];
    labIntroudction.numberOfLines=2;
    labIntroudction.textColor=[UIColor whiteColor];
    labIntroudction.text=@"将二维码置于方框内,即可自动扫描";
    labIntroudction.textAlignment = NSTextAlignmentCenter;
    labIntroudction.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:labIntroudction];
    
    UIButton * ledBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    ledBtn.frame = CGRectMake((kDeviceWidth - 80) / 2.0, CGRectGetMaxY(labIntroudction.frame) + 20, 80, 40);
    [ledBtn setTitleColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"logo_background.png"]] forState:UIControlStateNormal];
    [ledBtn setTitle:@"电筒" forState:UIControlStateNormal];
    ledBtn.titleLabel.font = [UIFont systemFontOfSize:18];
    [ledBtn addTarget:self action:@selector(ledClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:ledBtn];
}

- (void)ledClick:(id)sender {
    _ledStatu = !_ledStatu;
    if (_ledStatu) {
        [self turnOnLed];
    } else {
        [self turnOffLed];
    }
}

-(void)turnOnLed
{
    if ([_device hasTorch]) {
        [_device lockForConfiguration:nil];
        [_device setTorchMode: AVCaptureTorchModeOn];
        [_device unlockForConfiguration];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"闪光灯" message:@"抱歉，该设备没有闪光灯而无法使用手电筒功能！" delegate:nil
                                              cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    }
}


-(void)turnOffLed
{
    [_device lockForConfiguration:nil];
    [_device setTorchMode: AVCaptureTorchModeOff];
    [_device unlockForConfiguration];
}


- (CGRect)rectOfInterestByScanViewRect:(CGRect)rect {
    CGFloat width = CGRectGetWidth(self.view.frame);
    CGFloat height = CGRectGetHeight(self.view.frame);
    
    CGFloat x = CGRectGetMinY(rect)/ height;
    CGFloat y = CGRectGetMinX(rect) / width;
    
    CGFloat w = CGRectGetHeight(rect) / height;
    CGFloat h = CGRectGetWidth(rect) / width;
    
    return CGRectMake(x, y, w, h);
}

#pragma mark - 添加模糊效果
- (void)setOverView {
    CGFloat width = CGRectGetWidth(self.view.frame);
    CGFloat height = CGRectGetHeight(self.view.frame);
    
    CGFloat x = CGRectGetMinX(_scanView.frame);
    CGFloat y = CGRectGetMinY(_scanView.frame);
    CGFloat w = CGRectGetWidth(_scanView.frame);
    CGFloat h = CGRectGetHeight(_scanView.frame);
    
    [self creatView:CGRectMake(0, 0, width, y)];
    [self creatView:CGRectMake(0, y, x, h)];
    [self creatView:CGRectMake(0, y + h, width, height - y - h)];
    [self creatView:CGRectMake(x + w, y, width - x - w, h)];
}

- (void)creatView:(CGRect)rect {
    CGFloat alpha = 0.4;
    UIColor *backColor = [UIColor blackColor];
    UIView *view = [[UIView alloc] initWithFrame:rect];
    view.backgroundColor = backColor;
    view.alpha = alpha;
    [self.view addSubview:view];
}


#pragma mark - 动画
- (void)loopDrawLine {
    UIImage *lineImage = [UIImage imageNamed:@"scanLine"];
    
    CGFloat x = CGRectGetMinX(_scanView.frame);
    CGFloat y = CGRectGetMinY(_scanView.frame);
    CGFloat w = CGRectGetWidth(_scanView.frame);
    CGFloat h = CGRectGetHeight(_scanView.frame);
    
    CGRect start = CGRectMake(x, y, w, 2);
    CGRect end = CGRectMake(x, y + h - 2, w, 2);
    
    if (!_lineView) {
        _lineView = [[UIImageView alloc] initWithImage:lineImage];
        _lineView.frame = start;
        [self.view addSubview:_lineView];
    } else {
        _lineView.frame = start;
    }
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:2.0 animations:^{
        _lineView.frame = end;
    } completion:^(BOOL finished) {
        [weakSelf loopDrawLine];
    }];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects != nil && [metadataObjects count] > 0){
        
        __unused AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex:0];
        /**
         *  这是扫描到的结果，s自行处理
         */
        
        [self stopQRCodeScan];
        NSString *result = metadataObject.stringValue;
        NSLog(@"reslut === %@",result);
        if (!result) {
            return;
        }
//        SecondViewController *secondVc = [[SecondViewController alloc]init];
//        [self.navigationController pushViewController:secondVc animated:YES];
    } else {
        NSLog(@"不能识别该二维码");
    }
}

- (void)stopQRCodeScan
{
    // 1. 如果扫描完成，停止会话
    if (_session) {
        [_session stopRunning];
        _session = nil;
    }
    if (_session) {
        [_session removeOutput:_output];
        [_session stopRunning];
        _session = nil;
    }
    
    // 2. 删除预览图层
    [_preview removeFromSuperlayer];
    _preview = nil;
    
    [_output setMetadataObjectsDelegate:nil queue:dispatch_get_main_queue()];
    _output = nil;
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self backAction];
}


- (void)backAction
{
    [self stopQRCodeScan];
    self.navigationController.tabBarController.tabBar.hidden = NO;
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
