/*
 * ChatGPTCompatTweak v2.0
 * OpenAI-compatible API support + Việt hoá cho ChatGPT Legacy iOS
 *
 * Hook list:
 *   NSMutableURLRequest  -setURL:              → domain redirect
 *   CGAPIHelper          +logInUserwithKey:    → /v1/me → /v1/models
 *   CGAPIHelper          +alert:withMessage:   → dịch alert text
 *   CGAPIHelper          +saveConversation...  → mirror sang Documents/
 *   CGAPIHelper          +loadConversations    → restore từ Documents/
 *   CGAPIHelper          +deleteConversation.. → xóa cả Documents/
 *   SVProgressHUD        +show*/dismiss*       → dịch HUD text
 *   CGWelcomeController  -viewDidLoad          → thêm Base URL field + Bỏ qua
 *   CGWelcomeController  -textFieldShouldReturn→ xử lý 2 field
 *   UILabel              -setText:             → dịch static label text
 *   UITextField          -setPlaceholder:      → dịch placeholder
 *   UIAlertView          -init...              → dịch title/message
 */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ─────────────────────────────────────────────
// MARK: - Bảng dịch Anh → Việt
// ─────────────────────────────────────────────

static NSDictionary *VNStrings() {
    static NSDictionary *d = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        d = @{
            // Alert titles
            @"Warning"          : @"Cảnh báo",
            @"Error"            : @"Lỗi",
            @"Fatal Error"      : @"Lỗi nghiêm trọng",
            @"Missing Model"    : @"Thiếu mô hình AI",
            @"Good news!"       : @"Có cập nhật mới!",
            @"Connection Error" : @"Lỗi kết nối",
            @"Too short"        : @"Tin nhắn quá ngắn",

            // Alert messages
            @"An error occured when trying to delete this conversation."
                : @"Đã xảy ra lỗi khi xóa cuộc hội thoại này.",
            @"An error occured while trying to delete conversations."
                : @"Đã xảy ra lỗi khi xóa các cuộc hội thoại.",
            @"An unknown error has occured."
                : @"Đã xảy ra lỗi không xác định.",
            @"An error occured when trying to download the user avatar."
                : @"Không thể tải ảnh đại diện.",
            @"Please check your internet connection."
                : @"Vui lòng kiểm tra kết nối internet.",
            @"Please make sure you're **connected to a Wi-Fi network or have cellular data enabled**. ChatGPT cannot connect to OpenAI's services at the moment. **Please try again later.**"
                : @"Không thể kết nối đến API. Vui lòng kiểm tra **Wi-Fi hoặc dữ liệu di động** và thử lại sau.",
            @"Please re-check your model settings. Your model was set back to 'gpt-4o-mini' for this session."
                : @"Mô hình không hợp lệ. Đã đặt lại thành 'gpt-4o-mini' cho phiên này.",
            @"Please re-check your model settings. Your model was set back to 'dall-e-3' for this session."
                : @"Mô hình không hợp lệ. Đã đặt lại thành 'dall-e-3' cho phiên này.",
            @"For the sake of preserving your API Credit, you should ask the AI questions that are longer than three characters."
                : @"Tin nhắn quá ngắn. Hãy nhập nhiều hơn để tiết kiệm API credit.",
            @"You need to start sending messages in order to be able to save your conversations."
                : @"Hãy gửi ít nhất một tin nhắn trước khi lưu hội thoại.",
            @"You don't have any conversations yet, you should chat more and save this conversation!"
                : @"Chưa có hội thoại nào được lưu. Hãy chat và lưu lại nhé!",
            @"Give your conversation a fitting name."
                : @"Đặt tên cho cuộc hội thoại.",
            @"Once you're done, press the 'Done' button."
                : @"Nhấn 'Xong' khi đặt tên xong.",
            @"Your API Key is missing, please double-check the settings pane and make sure you've inputted an OpenAI API Key."
                : @"Thiếu API Key. Vào Settings để nhập key của bạn.",
            @"Your API Key is missing. Please check Settings and make sure you've entered a valid API key."
                : @"Thiếu API Key. Vào Settings để nhập key hợp lệ.",
            @"Could not connect to the API. Please check your Base URL and internet connection."
                : @"Không thể kết nối API. Kiểm tra lại Base URL và internet.",

            // SVProgressHUD
            @"Logging in..."    : @"Đang kết nối...",
            @"Connecting..."    : @"Đang kết nối...",
            @"An error occured. Please retry."
                : @"Lỗi kết nối. Vui lòng thử lại.",
            @"Configure your API key in Settings."
                : @"Vào Settings để cài đặt API key.",

            // Buttons & static labels
            @"Cancel"           : @"Hủy",
            @"Delete"           : @"Xóa",
            @"Done"             : @"Xong",
            @"Save"             : @"Lưu",
            @"Share"            : @"Chia sẻ",
            @"Rename"           : @"Đổi tên",
            @"Chats"            : @"Hội thoại",
            @"NewChat"          : @"Chat mới",
            @"Already have an idea?"     : @"Nhập tin nhắn...",
            @"Delete all conversations"  : @"Xóa tất cả hội thoại",
            @"Rename Conversation"       : @"Đổi tên hội thoại",
            @"Save conversation"         : @"Lưu hội thoại",
            @"Save your conversation now": @"Lưu hội thoại ngay",
            @"Choose Existing"  : @"Chọn từ thư viện ảnh",
            @"Take Photo or Video" : @"Chụp ảnh hoặc quay video",

            // Tweak-added text (sẵn tiếng Việt, để đây cho nhất quán)
            @"Skip — Configure in Settings" : @"Bỏ qua — Cài đặt sau trong Settings",
        };
    });
    return d;
}

