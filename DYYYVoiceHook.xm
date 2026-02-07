#import <UIKit/UIKit.h>

extern "C" void showVoicePanel();

@interface DYYYVoiceManager : NSObject
@property (nonatomic, strong) NSString *selectedPath;
+ (instancetype)shared;
@end

// 1. 摇一摇显示界面
%hook UIWindow
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
        showVoicePanel();
    }
    %orig;
}
%end

// 2. 录音替换
%hook AWEAudioRecorder
- (void)_didFinishRecordingWithUrl:(NSURL *)url error:(NSError *)error {
    Class cls = NSClassFromString(@"DYYYVoiceManager");
    if (cls) {
        id manager = [cls performSelector:@selector(shared)];
        NSString *myFile = [manager valueForKey:@"selectedPath"];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        if (myFile && [fm fileExistsAtPath:myFile]) {
            if ([fm fileExistsAtPath:url.path]) [fm removeItemAtPath:url.path error:nil];
            [fm copyItemAtPath:myFile toPath:url.path error:nil];
            
            // 震动提示
            UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
            [gen impactOccurred];
        }
    }
    %orig;
}
%end