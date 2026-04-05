// ChatGPTCompatTweak - Force Groq API Version
// Bắt buộc ứng dụng chuyển toàn bộ request từ OpenAI sang Groq

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface CGAPIHelper : NSObject
+ (void)alert:(NSString *)title withMessage:(NSString *)message;
@end

// Khai báo cứng Base URL của Groq
#define GROQ_BASE_URL @"https://api.groq.com/openai"

// -----------------------------------------------
// 1. Hook chặn và tráo đổi URL (Tầng Network)
// -----------------------------------------------
%hook NSMutableURLRequest

- (void)setURL:(NSURL *)url {
    NSString *s = url.absoluteString;
    
    // Bắt buộc: Cứ thấy link OpenAI là tự động đổi thành Groq
    if ([s rangeOfString:@"https://api.openai.com"].location != NSNotFound) {
        url = [NSURL URLWithString:[s stringByReplacingOccurrencesOfString:@"https://api.openai.com" withString:GROQ_BASE_URL]];
    }
    
    %orig(url);
}

%end

// -----------------------------------------------
// 2. Hook bypass màn hình đăng nhập (Xác thực Key qua Groq)
// -----------------------------------------------
%hook CGAPIHelper

+ (void)logInUserwithKey:(NSString *)key {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Gắn cứng URL kiểm tra model của Groq
        NSURL *endpoint = [NSURL URLWithString:[NSString stringWithFormat:@"%@/v1/models", GROQ_BASE_URL]];
        
        NSMutableURLRequest *req = [[NSMutableURLRequest alloc] init];
        [req setURL:endpoint];
        [req setHTTPMethod:@"GET"];
        [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [req setValue:[NSString stringWithFormat:@"Bearer %@", key] forHTTPHeaderField:@"Authorization"];

        NSURLResponse *resp;
        NSError *err;
        NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
        
        if (data) {
            NSDictionary *parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
            
            // Xử lý nếu Key Groq sai hoặc bị lỗi
            if (parsed[@"error"]) {
                NSString *msg = parsed[@"error"][@"message"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [%c(CGAPIHelper) alert:@"Warning" withMessage:msg];
                    [NSNotificationCenter.defaultCenter postNotificationName:@"LOG-IN FAILURE" object:nil];
                });
                return;
            }
            
            // Đăng nhập thành công, lưu thông tin
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasLoggedInUser"];
            [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"apiKey"];
            [[NSUserDefaults standardUserDefaults] setObject:@"Groq" forKey:@"username"]; // Đổi tên hiển thị thành Groq cho ngầu
            [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"email"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSNotificationCenter.defaultCenter postNotificationName:@"LOG-IN VALID" object:nil];
            });
            
        } else {
            // Lỗi không có mạng
            dispatch_async(dispatch_get_main_queue(), ^{
                [%c(CGAPIHelper) alert:@"Connection Error" withMessage:@"Could not connect to Groq API. Please check your internet connection."];
                [NSNotificationCenter.defaultCenter postNotificationName:@"LOG-IN FAILURE" object:nil];
            });
        }
    });
}

%end