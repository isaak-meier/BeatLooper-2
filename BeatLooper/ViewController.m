//
//  ViewController.m
//  BeatLooper
//
//  Created by Isaak Meier on 4/2/21.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITableView *songTableView;
@property AVAudioPlayer *player;

@end

@implementation ViewController
BOOL isPlaying;

- (IBAction)addSong:(id)sender {
    if (isPlaying) {
        [_player stop];
        isPlaying = false;
    } else {
        [_player play];
        isPlaying = true;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self loadBundle];
}

- (void)loadBundle {
    NSBundle *main = [NSBundle mainBundle];
    NSString *resourceURL = [main pathForResource:@"dunevibes" ofType:@"mp3"];
    [self playAudio:resourceURL];
}

- (void)playAudio:(NSString*)resourceURL {
    NSURL *url = [[NSURL alloc] initFileURLWithPath:resourceURL];
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
}


@end
