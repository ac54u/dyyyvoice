#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

// --- 数据管理器 ---
@interface DYYYVoiceManager : NSObject
@property (nonatomic, strong) NSString *selectedPath;
@property (nonatomic, assign) NSTimeInterval fakeDuration;
@property (nonatomic, strong) AVAudioPlayer *player;
+ (instancetype)shared;
- (NSString *)dirPath;
- (NSArray *)getFiles;
@end

@implementation DYYYVoiceManager
+ (instancetype)shared {
    static DYYYVoiceManager *m;
    static dispatch_once_t o;
    dispatch_once(&o, ^{ m = [DYYYVoiceManager new]; });
    return m;
}
- (NSString *)dirPath {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"DYYY_Voices"];
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    return path;
}
- (NSArray *)getFiles {
    return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self dirPath] error:nil];
}
@end

// --- Cell ---
@interface VoiceCell : UITableViewCell
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UIButton *useBtn;
@property (nonatomic, copy) void (^playBlock)(void);
@property (nonatomic, copy) void (^useBlock)(void);
@end

@implementation VoiceCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor clearColor];
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 220, 20)];
        _titleLabel.font = [UIFont boldSystemFontOfSize:15];
        [self.contentView addSubview:_titleLabel];
        _infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 35, 200, 15)];
        _infoLabel.font = [UIFont systemFontOfSize:11];
        _infoLabel.textColor = [UIColor systemBlueColor];
        [self.contentView addSubview:_infoLabel];
        _playBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _playBtn.frame = CGRectMake(self.contentView.bounds.size.width - 90, 10, 40, 40);
        _playBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [_playBtn setTitle:@"▶️" forState:UIControlStateNormal];
        [_playBtn addTarget:self action:@selector(doPlay) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_playBtn];
        _useBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _useBtn.frame = CGRectMake(self.contentView.bounds.size.width - 45, 10, 40, 40);
        _useBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [_useBtn setTitle:@"🚀" forState:UIControlStateNormal];
        [_useBtn addTarget:self action:@selector(doUse) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_useBtn];
    }
    return self;
}
- (void)doPlay { if(_playBlock) _playBlock(); }
- (void)doUse { if(_useBlock) _useBlock(); }
@end

// --- 主界面 ---
@interface DYYYVoiceView : UIView <UITableViewDelegate, UITableViewDataSource, UIDocumentPickerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *files;
@end

@implementation DYYYVoiceView
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        _files = [NSMutableArray arrayWithArray:[[DYYYVoiceManager shared] getFiles]];
        UIView *box = [[UIView alloc] initWithFrame:CGRectMake(30, 150, frame.size.width-60, 500)];
        box.backgroundColor = [UIColor whiteColor];
        box.layer.cornerRadius = 15;
        box.clipsToBounds = YES;
        [self addSubview:box];
        
        UILabel *head = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, box.frame.size.width, 50)];
        head.text = @"语音包 (全能导入版)";
        head.textAlignment = NSTextAlignmentCenter;
        head.font = [UIFont boldSystemFontOfSize:16];
        head.backgroundColor = [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1];
        [box addSubview:head];
        
        UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
        close.frame = CGRectMake(10, 5, 40, 40);
        [close setTitle:@"✕" forState:UIControlStateNormal];
        [close addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
        [box addSubview:close];
        
        // 注意：这里改成调用 showImportMenu
        UIButton *add = [UIButton buttonWithType:UIButtonTypeSystem];
        add.frame = CGRectMake(box.frame.size.width-50, 5, 40, 40);
        [add setTitle:@"➕" forState:UIControlStateNormal];
        [add addTarget:self action:@selector(showImportMenu) forControlEvents:UIControlEventTouchUpInside];
        [box addSubview:add];
        
        UIButton *fixBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        fixBtn.frame = CGRectMake(0, 50, box.frame.size.width, 40);
        fixBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.1];
        [fixBtn setTitle:@"🔧 点我修复 (30秒+压缩)" forState:UIControlStateNormal];
        [fixBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        fixBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [fixBtn addTarget:self action:@selector(fixAllFiles) forControlEvents:UIControlEventTouchUpInside];
        [box addSubview:fixBtn];
        
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 90, box.frame.size.width, 410)];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = 60;
        [box addSubview:_tableView];
    }
    return self;
}
- (void)close { [self removeFromSuperview]; }

