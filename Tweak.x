// ChatGPTCompatTweak - Ultimate Bypass Authentication

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface CGAPIHelper : NSObject
+ (void)alert:(NSString *)title withMessage:(NSString *)message;
+ (id)loopErrorBack:(NSString *)errorMsg;
@end

#define GROQ_BASE_URL @"https://api.groq.com/openai"

// -----------------------------------------------
// 1. Tóm Request và sửa Header/URL
// -----------------------------------------------
%hook NSMutableURLRequest

- (void)setURL:(NSURL *)url {
    NSString *s = url.absoluteString;
    if ([s rangeOfString:@"https://api.openai.com"].location != NSNotFound) {
        url = [NSURL URLWithString:[s stringByReplacingOccurrencesOfString:@"https://api.openai.com" withString:GROQ_BASE_URL]];
    }
    %orig(url);
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    if ([field isEqualToString:@"Authorization"]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *realKey = [defaults objectForKey:@"apiKey"];
        
        // Quét các tên biến khả thi trong Settings
        if (!realKey || realKey.length == 0) realKey = [defaults objectForKey:@"api_key_preference"];
        if (!realKey || realKey.length == 0) realKey = [defaults objectForKey:@"API_KEY"];
        
        if (realKey && realKey.length > 0) {
            // Mẹo lừa tiền tố: Xóa 'sk-' nếu bạn lỡ nhập vào cài đặt để đánh lừa app
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
// 2. VÔ HIỆU HÓA CÁC HÀM KIỂM TRA API KEY
// -----------------------------------------------
%hook CGAPIHelper

// Chặn đứng hàm kiểm tra ngầm của ứng dụng
+ (void)checkForAPIKeyValidity {
    // Để trống hàm này. 
    // Ứng dụng gọi hàm này -> Tweak chặn lại -> Không có lỗi mạng nào xảy ra -> App tưởng key đúng.
}

// Chặn hàm Login (phòng trường hợp app ép người dùng qua màn hình Welcome)
+ (void)logInUserwithKey:(NSString *)key {
    // Không thèm gọi API xác minh nữa, ép lưu trạng thái thành công luôn!
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasLoggedInUser"];
    [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"apiKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:@"LOG-IN VALID" object:nil];
    });
}

// -----------------------------------------------
// 3. Sửa câu thông báo lỗi
// -----------------------------------------------
+ (id)loopErrorBack:(NSString *)msg {
    if ([msg rangeOfString:@"OpenAI"].location != NSNotFound) {
        msg = @"Lỗi trả về từ Groq: Hãy chắc chắn bạn điền đúng Model (vd: llama3-8b-8192) và API Key của Groq.";
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