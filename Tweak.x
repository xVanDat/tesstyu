// ChatGPTCompatTweak - Force Groq API (No Login Bypass)

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface CGAPIHelper : NSObject
+ (void)alert:(NSString *)title withMessage:(NSString *)message;
+ (id)loopErrorBack:(NSString *)errorMsg;
@end

// Khai báo cứng Base URL của Groq
#define GROQ_BASE_URL @"https://api.groq.com/openai"

// -----------------------------------------------
// 1. Bắt cóc và tráo đổi URL sang Groq
// -----------------------------------------------
%hook NSMutableURLRequest

- (void)setURL:(NSURL *)url {
    NSString *s = url.absoluteString;
    // Tự động tìm và đổi link OpenAI thành Groq
    if ([s rangeOfString:@"https://api.openai.com"].location != NSNotFound) {
        url = [NSURL URLWithString:[s stringByReplacingOccurrencesOfString:@"https://api.openai.com" withString:GROQ_BASE_URL]];
    }
    %orig(url);
}

%end

// -----------------------------------------------
// 2. Chặn câu thông báo lỗi "ảo" của app gốc
// -----------------------------------------------
%hook CGAPIHelper

+ (id)loopErrorBack:(NSString *)msg {
    // Đổi câu báo lỗi cứng của app gốc thành lỗi bao quát hơn để dễ debug
    if ([msg rangeOfString:@"OpenAI"].location != NSNotFound) {
        msg = @"Lỗi kết nối Groq: Mạng yếu, sai Tên Model, API Key, hoặc iOS quá cũ không hỗ trợ chuẩn SSL/TLS mới.";
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