// --- 核心压缩转码逻辑 (30秒+22050Hz) ---
- (void)convertAudio:(NSURL *)srcURL to:(NSURL *)destURL completion:(void(^)(BOOL))handler {
    AVAsset *asset = [AVAsset assetWithURL:srcURL];
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:asset error:nil];
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    if (!track) { handler(NO); return; }
    
    NSDictionary *readerSettings = @{AVFormatIDKey: @(kAudioFormatLinearPCM)};
    AVAssetReaderTrackOutput *output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:readerSettings];
    [reader addOutput:output];
    
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:destURL fileType:AVFileTypeAppleM4A error:nil];
    NSDictionary *writerSettings = @{
        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
        AVNumberOfChannelsKey: @1,
        AVSampleRateKey: @22050, 
        AVEncoderBitRateKey: @32000
    };
    
    AVAssetWriterInput *input = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:writerSettings];
    [writer addInput:input];
    [writer startWriting];
    [reader startReading];
    [writer startSessionAtSourceTime:kCMTimeZero];
    
    dispatch_queue_t queue = dispatch_queue_create("audio.converter", NULL);
    [input requestMediaDataWhenReadyOnQueue:queue usingBlock:^{
        while (input.readyForMoreMediaData) {
            CMSampleBufferRef buffer = [output copyNextSampleBuffer];
            if (buffer) {
                CMTime current = CMSampleBufferGetPresentationTimeStamp(buffer);
                if (CMTimeGetSeconds(current) > 30.0) { // 强行截断
                    CFRelease(buffer);
                    [input markAsFinished];
                    [writer finishWritingWithCompletionHandler:^{ handler(YES); }];
                    [reader cancelReading];
                    return;
                }
                [input appendSampleBuffer:buffer];
                CFRelease(buffer);
            } else {
                [input markAsFinished];
                [writer finishWritingWithCompletionHandler:^{ handler(YES); }];
                return;
            }
        }
    }];
}

- (void)fixAllFiles {
    NSArray *allFiles = [[DYYYVoiceManager shared] getFiles];
    if (allFiles.count == 0) return;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"正在处理" message:@"正在转码压缩..." preferredStyle:UIAlertControllerStyleAlert];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *basePath = [[DYYYVoiceManager shared] dirPath];
        NSFileManager *fm = [NSFileManager defaultManager];
        for (NSString *name in allFiles) {
            if ([name hasSuffix:@"_30s.m4a"]) continue;
            NSString *srcPath = [basePath stringByAppendingPathComponent:name];
            NSString *destPath = [basePath stringByAppendingPathComponent:[[name stringByDeletingPathExtension] stringByAppendingString:@"_30s.m4a"]];
            if ([fm fileExistsAtPath:destPath]) [fm removeItemAtPath:destPath error:nil];
            
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            [self convertAudio:[NSURL fileURLWithPath:srcPath] to:[NSURL fileURLWithPath:destPath] completion:^(BOOL success) {
                if (success) [fm removeItemAtPath:srcPath error:nil];
                dispatch_semaphore_signal(sema);
            }];
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
            _files = [NSMutableArray arrayWithArray:[[DYYYVoiceManager shared] getFiles]];
            [_tableView reloadData];
        });
    });
}

// --- 🔥 新增：导入菜单逻辑 ---
- (void)showImportMenu {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"选择导入方式" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"📂 从文件导入" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self importFromFile];
    }]];
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"🔗 从链接导入" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showLinkImportDialog:@"输入下载链接" isAPI:NO];
    }]];
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"🌐 从接口导入" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showLinkImportDialog:@"输入 API 接口地址" isAPI:YES];
    }]];
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:sheet animated:YES completion:nil];
}

// 1. 文件导入
- (void)importFromFile {
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.audio"] inMode:UIDocumentPickerModeImport];
    picker.delegate = self;
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:picker animated:YES completion:nil];
}
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray <NSURL *>*)urls {
    NSURL *url = urls.firstObject;
    NSString *dest = [[DYYYVoiceManager shared].dirPath stringByAppendingPathComponent:url.lastPathComponent];
    [[NSFileManager defaultManager] copyItemAtURL:url toURL:[NSURL fileURLWithPath:dest] error:nil];
    _files = [NSMutableArray arrayWithArray:[[DYYYVoiceManager shared] getFiles]];
    [_tableView reloadData];
    [self fixAllFiles];
}

