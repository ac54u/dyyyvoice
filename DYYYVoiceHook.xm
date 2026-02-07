#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

extern "C" void showDYYYVoicePanel();

@interface DYYYVoiceManager : NSObject
@property (nonatomic, assign) BOOL isEnabled;
@property (nonatomic, assign) NSInteger fakeDuration;
@property (nonatomic, strong) NSString *selectedPath;
+ (instancetype)shared;
@end

%hook UIWindow
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) showDYYYVoicePanel();
    %orig;
}
%end

%hook AVAudioRecorder
- (void)stop {
    %orig;
    
    // 1. 检查开关
    Class cls = NSClassFromString(@"DYYYVoiceManager");
    if (!cls) return;
    id manager = [cls performSelector:@selector(shared)];
    if (![[manager valueForKey:@"isEnabled"] boolValue]) return; // 没开功能直接跳过
    
    // 2. 检查路径
    NSString *fakePath = [manager valueForKey:@"selectedPath"];
    if (!fakePath) return;
    
    NSURL *url = self.url;
    if (!url) return;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 3. 替换逻辑 (只处理临时文件)
    if ([url.pathExtension isEqualToString:@"m4a"] || [url.pathExtension isEqualToString:@"wav"] || [url.path containsString:@"tmp"]) {
        // 暴力循环5次，防占用
        for (int i = 0; i < 5; i++) {
            NSError *err = nil;
            if ([fm fileExistsAtPath:url.path]) [fm removeItemAtPath:url.path error:&err];
            if (!err) {
                if ([fm copyItemAtPath:fakePath toPath:url.path error:&err]) {
                    NSLog(@"[DYYY] 替换成功！使用文件: %@", fakePath);
                    break;
                }
            }
            [NSThread sleepForTimeInterval:0.05];
        }
    }
}
%end

// 欺骗时长核心
%hook AWEAudioRecorder
- (NSTimeInterval)recordDuration {
    Class cls = NSClassFromString(@"DYYYVoiceManager");
    if (cls) {
        id manager = [cls performSelector:@selector(shared)];
        // 如果开启了功能，且选了文件
        if ([[manager valueForKey:@"isEnabled"] boolValue] && [manager valueForKey:@"selectedPath"]) {
            // 返回用户在面板里设置的滑块数值！
            NSInteger userSetDuration = [[manager valueForKey:@"fakeDuration"] integerValue];
            if (userSetDuration > 0) return (NSTimeInterval)userSetDuration;
        }
    }
    return %orig;
}

- (NSTimeInterval)currentTime {
    Class cls = NSClassFromString(@"DYYYVoiceManager");
    if (cls) {
        id manager = [cls performSelector:@selector(shared)];
        if ([[manager valueForKey:@"isEnabled"] boolValue] && [manager valueForKey:@"selectedPath"]) {
            NSInteger userSetDuration = [[manager valueForKey:@"fakeDuration"] integerValue];
            if (userSetDuration > 0) return (NSTimeInterval)userSetDuration;
        }
    }
    return %orig;
}
%end