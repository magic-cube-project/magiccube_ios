//
//  _NoInputAccessoryView.h
//  magiccube
//
//  Created by 施哲晨 on 2019/2/7.
//  Copyright © 2019 magiccube. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface _NoInputAccessoryView : NSObject
- (id)inputAccessoryView;
- (void)hideWKWebviewKeyboardShortcutBar:(WKWebView *)webView;
@end

NS_ASSUME_NONNULL_END
