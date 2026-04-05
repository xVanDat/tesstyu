export THEOS_DEVICE_IP = 192.168.x.x   # ← đổi thành IP máy của mày
export THEOS_DEVICE_PORT = 22

# Nhắm iOS 7.0+ (app gốc hỗ trợ từ iOS 6)
TARGET  := iphone:clang:latest:7.0

# Build cả armv7 (32-bit, iPhone cũ) lẫn arm64 (iPhone 5s+)
ARCHS   = armv7 arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ChatGPTCompatTweak

ChatGPTCompatTweak_FILES        = Tweak.x
ChatGPTCompatTweak_CFLAGS       = -fobjc-arc
ChatGPTCompatTweak_LDFLAGS      =
# Chỉ inject vào đúng app này
ChatGPTCompatTweak_FILTER       = com.apple.UIKit
BUNDLE_FILTER                   = bag.xml.ChatGPT

include $(THEOS)/makefiles/tweak.mk

# make package  → build + tạo .deb
# make install  → build + cài thẳng lên device qua SSH
