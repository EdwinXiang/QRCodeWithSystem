//
//  ViewController.m
//  SystemQRCode
//
//  Created by Edwin on 16/3/21.
//  Copyright © 2016年 EdwinXiang. All rights reserved.
//

#import "ViewController.h"
#import "QRCodeViewController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)btnClick:(UIButton *)sender {
    QRCodeViewController *qrcode = [[QRCodeViewController alloc]init];
    [self.navigationController pushViewController:qrcode animated:YES];
}

@end
