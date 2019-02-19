#import "ViewController.h"
#import <WebKit/WebKit.h>
#import <AVFoundation/AVFoundation.h>
#import "WebViewJavascriptBridge.h"
#import "_NoInputAccessoryView.h"
#import "scancode/ScanCodeMgr.h"
#import <objc/runtime.h>

@interface ViewController ()<WKUIDelegate,WKScriptMessageHandler,WKNavigationDelegate>

@property (strong, nonatomic)   WKWebView                   *webView;
@property (strong, nonatomic)   NSString                   *url;
@property (strong, nonatomic)   UIProgressView              *progressView;
@property (strong,nonatomic)    UIView  *launchView;   // 启动页view
@property WebViewJavascriptBridge* bridge;
/** 键盘谈起屏幕偏移量 */
@property (nonatomic, assign) CGPoint keyBoardPoint;
@end

@implementation ViewController

- (void)viewDidLoad {
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    [self initWKWebView];
    [self autoLayout];
    [self openLaunchView];
    UIApplication *app = [UIApplication sharedApplication];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:)name:UIApplicationWillEnterForegroundNotification object:app];
    
}

-(void) openLaunchView{
    CGRect frame = [[UIScreen mainScreen] bounds];//创建一个长方形结构体，用于UIView的位置和大学
    _launchView= [[UIView alloc]initWithFrame:frame];//初始化UIView
    [_launchView setBackgroundColor:[UIColor whiteColor]];//设置背景色，ios9之后，基本所有视图默认为透明色，为了看见要设置背景色
    [self.view addSubview:_launchView];//添加子视图
    
    UIImage *image = [UIImage imageNamed:@"launch-icon.png"];
    
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width-image.size.width/3)/2, CGRectGetMaxY(self.view.frame)-120, image.size.width/3,image.size.height/3)];
    imageView.image = image;
    [_launchView addSubview:imageView];
    
    NSTimeInterval duration = 0.2;
    [UIView animateWithDuration:duration animations:^{
        self->_launchView.alpha = 1.f;
    }];
    
}

-(void) closeLauchView{
    NSTimeInterval duration = 0.2;
    
    [UIView animateWithDuration:duration animations:^{
        self->_launchView.alpha = 0.f;
    } completion:^(BOOL finished) {
        [self->_launchView removeFromSuperview];
    }];
}

// 启动约束组件
- (void)autoLayout{
    WKWebView* webView = self.webView;
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    // 创建控件数组
    NSArray *hCos = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[webView]-0-|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(webView)];
    [self.view addConstraints:hCos];
    
    //竖直方向
    NSArray *vCos = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[webView]-0-|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(webView)];
    [self.view addConstraints:vCos];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{//进入前台时调用此函数
    [self onResult:@"enterForeground" didReceiveScriptMessage:@"null"];
}
- (id)inputAccessoryView {
    return nil;
}
- (void)removeInputAccessoryViewFromWKWebView:(WKWebView *)webView {
    UIView *targetView;
    
    for (UIView *view in webView.scrollView.subviews) {
        if([[view.class description] hasPrefix:@"WKContent"]) {
            targetView = view;
        }
    }
    
    if (!targetView) {
        return;
    }
    
    NSString *noInputAccessoryViewClassName = [NSString stringWithFormat:@"%@_NoInputAccessoryView", targetView.class.superclass];
    Class newClass = NSClassFromString(noInputAccessoryViewClassName);
    
    if(newClass == nil) {
        newClass = objc_allocateClassPair(targetView.class, [noInputAccessoryViewClassName cStringUsingEncoding:NSASCIIStringEncoding], 0);
        if(!newClass) {
            return;
        }
        
        Method method = class_getInstanceMethod([_NoInputAccessoryView class], @selector(inputAccessoryView));
        
        class_addMethod(newClass, @selector(inputAccessoryView), method_getImplementation(method), method_getTypeEncoding(method));
        
        objc_registerClassPair(newClass);
    }
    
    object_setClass(targetView, newClass);
}
//初始化页面
- (void)initWKWebView
{
    //进行配置控制器
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    //实例化对象
    configuration.userContentController = [WKUserContentController new];
    configuration.allowsInlineMediaPlayback = YES;
    [configuration.userContentController addScriptMessageHandler:self name:@"openWeb"];
    [configuration.userContentController addScriptMessageHandler:self name:@"scanCode"];
    [configuration.userContentController addScriptMessageHandler:self name:@"launchComplete"];
    if (@available(iOS 10.0, *)) {
        configuration.mediaTypesRequiringUserActionForPlayback = NO;
    } else {
        // Fallback on earlier versions
        configuration.mediaPlaybackRequiresUserAction = NO;
    }
    WKPreferences *preferences = [WKPreferences new];
    preferences.javaScriptCanOpenWindowsAutomatically = YES;
    configuration.preferences = preferences;
    self.webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:configuration];
    