// 2 & 3. 链接与接口导入
- (void)showLinkImportDialog:(NSString *)title isAPI:(BOOL)isAPI {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:isAPI ? @"API 需返回文件流或包含 url 的 JSON" : @"请粘贴 http/https 音频链接" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"http://...";
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"下载" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *urlStr = alert.textFields.firstObject.text;
        if (urlStr.length > 0) {
            [self downloadFromURL:urlStr isAPI:isAPI];
        }
    }]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void)downloadFromURL:(NSString *)urlStr isAPI:(BOOL)isAPI {
    NSURL *url = [NSURL URLWithString:urlStr];
    if (!url) return;
    
    UIAlertController *loading = [UIAlertController alertControllerWithTitle:@"下载中..." message:@"正在获取数据" preferredStyle:UIAlertControllerStyleAlert];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:loading animated:YES completion:nil];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [loading dismissViewControllerAnimated:YES completion:nil];
            
            if (error || !data) {
                // 简单报错提示
                UIAlertController *errAlert = [UIAlertController alertControllerWithTitle:@"错误" message:@"下载失败，请检查链接" preferredStyle:UIAlertControllerStyleAlert];
                [errAlert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
                [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:errAlert animated:YES completion:nil];
                return;
            }
            
            // 如果是 API，尝试解析 JSON (简单的容错处理)
            NSData *audioData = data;
            NSString *fileName = response.suggestedFilename ?: @"downloaded_audio.mp3";
            
            if (isAPI) {
                // 简单判断是不是 JSON
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if (json && json[@"url"]) {
                    // 如果 API 返回 {"url": "http..."}，则递归下载
                    [self downloadFromURL:json[@"url"] isAPI:NO]; 
                    return;
                }
                // 如果不是 JSON，假设它直接返回了音频流
            }
            
            // 保存文件
            NSString *tempPath = [[DYYYVoiceManager shared].dirPath stringByAppendingPathComponent:fileName];
            [audioData writeToFile:tempPath atomically:YES];
            
            // 刷新并触发修复
            _files = [NSMutableArray arrayWithArray:[[DYYYVoiceManager shared] getFiles]];
            [_tableView reloadData];
            [self fixAllFiles]; // 下载完自动转码压缩
        });
    }];
    [task resume];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return _files.count; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VoiceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"vc"];
    if (!cell) cell = [[VoiceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"vc"];
    
    NSString *name = _files[indexPath.row];
    NSString *path = [[DYYYVoiceManager shared].dirPath stringByAppendingPathComponent:name];
    cell.titleLabel.text = name;
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:path]];
    NSTimeInterval dur = CMTimeGetSeconds(asset.duration);
    NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    
    if ([name containsString:@"_30s.m4a"]) {
        cell.infoLabel.text = [NSString stringWithFormat:@"✅ 30秒极速版 • %.1fs • %.1f KB", dur, [attr fileSize]/1024.0];
        cell.infoLabel.textColor = [UIColor colorWithRed:0 green:0.6 blue:0 alpha:1];
    } else {
        cell.infoLabel.text = @"❌ 需修复";
        cell.infoLabel.textColor = [UIColor redColor];
    }
    
    BOOL isSel = [[DYYYVoiceManager shared].selectedPath isEqualToString:path];
    [cell.useBtn setTitle:isSel ? @"✅" : @"🚀" forState:UIControlStateNormal];
    
    cell.playBlock = ^{
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        AVAudioPlayer *p = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
        p.volume = 1.0;
        [p prepareToPlay];
        [DYYYVoiceManager shared].player = p;
        [p play];
    };
    cell.useBlock = ^{
        if (isSel) {
            [DYYYVoiceManager shared].selectedPath = nil;
            [DYYYVoiceManager shared].fakeDuration = 0;
        } else {
            [DYYYVoiceManager shared].selectedPath = path;
            [DYYYVoiceManager shared].fakeDuration = dur;
        }
        [_tableView reloadData];
    };
    return cell;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *name = _files[indexPath.row];
        [[NSFileManager defaultManager] removeItemAtPath:[[DYYYVoiceManager shared].dirPath stringByAppendingPathComponent:name] error:nil];
        [_files removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}
@end
void showDYYYVoicePanel() {
    UIWindow *win = [UIApplication sharedApplication].keyWindow;
    DYYYVoiceView *v = [[DYYYVoiceView alloc] initWithFrame:win.bounds];
    [win addSubview:v];
}