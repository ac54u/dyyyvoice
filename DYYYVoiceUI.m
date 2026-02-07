#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

// --- 1. 数据管理器 ---
@interface DYYYVoiceManager : NSObject
@property (nonatomic, strong) NSString *selectedPath;
@property (nonatomic, strong) AVAudioPlayer *player;
+ (instancetype)shared;
- (NSString *)dirPath;
- (NSArray *)getFiles;
@end

@implementation DYYYVoiceManager
+ (instancetype)shared {
    static DYYYVoiceManager *m;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ m = [DYYYVoiceManager new]; });
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

// --- 2. 列表行 (Cell) ---
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
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 200, 20)];
        _titleLabel.font = [UIFont boldSystemFontOfSize:16];
        [self.contentView addSubview:_titleLabel];
        
        _infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 35, 200, 15)];
        _infoLabel.font = [UIFont systemFontOfSize:12];
        _infoLabel.textColor = [UIColor colorWithRed:0.1 green:0.7 blue:0.4 alpha:1];
        [self.contentView addSubview:_infoLabel];
        
        _playBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _playBtn.frame = CGRectMake(self.contentView.bounds.size.width - 100, 15, 40, 40);
        _playBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [_playBtn setTitle:@"▶️" forState:UIControlStateNormal];
        [_playBtn addTarget:self action:@selector(doPlay) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_playBtn];
        
        _useBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _useBtn.frame = CGRectMake(self.contentView.bounds.size.width - 50, 15, 40, 40);
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

// --- 3. 主界面 ---
@interface DYYYVoiceView : UIView <UITableViewDelegate, UITableViewDataSource, UIDocumentPickerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *files;
@end

@implementation DYYYVoiceView
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        _files = [NSMutableArray arrayWithArray:[[DYYYVoiceManager shared] getFiles]];
        
        UIView *box = [[UIView alloc] initWithFrame:CGRectMake(20, 100, frame.size.width-40, 500)];
        box.backgroundColor = [UIColor whiteColor];
        box.layer.cornerRadius = 12;
        box.clipsToBounds = YES;
        [self addSubview:box];
        
        UILabel *head = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, box.frame.size.width, 50)];
        head.text = @"语音包列表";
        head.textAlignment = NSTextAlignmentCenter;
        head.font = [UIFont boldSystemFontOfSize:18];
        head.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1];
        [box addSubview:head];
        
        UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
        close.frame = CGRectMake(10, 5, 40, 40);
        [close setTitle:@"✕" forState:UIControlStateNormal];
        [close addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
        [box addSubview:close];
        
        UIButton *add = [UIButton buttonWithType:UIButtonTypeSystem];
        add.frame = CGRectMake(box.frame.size.width-50, 5, 40, 40);
        [add setTitle:@"➕" forState:UIControlStateNormal];
        add.titleLabel.font = [UIFont systemFontOfSize:24];
        [add addTarget:self action:@selector(import) forControlEvents:UIControlEventTouchUpInside];
        [box addSubview:add];
        
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 50, box.frame.size.width, 450)];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = 70;
        [box addSubview:_tableView];
    }
    return self;
}
- (void)close { [self removeFromSuperview]; }
- (void)import {
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
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return _files.count; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VoiceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"vc"];
    if (!cell) cell = [[VoiceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"vc"];
    
    NSString *name = _files[indexPath.row];
    NSString *path = [[DYYYVoiceManager shared].dirPath stringByAppendingPathComponent:name];
    
    cell.titleLabel.text = name;
    NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    cell.infoLabel.text = [NSString stringWithFormat:@"%.1f MB", [attr fileSize]/1024.0/1024.0];
    
    BOOL isSel = [[DYYYVoiceManager shared].selectedPath isEqualToString:path];
    [cell.useBtn setTitle:isSel ? @"✅" : @"🚀" forState:UIControlStateNormal];
    
    cell.playBlock = ^{
        AVAudioPlayer *p = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
        [DYYYVoiceManager shared].player = p;
        [p play];
    };
    cell.useBlock = ^{
        [DYYYVoiceManager shared].selectedPath = path;
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

void showVoicePanel() {
    UIWindow *win = [UIApplication sharedApplication].keyWindow;
    DYYYVoiceView *v = [[DYYYVoiceView alloc] initWithFrame:win.bounds];
    [win addSubview:v];
}