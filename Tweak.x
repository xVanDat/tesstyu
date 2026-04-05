// ChatGPTCompatTweak v2.0
// OpenAI-compatible API + Viet hoa cho ChatGPT Legacy iOS

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

// -----------------------------------------------
// Interface declarations
// (Theos chi forward-declare, phai khai bao day du)
// -----------------------------------------------

@interface CGAPIHelper : NSObject
+ (void)alert:(NSString *)title withMessage:(NSString *)message;
+ (void)checkForAPIKeyValidity;
+ (void)checkForAppUpdate;
@end

@interface CGWelcomeController : UIViewController <UITextFieldDelegate>
@property (nonatomic, assign) bool authenticated;
- (void)dismissModalViewControllerAnimated:(BOOL)animated;
@end

@interface SVProgressHUD : NSObject
+ (void)showWithStatus:(NSString *)status maskType:(NSInteger)mask;
+ (void)showSuccessWithStatus:(NSString *)status;
+ (void)showErrorWithStatus:(NSString *)status;
+ (void)dismiss;
@end

// -----------------------------------------------
// Translation table
// -----------------------------------------------

static NSDictionary *VNStrings() {
    static NSDictionary *d = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        d = @{
            @"Warning"          : @"C\u1ea3nh b\u00e1o",
            @"Error"            : @"L\u1ed7i",
            @"Fatal Error"      : @"L\u1ed7i nghi\u00eam tr\u1ecdng",
            @"Missing Model"    : @"Thi\u1ebfu m\u00f4 h\u00ecnh AI",
            @"Good news!"       : @"C\u00f3 c\u1eadp nh\u1eadt m\u1edbi!",
            @"Connection Error" : @"L\u1ed7i k\u1ebft n\u1ed1i",
            @"Too short"        : @"Tin nh\u1eafn qu\u00e1 ng\u1eafn",

            @"An error occured when trying to delete this conversation."
                : @"\u0110\u00e3 x\u1ea3y ra l\u1ed7i khi x\u00f3a cu\u1ed9c h\u1ed9i tho\u1ea1i n\u00e0y.",
            @"An error occured while trying to delete conversations."
                : @"\u0110\u00e3 x\u1ea3y ra l\u1ed7i khi x\u00f3a c\u00e1c cu\u1ed9c h\u1ed9i tho\u1ea1i.",
            @"An unknown error has occured."
                : @"\u0110\u00e3 x\u1ea3y ra l\u1ed7i kh\u00f4ng x\u00e1c \u0111\u1ecbnh.",
            @"Please check your internet connection."
                : @"Vui l\u00f2ng ki\u1ec3m tra k\u1ebft n\u1ed1i internet.",
            @"Please make sure you're **connected to a Wi-Fi network or have cellular data enabled**. ChatGPT cannot connect to OpenAI's services at the moment. **Please try again later.**"
                : @"Kh\u00f4ng th\u1ec3 k\u1ebft n\u1ed1i API. Ki\u1ec3m tra **Wi-Fi ho\u1eb7c d\u1eef li\u1ec7u di \u0111\u1ed9ng** v\u00e0 th\u1eed l\u1ea1i sau.",
            @"Please re-check your model settings. Your model was set back to 'gpt-4o-mini' for this session."
                : @"M\u00f4 h\u00ecnh kh\u00f4ng h\u1ee3p l\u1ec7. \u0110\u00e3 \u0111\u1eb7t l\u1ea1i th\u00e0nh 'gpt-4o-mini'.",
            @"Please re-check your model settings. Your model was set back to 'dall-e-3' for this session."
                : @"M\u00f4 h\u00ecnh kh\u00f4ng h\u1ee3p l\u1ec7. \u0110\u00e3 \u0111\u1eb7t l\u1ea1i th\u00e0nh 'dall-e-3'.",
            @"For the sake of preserving your API Credit, you should ask the AI questions that are longer than three characters."
                : @"Tin nh\u1eafn qu\u00e1 ng\u1eafn. H\u00e3y nh\u1eadp nhi\u1ec1u h\u01a1n \u0111\u1ec3 ti\u1ebft ki\u1ec7m API credit.",
            @"You need to start sending messages in order to be able to save your conversations."
                : @"H\u00e3y g\u1eedi \u00edt nh\u1ea5t m\u1ed9t tin nh\u1eafn tr\u01b0\u1edbc khi l\u01b0u h\u1ed9i tho\u1ea1i.",
            @"You don't have any conversations yet, you should chat more and save this conversation!"
                : @"Ch\u01b0a c\u00f3 h\u1ed9i tho\u1ea1i n\u00e0o \u0111\u01b0\u1ee3c l\u01b0u. H\u00e3y chat v\u00e0 l\u01b0u l\u1ea1i nh\u00e9!",
            @"Give your conversation a fitting name."
                : @"\u0110\u1eb7t t\u00ean cho cu\u1ed9c h\u1ed9i tho\u1ea1i.",
            @"Once you're done, press the 'Done' button."
                : @"Nh\u1ea5n 'Xong' khi \u0111\u1eb7t t\u00ean xong.",
            @"Your API Key is missing, please double-check the settings pane and make sure you've inputted an OpenAI API Key."
                : @"Thi\u1ebfu API Key. V\u00e0o Settings \u0111\u1ec3 nh\u1eadp key c\u1ee7a b\u1ea1n.",
            @"Your API Key is missing. Please check Settings and make sure you've entered a valid API key."
                : @"Thi\u1ebfu API Key. V\u00e0o Settings \u0111\u1ec3 nh\u1eadp key h\u1ee3p l\u1ec7.",
            @"Could not connect to the API. Please check your Base URL and internet connection."
                : @"Kh\u00f4ng th\u1ec3 k\u1ebft n\u1ed1i API. Ki\u1ec3m tra l\u1ea1i Base URL v\u00e0 internet.",

            @"Logging in..."    : @"\u0110ang k\u1ebft n\u1ed1i...",
            @"Connecting..."    : @"\u0110ang k\u1ebft n\u1ed1i...",
            @"An error occured. Please retry."
                : @"L\u1ed7i k\u1ebft n\u1ed1i. Vui l\u00f2ng th\u1eed l\u1ea1i.",
            @"Configure your API key in Settings."
                : @"V\u00e0o Settings \u0111\u1ec3 c\u00e0i \u0111\u1eb7t API key.",

            @"Cancel"                    : @"H\u1ee7y",
            @"Delete"                    : @"X\u00f3a",
            @"Done"                      : @"Xong",
            @"Save"                      : @"L\u01b0u",
            @"Share"                     : @"Chia s\u1ebb",
            @"Rename"                    : @"\u0110\u1ed5i t\u00ean",
            @"Chats"                     : @"H\u1ed9i tho\u1ea1i",
            @"NewChat"                   : @"Chat m\u1edbi",
            @"Already have an idea?"     : @"Nh\u1eadp tin nh\u1eafn...",
            @"Delete all conversations"  : @"X\u00f3a t\u1ea5t c\u1ea3 h\u1ed9i tho\u1ea1i",
            @"Rename Conversation"       : @"\u0110\u1ed5i t\u00ean h\u1ed9i tho\u1ea1i",
            @"Save conversation"         : @"L\u01b0u h\u1ed9i tho\u1ea1i",
            @"Save your conversation now": @"L\u01b0u h\u1ed9i tho\u1ea1i ngay",
            @"Choose Existing"           : @"Ch\u1ecdn t\u1eeb th\u01b0 vi\u1ec7n \u1ea3nh",
            @"Take Photo or Video"       : @"Ch\u1ee5p \u1ea3nh ho\u1eb7c quay video",
        };
    });
    return d;
}

