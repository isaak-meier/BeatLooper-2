//
//  ViewController.m
//  BeatLooper
//
//  Created by Isaak Meier on 4/2/21.
//

#import "HomeViewController.h"

@interface HomeViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *songTableView;
@property (strong, nonatomic) NSArray *songs;
@property (strong, nonatomic) NSArray *content;

@end

@implementation HomeViewController

- (id)initWithCoordinator:(BLPCoordinator *)coordinator {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if ((self = [storyboard instantiateViewControllerWithIdentifier:@"HomeViewController"])) {
        _coordinator = coordinator;
        // setup data
        _model = [[BLPBeatModel alloc] init];
        _songs = [_model getAllSongs];
    }
    return self;
}

- (void)refreshSongsAndReloadData:(BOOL)shouldReloadData {
    NSArray *brandNewSongs = [[self model] getAllSongs];
    [self setSongs:brandNewSongs];
    if (shouldReloadData) {
        [[self songTableView] reloadData];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // DEBUG ONLY: Clear out songs, and then add our test song
    [self.model deleteAllEntities];
    [self addTestSong];

    [self songTableView].dataSource = self;
    [self songTableView].delegate = self;
    [[self songTableView] registerClass:[UITableViewCell class] forCellReuseIdentifier:@"SongCell"];

    [self refreshSongsAndReloadData:YES];
}

- (void)addTestSong {
    NSBundle *main = [NSBundle mainBundle];
    NSString *resourceURL1 = [main pathForResource:@"forgetMe" ofType:@"mp3"];
    NSString *resourceURL2 = [main pathForResource:@"swish" ofType:@"wav"];
    [self.model saveSongWith:@"forgetMe" url:resourceURL1];
    [self.model saveSongWith:@"swish" url:resourceURL2];

}

// MARK: UITableView Datasource
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [_songTableView dequeueReusableCellWithIdentifier:@"SongCell"];
    Beat *beat = self.songs[indexPath.row];
    cell.textLabel.text = beat.title;
    return cell;
    
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.songs count];
}

// MARK: UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Beat *selectedBeat = self.songs[indexPath.row];
    NSManagedObjectID *beatID = selectedBeat.objectID;
    [[self coordinator] songTapped:beatID];
    [self.songTableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Beat *selectedBeat = self.songs[indexPath.row];
        [self.model deleteSong:selectedBeat];
        [self refreshSongsAndReloadData:NO];
        NSArray *indexPaths = @[indexPath];
        [self.songTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
    }
}


@end
