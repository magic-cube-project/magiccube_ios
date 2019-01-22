#import "ViewController.h"
#import <WebKit/WebKit.h>
#import <AVFoundation/AVFoundation.h>
#import "WebViewJavascriptBridge.h"

@interface ViewController ()<WKUIDelegate,WKScriptMessageHandler,WKNavigationDelegate>

@property (strong, nonatomic)   WKWebView                   *webView;
@property (strong, nonatomic)   NSString                   *url;
@property (strong, nonatomic)   UIProgressView              *progressView;
@property WebViewJavascriptBridge* bridge;
/** 键盘谈起屏幕偏移量 */
@property (nonatomic, assign) CGPoint keyBoardPoint;
@end

@implementation ViewController

- (void)viewDidLoad {
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    [self initWKWebView];
    [self autoLayout];
    UIApplication *app = [UIApplication sharedApplication];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:)name:UIApplicationWillEnterForegroundNotification object:app];
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
{
    [self.bridge callHandler:@"onEnterForeground" data:nil responseCallback:^(id responseData) {
        NSLog(@"ObjC received response: %@", responseData);
    }];
    
    //进入前台时调用此函数
    NSLog(@"进入前台");
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
    

    // 如果控制器里需要监听WKWebView 的`navigationDelegate`方法，就需要添加下面这行。
//

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
    NSLog(@"页面加载完毕");
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
    NSLog(@"键盘弹起");
}
/// 键盘将要隐藏
- (void)keyBoardHidden {
    self.webView.scrollView.contentOffset = self.keyBoardPoint;
    NSLog(@"键盘隐藏");
}

#pragma mark - WKScriptMessageHandler
-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSLog(@"body:%@",message.body);
    if ([message.name isEqualToString:@"openWeb"]) {
         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:message.body]];
    }
}
@end

