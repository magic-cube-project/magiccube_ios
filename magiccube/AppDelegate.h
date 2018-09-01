//
//  AppDelegate.h
//  magiccube
//
//  Created by 施哲晨 on 2018/8/28.
//  Copyright © 2018年 magiccube. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

