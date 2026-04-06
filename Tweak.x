// ChatGPTCompatTweak
// - Redirect tat ca request tu api.openai.com sang api.groq.com/openai
// - Fix login flow: /v1/me -> /v1/models (Groq compatible)
// - Luu lich su chat vao Documents/ (vinh vien, khong bi iOS xoa)

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#define GROQ_DOMAIN @"https://api.groq.com/openai"
#define OPENAI_DOMAIN @"https://api.openai.com"

@interface CGAPIHelper : NSObject
+ (void)alert:(NSString *)title withMessage:(NSString *)message;
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

// -----------------------------------------------
// 1. Redirect tat ca request openai -> groq
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
// 2. Fix login: /v1/me -> /v1/models
// -----------------------------------------------

%hook CGAPIHelper

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
                NSString *msg = parsed[@"error"][@"message"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    TWEAKAlert(@"Warning", msg);
                    [NSNotificationCenter.defaultCenter
                        postNotificationName:@"LOG-IN FAILURE" object:nil];
                });
                return;
            }
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasLoggedInUser"];
            [[NSUserDefaults standardUserDefaults] setObject:key  forKey:@"apiKey"];
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

// -----------------------------------------------
// 3. Luu lich su chat vao Documents/ (mirror)
// -----------------------------------------------

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
