#import "ViewController.h"
#import <WebKit/WebKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<WKUIDelegate,WKScriptMessageHandler,WKNavigationDelegate>

@property (strong, nonatomic)   WKWebView                   *webView;
@property (strong, nonatomic)   NSString                   *url;
@property (strong, nonatomic)   UIProgressView              *progressView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    [self initWKWebView];
    
}

//初始化页面
- (void)initWKWebView
{
    //进行配置控制器
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    //实例化对象
    configuration.userContentController = [WKUserContentController new];
    
    WKPreferences *preferences = [WKPreferences new];
    preferences.javaScriptCanOpenWindowsAutomatically = YES;
    configuration.preferences = preferences;
    self.webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:configuration];
    
    if (@available(iOS 11.0, *)) {
        self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        self.webView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        self.webView.scrollView.scrollIndicatorInsets = self.webView.scrollView.contentInset;
    }
    
  
    
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
        NSLog(newAgent);
        // 设置global User-Agent
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:newAgent, @"UserAgent", nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
        [self.webView setCustomUserAgent:newAgent];
    }];
    
    

    self.webView.UIDelegate = self;
    self.webView.navigationDelegate = self;
    [self.view addSubview:self.webView];
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

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    
}

- (BOOL)shouldAutorotate
{
    return true;
}

-(void)evaluateJavaScript:(NSString *)string{
    //设置JS
    NSString *inputValueJS = string;
    //执行JS
    [self.webView evaluateJavaScript:inputValueJS completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        NSLog(@"value: %@ error: %@", response, error);
    }];
}
- (void)disableBounce {
    self.webView.scrollView.bounces = NO;
}
@end

