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
    [_songTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"SongCell"];
    [_songTableView setDelegate:self];
    [_songTableView setDataSource:self];
    
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
    NSArray *newSongs = [_model getAllSongs];
    _songs = [NSMutableArray arrayWithArray:newSongs];
    NSLog(@"%@", _songs);
    [_songTableView reloadData];
}


// MARK: UITableView Datasource
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [_songTableView dequeueReusableCellWithIdentifier:@"SongCell"];
//    cell.textLabel.text = _songs[indexPath.row];
    return cell;
    
    
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //
    return 6;
}


@end
