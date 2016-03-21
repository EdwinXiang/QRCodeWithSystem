//
//  QRCodeViewController.h
//  SystemQRCode
//
//  Created by Edwin on 16/3/21.
//  Copyright © 2016年 EdwinXiang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@interface QRCodeViewController : UIViewController<AVCaptureMetadataOutputObjectsDelegate>{
    int num;
    BOOL upOrdown;
}

// 签到类型
typedef NS_ENUM(long, QRType) {
    elevatorQR,
    signInQR,
};

@property (nonatomic, retain) UIImageView * line;
@property (nonatomic, assign) CGRect scanViewFrame;
@property (nonatomic, assign) BOOL isElevatorQR;
@property (nonatomic, assign) QRType qrType;
@property (nonatomic, assign) NSInteger imageIndex;
@property (nonatomic, assign) NSInteger signType;

@end
