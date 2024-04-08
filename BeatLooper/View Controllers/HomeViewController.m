//
//  ViewController.m
//  BeatLooper
//
//  Created by Isaak Meier on 4/2/21.
//

#import "HomeViewController.h"

@interface HomeViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *songTableView;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (strong, nonatomic) NSMutableArray *songs;
@property (weak, nonatomic) IBOutlet UIImageView *rainbowMusicBanner;
@property BOOL isAddSongsMode;
@property BOOL rowSelected;
@property NSString *currentlyPlayingSongTitle;

@end

@implementation HomeViewController

- (id)initWithCoordinator:(BLPCoordinator *)coordinator inAddSongsMode:(BOOL)isAddSongsMode {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if ((self = [storyboard instantiateViewControllerWithIdentifier:@"HomeViewController"])) {
        _coordinator = coordinator;
        _model = [[BLPBeatModel alloc] init];
        _isAddSongsMode = isAddSongsMode;
    }
    return self;
}

- (void)refreshSongsAndReloadData:(BOOL)shouldReloadData {
    NSArray *brandNewSongs = [[self model] getAllSongs];
    [self setSongs:[NSMutableArray arrayWithArray:brandNewSongs]];
    if (shouldReloadData) {
        [[self songTableView] reloadData];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self songTableView].dataSource = self;
    [self songTableView].delegate = self;
    [[self songTableView] registerClass:[UITableViewCell class] forCellReuseIdentifier:@"SongCell"];

    if (self.isAddSongsMode) {
        [self.editButton setHidden:YES];
        [self.rainbowMusicBanner setHidden:YES];
    }
    [self refreshSongsAndReloadData:YES];
}

- (IBAction)editButtonTapped:(id)sender {
    if (self.songTableView.isEditing) {
        [self.songTableView setEditing:NO];
        [self.editButton setTitle:@"Edit" forState:UIControlStateNormal];
    } else {
        [self.songTableView setEditing:YES];
        [self.editButton setTitle:@"Done" forState:UIControlStateNormal];
    }
}

// MARK: UITableView Datasource
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView
                 cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [self.songTableView dequeueReusableCellWithIdentifier:@"SongCell"];
    Beat *beat = self.songs[indexPath.row];
    cell.textLabel.text = beat.title;
    if ([self.currentlyPlayingSongTitle isEqualToString:beat.title]) {
        UILabel *nowPlayingView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, cell.frame.size.height)];
        [nowPlayingView setText:@"Now Playing"];
        [nowPlayingView setTextColor:UIColor.grayColor];
        UIView *labelHolder = [[UIView alloc] initWithFrame:nowPlayingView.frame];
        labelHolder.backgroundColor = UIColor.clearColor;
        [labelHolder addSubview:nowPlayingView];
        cell.accessoryView = labelHolder;
    } else {
        cell.accessoryView = nil;
    }
    return cell;
    
}


// MARK: UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isAddSongsMode) {
        [self.coordinator addSongToQueue:self.songs[indexPath.row]];
        return;
    }
    Beat *beat = self.songs[indexPath.row];
    if ([self.currentlyPlayingSongTitle isEqualToString:beat.title]) {
        [self.coordinator openPlayerWithoutSong];
    } else {
        // this range encompasses the song we just selected and every song after it.
        NSRange queueRange = NSMakeRange(indexPath.row, self.songs.count - indexPath.row);
        NSIndexSet *indexes = [[NSIndexSet alloc] initWithIndexesInRange:queueRange];
        NSArray *songsForQueue = [NSArray arrayWithArray:[self.songs objectsAtIndexes:indexes]];
        [[self coordinator] openPlayerWithSongs:songsForQueue];
        self.rowSelected = YES;
    }
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

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if (sourceIndexPath.row != destinationIndexPath.row) {
        Beat *beatToMove = self.songs[sourceIndexPath.row];
        [self.songs removeObjectAtIndex:sourceIndexPath.row];
        [self.songs insertObject:beatToMove atIndex:destinationIndexPath.row];
    }
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.songs count];
}


// MARK: BLPPlayer Delegate
- (void)currentItemDidChangeStatus:(AVPlayerItemStatus)status {
    // do nothing
}

- (void)didUpdateCurrentProgressTo:(double)fractionCompleted {
    // do nothing
}

- (void)playerDidChangeSongTitle:(nonnull NSString *)songTitle {
    // update the correct tableviewcell with the title
    self.currentlyPlayingSongTitle = songTitle;
    [self.songTableView reloadData];
}

- (void)playerDidChangeState:(BLPPlayerState)state {
    // do nothing
}

- (void)requestProgressBarUpdate {
    // do nothing
}

- (void)requestTableViewUpdate {
    // do nothing 
}

- (void)selectedIndexesChanged:(NSUInteger)count { 
    // do nothing
}

@end
