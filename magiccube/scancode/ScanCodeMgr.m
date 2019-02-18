//
//  ScanCodeMgr.m
//  magiccube
//
//  Created by 施哲晨 on 2019/2/9.
//  Copyright © 2019 magiccube. All rights reserved.
//

#import "ScanCodeMgr.h"
#import "MainLBXScanViewController.h"
#import "StyleDIY.h"
#import "Global.h"

@implementation ScanCodeMgr
+(void) start:(UIViewController*)aTarget{
    MainLBXScanViewController *vc = [MainLBXScanViewController new];
    vc.libraryType = [Global sharedManager].libraryType;
    vc.scanCodeType = [Global sharedManager].scanCodeType;
    vc.style = [StyleDIY qqStyle];
    //镜头拉远拉近功能
    vc.isVideoZoom = YES;
    vc.targetController = aTarget;
    //        [viewController presentViewController:about animated:YES completion:nil];
    [aTarget.navigationController pushViewController:vc animated:YES];
}
@end
