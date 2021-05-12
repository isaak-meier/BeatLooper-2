//
//  ViewController.m
//  BeatLooper
//
//  Created by Isaak Meier on 4/2/21.
//

#import "HomeViewController.h"

@interface HomeViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *songTableView;

@property AVAudioPlayer *player;

@property (strong, nonatomic) NSArray *songs;

@property (strong, nonatomic) NSArray *content;

@end

@implementation HomeViewController

- (id)initWithCoordinator:(BLPCoordinator *)coordinator {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if ((self = [storyboard instantiateViewControllerWithIdentifier:@"HomeViewController"])) {
        _coordinator = coordinator;
    }
    return self;
}

- (IBAction)addSong:(id)sender {
    if ([self player].playing) {
        [[self player] stop];
    } else {
        [[self player] play];
    }
}

- (void)refreshSongs {
    //
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self loadBundle];
    [self songTableView].dataSource = self;
    [self songTableView].delegate = self;
    [_songTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"SongCell"];
    // setup data
    _model = [[BLPBeatModel alloc] init];
    _songs = [_model getAllSongs];
    [self coordinator];
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


// MARK: UITableView Datasource
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [_songTableView dequeueReusableCellWithIdentifier:@"SongCell"];
    Beat *beat = _songs[indexPath.row];
    cell.textLabel.text = beat.title;
    return cell;
    
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_songs count];
}

// MARK: UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"selected %ld row", (long)indexPath.row);
    Beat *selectedBeat = _songs[indexPath.row];
    NSManagedObjectID *beatID = selectedBeat.objectID;
    [[self coordinator] songTapped:beatID];
    
}


@end
