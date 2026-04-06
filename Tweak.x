// ChatGPTCompatTweak
// - Redirect api.openai.com -> api.groq.com/openai
// - Fix login flow: /v1/me -> /v1/models
// - Tu dong bypass Welcome screen neu da co API key trong Settings
// - Luu lich su chat vao Documents/

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

#define GROQ_DOMAIN   @"https://api.groq.com/openai"
#define OPENAI_DOMAIN @"https://api.openai.com"

@interface CGAPIHelper : NSObject
+ (void)alert:(NSString *)title withMessage:(NSString *)message;
@end

@interface SVProgressHUD : NSObject
+ (void)dismiss;
@end

static NSString *TWEAKDocumentsDir() {
    return [NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
}

static void TWEAKAlert(NSString *title, NSString *msg) {
    Class cls = objc_getClass("CGAPIHelper");
    if (cls)
        ((void (*)(Class, SEL, NSString *, NSString *))objc_msgSend)(
            cls, @selector(alert:withMessage:), title, msg);
}

// Kiem tra apiKey trong ca Settings bundle lam UserDefaults
static NSString *TWEAKGetAPIKey() {
    // Sync truoc de dam bao lay gia tri moi nhat tu Settings app
    [[NSUserDefaults standardUserDefaults] synchronize];
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"apiKey"];
}

// -----------------------------------------------
// 1. Redirect openai -> groq
// -----------------------------------------------

%hook NSMutableURLRequest

- (void)setURL:(NSURL *)url {
    NSString *s = url.absoluteString;
    if ([s rangeOfString:OPENAI_DOMAIN].location != NSNotFound) {
        url = [NSURL URLWithString:
               [s stringByReplacingOccurrencesOfString:OPENAI_DOMAIN
                                            withString:GROQ_DOMAIN]];
    }
    %orig(url);
}

%end

// -----------------------------------------------
// 2. CGAPIHelper - login + storage
// -----------------------------------------------

%hook CGAPIHelper

// 2a. Bypass canh bao "API Key is missing" neu key co trong Settings
+ (void)checkForAPIKeyValidity {
    NSString *key = TWEAKGetAPIKey();
    if (!key || key.length == 0) {
        TWEAKAlert(@"Warning", @"API key is missing. Please add your Groq key in Settings.");
        return;
    }
    %orig;
}

// 2b. Login dung /v1/models thay /v1/me
+ (void)logInUserwithKey:(NSString *)key {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *endpoint = [NSURL URLWithString:
                           [NSString stringWithFormat:@"%@/v1/models", GROQ_DOMAIN]];
        NSMutableURLRequest *req = [[NSMutableURLRequest alloc] init];
        [req setURL:endpoint];
        [req setHTTPMethod:@"GET"];
        [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [req setValue:[NSString stringWithFormat:@"Bearer %@", key]
   forHTTPHeaderField:@"Authorization"];

        NSURLResponse *resp;
        NSError *err;
        NSData *data = [NSURLConnection sendSynchronousRequest:req
                                            returningResponse:&resp
                                                        error:&err];
        if (data) {
            NSDictionary *parsed = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:0
                                                                     error:&err];
            if (parsed[@"error"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    TWEAKAlert(@"Warning", parsed[@"error"][@"message"]);
                    [NSNotificationCenter.defaultCenter
                        postNotificationName:@"LOG-IN FAILURE" object:nil];
                });
                return;
            }
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasLoggedInUser"];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstLaunch"];
            [[NSUserDefaults standardUserDefaults] setObject:key    forKey:@"apiKey"];
            [[NSUserDefaults standardUserDefaults] setObject:@"Groq" forKey:@"username"];
            [[NSUserDefaults standardUserDefaults] setObject:@""     forKey:@"email"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [NSNotificationCenter.defaultCenter
                postNotificationName:@"LOG-IN VALID" object:nil];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                TWEAKAlert(@"Connection Error",
                           @"Could not connect to Groq. Check your API key and internet.");
            });
            [NSNotificationCenter.defaultCenter
                postNotificationName:@"LOG-IN FAILURE" object:nil];
        }
    });
}

// 2c. Mirror sang Documents/
+ (void)saveConversationWithArray:(NSMutableArray *)arr
                           withID:(NSString *)uuid
                        withTitle:(NSString *)title {
    %orig;
    NSString *tmp = [NSTemporaryDirectory() stringByAppendingPathComponent:
                     [NSString stringWithFormat:@"%@.json", uuid]];
    NSString *doc = [TWEAKDocumentsDir() stringByAppendingPathComponent:
                     [NSString stringWithFormat:@"%@.json", uuid]];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:tmp]) {
        if ([fm fileExistsAtPath:doc]) [fm removeItemAtPath:doc error:nil];
        [fm copyItemAtPath:tmp toPath:doc error:nil];
    }
}

+ (NSMutableArray *)loadConversations {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *docs = TWEAKDocumentsDir();
    NSString *tmp  = NSTemporaryDirectory();
    for (NSString *f in [fm contentsOfDirectoryAtPath:docs error:nil]) {
        if (![f hasSuffix:@".json"]) continue;
        NSString *t = [tmp  stringByAppendingPathComponent:f];
        NSString *d = [docs stringByAppendingPathComponent:f];
        if (![fm fileExistsAtPath:t]) [fm copyItemAtPath:d toPath:t error:nil];
    }
    return %orig;
}

+ (BOOL)deleteConversationWithUUID:(NSString *)uuid {
    BOOL r = %orig;
    [[NSFileManager defaultManager]
     removeItemAtPath:[TWEAKDocumentsDir() stringByAppendingPathComponent:
                       [NSString stringWithFormat:@"%@.json", uuid]]
                error:nil];
    return r;
}

+ (BOOL)deleteAllConversations {
    BOOL r = %orig;
    NSFileManager *fm = [NSFileManager defaultManager];
    for (NSString *f in [fm contentsOfDirectoryAtPath:TWEAKDocumentsDir() error:nil])
        if ([f.pathExtension isEqualToString:@"json"])
            [fm removeItemAtPath:[TWEAKDocumentsDir()
                                  stringByAppendingPathComponent:f] error:nil];
    return r;
}

%end

// -----------------------------------------------
// 3. CGChatViewController - tu dong bypass Welcome
//    neu apiKey da co trong Settings
// -----------------------------------------------

%hook UIViewController

- (void)viewDidLoad {
    %orig;

    // Chi xu ly CGChatViewController
    if (![NSStringFromClass([self class]) isEqualToString:@"CGChatViewController"])
        return;

    NSString *key = TWEAKGetAPIKey();
    if (!key || key.length == 0)
        return; // Khong co key, de Welcome screen hien binh thuong

    // Co key trong Settings -> danh dau da login, skip Welcome
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud boolForKey:@"firstLaunch"]) {
        [ud setBool:YES forKey:@"firstLaunch"];
        [ud setBool:YES forKey:@"hasLoggedInUser"];
        [ud setObject:@"Groq" forKey:@"username"];
        [ud synchronize];
    }
}

%end