static NSString *VN(NSString *s) {
    if (!s || s.length == 0) return s;
    return VNStrings()[s] ?: s;
}


// ─────────────────────────────────────────────
// MARK: - Helpers
// ─────────────────────────────────────────────

static NSString *TWEAKGetDomain() {
    NSString *d = [[NSUserDefaults standardUserDefaults] objectForKey:@"apiDomain"];
    if (d.length > 0) {
        if ([d hasSuffix:@"/"]) d = [d substringToIndex:d.length - 1];
        return d;
    }
    return @"https://api.openai.com";
}

static NSString *TWEAKDocumentsDir() {
    return [NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
}

static const char kBaseURLFieldKey = 0;


// ─────────────────────────────────────────────
// MARK: - 1. Domain redirect
// ─────────────────────────────────────────────

%hook NSMutableURLRequest

- (void)setURL:(NSURL *)url {
    NSString *custom = TWEAKGetDomain();
    if (![custom isEqualToString:@"https://api.openai.com"]) {
        NSString *s = url.absoluteString;
        if ([s rangeOfString:@"https://api.openai.com"].location != NSNotFound) {
            url = [NSURL URLWithString:
                   [s stringByReplacingOccurrencesOfString:@"https://api.openai.com"
                                                withString:custom]];
        }
    }
    %orig(url);
}

%end


// ─────────────────────────────────────────────
// MARK: - 2. CGAPIHelper
// ─────────────────────────────────────────────

%hook CGAPIHelper

+ (void)alert:(NSString *)title withMessage:(NSString *)message {
    %orig(VN(title), VN(message));
}

+ (void)logInUserwithKey:(NSString *)key {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *domain = TWEAKGetDomain();
        NSURL *endpoint  = [NSURL URLWithString:
                            [NSString stringWithFormat:@"%@/v1/models", domain]];
        NSMutableURLRequest *req = [[NSMutableURLRequest alloc] init];
        [req setURL:endpoint];
        [req setHTTPMethod:@"GET"];
        [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [req setValue:[NSString stringWithFormat:@"Bearer %@", key]
   forHTTPHeaderField:@"Authorization"];

        NSURLResponse *resp; NSError *err;
        NSData *data = [NSURLConnection sendSynchronousRequest:req
                                            returningResponse:&resp error:&err];
        if (data) {
            NSDictionary *parsed = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:0 error:&err];
            if (parsed[@"error"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self alert:@"Cảnh báo"
                    withMessage:[NSString stringWithFormat:@"%@",
                                 parsed[@"error"][@"message"]]];
                    [NSNotificationCenter.defaultCenter
                        postNotificationName:@"LOG-IN FAILURE" object:nil];
                });
                return;
            }
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasLoggedInUser"];
            [[NSUserDefaults standardUserDefaults] setObject:key  forKey:@"apiKey"];

            NSString *sd = [[NSUserDefaults standardUserDefaults] objectForKey:@"apiDomain"];
            NSString *pn = @"AI";
            if (!sd || sd.length == 0 ||
                [sd rangeOfString:@"openai.com"].location != NSNotFound)    pn = @"OpenAI";
            else if ([sd rangeOfString:@"groq.com"].location != NSNotFound) pn = @"Groq";
            else if ([sd rangeOfString:@"openrouter.ai"].location != NSNotFound) pn = @"OpenRouter";
            else if ([sd rangeOfString:@"anthropic.com"].location != NSNotFound) pn = @"Anthropic";
            else { NSURL *u = [NSURL URLWithString:sd]; if (u.host) pn = u.host; }

            [[NSUserDefaults standardUserDefaults] setObject:pn  forKey:@"username"];
            [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"email"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [NSNotificationCenter.defaultCenter
                postNotificationName:@"LOG-IN VALID" object:nil];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self alert:@"Lỗi kết nối"
                withMessage:@"Không thể kết nối API. Kiểm tra lại Base URL và internet."];
            });
            [NSNotificationCenter.defaultCenter
                postNotificationName:@"LOG-IN FAILURE" object:nil];
        }
    });
}

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
    NSString *docs    = TWEAKDocumentsDir();
    NSString *tmp     = NSTemporaryDirectory();
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


// ─────────────────────────────────────────────
// MARK: - 3. SVProgressHUD
// ─────────────────────────────────────────────

%hook SVProgressHUD

+ (void)showWithStatus:(NSString *)status maskType:(NSInteger)mask {
    %orig(VN(status), mask);
}
+ (void)showSuccessWithStatus:(NSString *)status {
    %orig(VN(status));
}
+ (void)showErrorWithStatus:(NSString *)status {
    %orig(VN(status));
}