static NSString *VN(NSString *s) {
    if (!s || s.length == 0) return s;
    return VNStrings()[s] ?: s;
}


// -----------------------------------------------
// Runtime alert helper
// Dung objc_getClass thay vi [CGAPIHelper ...] truc tiep
// vi linker khong the resolve app-internal class luc build time
// -----------------------------------------------

static void TWEAKAlert(NSString *title, NSString *msg) {
    Class cls = objc_getClass("CGAPIHelper");
    if (cls) {
        ((void (*)(Class, SEL, NSString *, NSString *))objc_msgSend)(
            cls, @selector(alert:withMessage:), title, msg);
    }
}

// -----------------------------------------------
// Helpers
// -----------------------------------------------

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


// -----------------------------------------------
// 1. Domain redirect
// -----------------------------------------------

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


// -----------------------------------------------
// 2. CGAPIHelper
// -----------------------------------------------

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
                    TWEAKAlert(@"C\u1ea3nh b\u00e1o", msg);
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
                [sd rangeOfString:@"openai.com"].location != NSNotFound)
                pn = @"OpenAI";
            else if ([sd rangeOfString:@"groq.com"].location != NSNotFound)
                pn = @"Groq";
            else if ([sd rangeOfString:@"openrouter.ai"].location != NSNotFound)
                pn = @"OpenRouter";
            else if ([sd rangeOfString:@"anthropic.com"].location != NSNotFound)
                pn = @"Anthropic";
            else {
                NSURL *u = [NSURL URLWithString:sd];
                if (u.host) pn = u.host;
            }

            [[NSUserDefaults standardUserDefaults] setObject:pn  forKey:@"username"];
            [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"email"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [NSNotificationCenter.defaultCenter
                postNotificationName:@"LOG-IN VALID" object:nil];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                TWEAKAlert(@"L\u1ed7i k\u1ebft n\u1ed1i", @"Kh\u00f4ng th\u1ec3 k\u1ebft n\u1ed1i API. Ki\u1ec3m tra l\u1ea1i Base URL v\u00e0 internet.");
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


// -----------------------------------------------
// 3. SVProgressHUD
// -----------------------------------------------

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


// -----------------------------------------------
// 4. UILabel
// -----------------------------------------------

%hook UILabel

- (void)setText:(NSString *)text {
    %orig(VN(text));
}

%end


// -----------------------------------------------
// 5. UITextField placeholder
// -----------------------------------------------

%hook UITextField

- (void)setPlaceholder:(NSString *)placeholder {
    %orig(VN(placeholder));
}

%end


// -----------------------------------------------
// 6. UIAlertView
// -----------------------------------------------

%hook UIAlertView

- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
           delegate:(id)delegate
  cancelButtonTitle:(NSString *)cancelTitle
  otherButtonTitles:(NSString *)otherTitle, ... {
    return %orig(VN(title), VN(message), delegate, cancelTitle, nil);
}

%end


// -----------------------------------------------
// 7. CGWelcomeController
// -----------------------------------------------

%hook CGWelcomeController

- (void)viewDidLoad {
    %orig;

    UITextField *keyField = [self valueForKey:@"KeyInputField"];
    if (!keyField) return;

    CGRect  kf  = keyField.frame;
    CGFloat gap = 8.0f;
    CGFloat lh  = 16.0f;
    CGFloat fh  = kf.size.height;

    UILabel *lbl = [[UILabel alloc]
                    initWithFrame:CGRectMake(kf.origin.x,
                                            kf.origin.y - fh - gap - lh - gap,
                                            kf.size.width, lh)];
    lbl.text      = @"Base URL (d\u1ec3 tr\u1ed1ng = OpenAI m\u1eb7c \u0111\u1ecbnh)";
    lbl.font      = [UIFont systemFontOfSize:11.0f];
    lbl.textColor = [UIColor grayColor];
    [keyField.superview addSubview:lbl];

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

    UIButton *skip = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    skip.frame = CGRectMake(kf.origin.x, kf.origin.y + fh + gap, kf.size.width, 36.0f);
    [skip setTitle:@"B\u1ecf qua \u2014 C\u00e0i \u0111\u1eb7t sau trong Settings"
          forState:UIControlStateNormal];
    skip.titleLabel.font = [UIFont systemFontOfSize:13.0f];
    [skip addTarget:self
             action:@selector(tweak_skipLogin)
   forControlEvents:UIControlEventTouchUpInside];
    [keyField.superview addSubview:skip];

    objc_setAssociatedObject(self, &kBaseURLFieldKey, urlField,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    UITextField *urlField = objc_getAssociatedObject(self, &kBaseURLFieldKey);
    if (textField == urlField) {
        UITextField *kf = [self valueForKey:@"KeyInputField"];
        [kf becomeFirstResponder];
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
    [self dismissModalViewControllerAnimated:YES];
}

%end
