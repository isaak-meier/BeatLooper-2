//
//  ViewController.m
//  BeatLooper
//
//  Created by Isaak Meier on 4/2/21.
//

#import "HomeViewController.h"

@interface HomeViewController ()
@property (weak, nonatomic) IBOutlet UITableView *songTableView;

@property AVAudioPlayer *player;

@property NSMutableArray *songs;

@end

@implementation HomeViewController

- (IBAction)addSong:(id)sender {
    if (_player.playing) {
        [_player stop];
    } else {
        [_player play];
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
    [self initAudioPlayer:resourceURL];
}

- (void)initAudioPlayer:(NSString*)resourceURL {
    NSURL *url = [[NSURL alloc] initFileURLWithPath:resourceURL];
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
}

- (void)refreshSongs {
//	_model	
}


// MARK: UITableView Datasource
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    //
    return [[UITableViewCell alloc] init];
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //
    return 6;
}


@end