%end


// ─────────────────────────────────────────────
// MARK: - 4. UILabel — static text từ storyboard
// Chỉ dịch string đã biết, còn lại giữ nguyên
// ─────────────────────────────────────────────

%hook UILabel

- (void)setText:(NSString *)text {
    %orig(VN(text));
}

%end


// ─────────────────────────────────────────────
// MARK: - 5. UITextField placeholder
// ─────────────────────────────────────────────

%hook UITextField

- (void)setPlaceholder:(NSString *)placeholder {
    %orig(VN(placeholder));
}

%end


// ─────────────────────────────────────────────
// MARK: - 6. UIAlertView (app dùng vì iOS 6 compat)
// ─────────────────────────────────────────────

%hook UIAlertView

- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
           delegate:(id)delegate
  cancelButtonTitle:(NSString *)cancelTitle
  otherButtonTitles:(NSString *)otherTitle, ... {
    return %orig(VN(title), VN(message), delegate, cancelTitle, nil);
}

%end


// ─────────────────────────────────────────────
// MARK: - 7. CGWelcomeController
// ─────────────────────────────────────────────

%hook CGWelcomeController

- (void)viewDidLoad {
    %orig;

    UITextField *keyField = [self valueForKey:@"KeyInputField"];
    if (!keyField) return;

    CGRect  kf  = keyField.frame;
    CGFloat gap = 8.0f, lh = 16.0f, fh = kf.size.height;

    // Label "Base URL"
    UILabel *lbl = [[UILabel alloc]
                    initWithFrame:CGRectMake(kf.origin.x,
                                            kf.origin.y - fh - gap - lh - gap,
                                            kf.size.width, lh)];
    lbl.text      = @"Base URL  (để trống = OpenAI mặc định)";
    lbl.font      = [UIFont systemFontOfSize:11.0f];
    lbl.textColor = [UIColor grayColor];
    [keyField.superview addSubview:lbl];

    // TextField Base URL
    UITextField *urlField = [[UITextField alloc]
                             initWithFrame:CGRectMake(kf.origin.x,
                                                      kf.origin.y - fh - gap,
                                                      kf.size.width, fh)];
    urlField.placeholder            = @"https://api.openai.com";
    urlField.borderStyle            = keyField.borderStyle;
    urlField.font                   = keyField.font;
    urlField.backgroundColor        = keyField.backgroundColor;
    urlField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    urlField.autocorrectionType     = UITextAutocorrectionTypeNo;
    urlField.keyboardType           = UIKeyboardTypeURL;
    urlField.returnKeyType          = UIReturnKeyNext;
    urlField.delegate               = (id<UITextFieldDelegate>)self;

    NSString *saved = [[NSUserDefaults standardUserDefaults] objectForKey:@"apiDomain"];
    if (saved.length > 0) urlField.text = saved;
    [keyField.superview addSubview:urlField];

    // Nút Bỏ qua
    UIButton *skip = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    skip.frame = CGRectMake(kf.origin.x, kf.origin.y + fh + gap, kf.size.width, 36.0f);
    [skip setTitle:@"Bỏ qua — Cài đặt sau trong Settings" forState:UIControlStateNormal];
    skip.titleLabel.font = [UIFont systemFontOfSize:13.0f];
    [skip addTarget:self action:@selector(tweak_skipLogin)
   forControlEvents:UIControlEventTouchUpInside];
    [keyField.superview addSubview:skip];

    objc_setAssociatedObject(self, &kBaseURLFieldKey, urlField,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    UITextField *urlField = objc_getAssociatedObject(self, &kBaseURLFieldKey);
    if (textField == urlField) {
        [[self valueForKey:@"KeyInputField"] becomeFirstResponder];
        return YES;
    }
    [textField resignFirstResponder];
    UITextField *uf = objc_getAssociatedObject(self, &kBaseURLFieldKey);
    NSString *baseURL = [uf.text stringByTrimmingCharactersInSet:
                         NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (baseURL.length > 0) {
        if ([baseURL hasSuffix:@"/"]) baseURL = [baseURL substringToIndex:baseURL.length - 1];
        [[NSUserDefaults standardUserDefaults] setObject:baseURL forKey:@"apiDomain"];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"apiDomain"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    return %orig(textField);
}

%new
- (void)tweak_skipLogin {
    UITextField *uf = objc_getAssociatedObject(self, &kBaseURLFieldKey);
    NSString *baseURL = [uf.text stringByTrimmingCharactersInSet:
                         NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (baseURL.length > 0) {
        if ([baseURL hasSuffix:@"/"]) baseURL = [baseURL substringToIndex:baseURL.length - 1];
        [[NSUserDefaults standardUserDefaults] setObject:baseURL forKey:@"apiDomain"];
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasLoggedInUser"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstLaunch"];
    [[NSUserDefaults standardUserDefaults] synchronize];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self dismissModalViewControllerAnimated:YES];
#pragma clang diagnostic pop
}

%end