//    _NoInputAccessoryView* o =  [_NoInputAccessoryView init];
//    [o hideWKWebviewKeyboardShortcutBar:self.webView];
    
    [self removeInputAccessoryViewFromWKWebView:self.webView];

    if (@available(iOS 11.0, *)) {
        self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        self.webView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        self.webView.scrollView.scrollIndicatorInsets = self.webView.scrollView.contentInset;
    } else{
          self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    /// 监听将要弹起
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardShow) name:UIKeyboardWillShowNotification object:nil];
    /// 监听将要隐藏
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardHidden) name:UIKeyboardWillHideNotification object:nil];

    // 获取默认User-Agent
    [self.webView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id result, NSError *error) {
        NSString *oldAgent = result;
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *appVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
        // 给User-Agent添加额外的信息
        NSString *newAgent = [NSString stringWithFormat:@"%@;%@", oldAgent, [@"APP/JHELLO app_version:" stringByAppendingString:appVersion]];
        // 设置global User-Agent
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:newAgent, @"UserAgent", nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
        [self.webView setCustomUserAgent:newAgent];
    }];
    
    //获取bundlePath 路径
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    //获取本地html目录 basePath
    NSString *basePath = [NSString stringWithFormat: @"%@/www", bundlePath];
    //获取本地html目录 baseUrl
    NSURL *baseUrl = [NSURL fileURLWithPath: basePath isDirectory: YES];
    NSLog(@"%@", baseUrl);
    //html 路径
    NSString *indexPath = [NSString stringWithFormat: @"%@/index.html", basePath];
    //html 文件中内容
    NSString *indexContent = [NSString stringWithContentsOfFile:
                              indexPath encoding: NSUTF8StringEncoding error:nil];
    //显示内容
    [self.webView loadHTMLString: indexContent baseURL: baseUrl];
    
    // 如果控制器里需要监听WKWebView 的`navigationDelegate`方法，就需要添加下面这行。
    self.webView.UIDelegate = self;
    self.webView.navigationDelegate = self;
    [self.view addSubview:self.webView];
    self.bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView];
    [_bridge setWebViewDelegate:self];
    [self disableBounce];
    
}

- (BOOL)isOpenAppSpecialURLValue:(NSString *)string
{
    if ([string hasPrefix:@"http://"]) {
        return NO;
    } else if ([string hasPrefix:@"https://"]) {
        return NO;
    }
    return YES;
}



#pragma mark - WKWebView WKNavigationDelegate 相关
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    // WKWebView默认拦截scheme 需在下面方法手动打开
    // 打开外部应用 Safari等操作
    
    NSString *_url = navigationAction.request.URL.absoluteString;
    if ([self isOpenAppSpecialURLValue:_url]) { // 对应的scheme
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
    }

    decisionHandler(WKNavigationActionPolicyAllow);
}
// 页面加载完毕时调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
   UIAlertAction *okAction =  [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
   }];
    [okAction setValue:[UIColor colorWithRed:139.0/255.0 green:55.0/255.0 blue:255.0/255.0 alpha:100] forKey:@"titleTextColor"];
    [alertController addAction:(okAction)];
    [self presentViewController:alertController animated:YES completion:nil];
    
}
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
    //    DLOG(@"msg = %@ frmae = %@",message,frame);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }])];
    
    UIAlertAction *okAction =  [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }];
    
    [alertController addAction:(okAction)];
    [self presentViewController:alertController animated:YES completion:nil];
}
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultText;
    }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(alertController.textFields[0].text?:@"");
    }];
    [okAction setValue:[UIColor colorWithRed:139.0/255.0 green:55.0/255.0 blue:255.0/255.0 alpha:100] forKey:@"titleTextColor"];

    
    [alertController addAction:(okAction)];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void)scanCode{
      [ScanCodeMgr start:self];
}

- (BOOL)shouldAutorotate
{
    return false;
}

-(void)evaluateJavaScript:(NSString *)string{
    //设置JS
    NSString *inputValueJS = string;
    //执行JS
    [self.webView evaluateJavaScript:inputValueJS completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        NSLog(@"value: %@ error: %@", response, error);
    }];
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView API_AVAILABLE(macosx(10.11), ios(9.0)){
    [self.webView reload];
}
- (void)disableBounce {
    self.webView.scrollView.bounces = NO;
}


#pragma mark - addObserverKeyboard
/// 键盘将要弹起
- (void)keyBoardShow {
    CGPoint point = self.webView.scrollView.contentOffset;
    self.keyBoardPoint = point;
}
/// 键盘将要隐藏
- (void)keyBoardHidden {
    self.webView.scrollView.contentOffset = self.keyBoardPoint;
}

-(void)onResult:(NSString*)action didReceiveScriptMessage:(NSString *)text{
    NSString *message = [[NSString alloc] initWithFormat:@"{\"action\":\"%@\",\"text\":\"%@\"}", action, text];
       NSLog(@"retey %@",message);
    [self.bridge callHandler:@"onResult" data:message responseCallback:^(id responseData) {
        NSLog(@"ObjC received response: %@", responseData);
    }];
}

#pragma mark - WKScriptMessageHandler
-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSLog(@"body:%@",message.body);
    if ([message.name isEqualToString:@"openWeb"]) {
         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:message.body]];
    }
    // 调用扫码
    if ([message.name isEqualToString:@"scanCode"]) {
        [self scanCode];
    }
    
//    launchComplete
    if ([message.name isEqualToString:@"launchComplete"]) {
        [self closeLauchView];
    }
}
@end

