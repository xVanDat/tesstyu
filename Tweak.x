// ChatGPTCompatTweak - Force Groq API & Fix Auth Issues

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface CGAPIHelper : NSObject
+ (void)alert:(NSString *)title withMessage:(NSString *)message;
+ (id)loopErrorBack:(NSString *)errorMsg;
@end

#define GROQ_BASE_URL @"https://api.groq.com/openai"

// -----------------------------------------------
// 1. Ép app nhận diện là "Đã đăng nhập" ngay khi mở lên
// -----------------------------------------------
%hook CGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasLoggedInUser"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return %orig;
}

%end

// -----------------------------------------------
// 2. Tráo URL và Ép Header chứa Key thật
// -----------------------------------------------
%hook NSMutableURLRequest

- (void)setURL:(NSURL *)url {
    NSString *s = url.absoluteString;
    if ([s rangeOfString:@"https://api.openai.com"].location != NSNotFound) {
        url = [NSURL URLWithString:[s stringByReplacingOccurrencesOfString:@"https://api.openai.com" withString:GROQ_BASE_URL]];
    }
    %orig(url);
}

// Can thiệp vào Header Authorization để chắc chắn app truyền đúng API Key
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    if ([field isEqualToString:@"Authorization"]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        // Quét tìm API key từ các tên biến phổ biến nhất mà Settings.bundle hay dùng
        NSString *realKey = [defaults objectForKey:@"apiKey"];
        if (!realKey || realKey.length == 0) realKey = [defaults objectForKey:@"api_key_preference"];
        if (!realKey || realKey.length == 0) realKey = [defaults objectForKey:@"API_KEY"];
        if (!realKey || realKey.length == 0) realKey = [defaults objectForKey:@"apikey"];
        
        if (realKey && realKey.length > 0) {
            // Mẹo lừa app: Nếu user thêm 'sk-' vào đầu key Groq để pass điều kiện, ta sẽ xóa nó đi trước khi gửi đi
            if ([realKey hasPrefix:@"sk-gsk_"]) {
                realKey = [realKey stringByReplacingOccurrencesOfString:@"sk-gsk_" withString:@"gsk_"];
            }
            value = [NSString stringWithFormat:@"Bearer %@", realKey];
        }
    }
    %orig(value, field);
}

%end

// -----------------------------------------------
// 3. Sửa lỗi hiển thị ảo
// -----------------------------------------------
%hook CGAPIHelper

+ (id)loopErrorBack:(NSString *)msg {
    if ([msg rangeOfString:@"OpenAI"].location != NSNotFound) {
        msg = @"Lỗi kết nối: Sai Model, API Key, mạng yếu hoặc iOS quá cũ.";
    }
    return %orig(msg);
}

+ (void)alert:(NSString *)title withMessage:(NSString *)message {
    if ([message rangeOfString:@"OpenAI"].location != NSNotFound) {
        message = [message stringByReplacingOccurrencesOfString:@"OpenAI" withString:@"Groq"];
    }
    %orig(title, message);
}

%end