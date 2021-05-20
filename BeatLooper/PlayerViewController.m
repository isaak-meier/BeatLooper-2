//
//  PlayerViewController.m
//  BeatLooper
//
//  Created by Isaak Meier on 5/6/21.
//

#import "PlayerViewController.h"
#import "BLPBeatModel.h"

@interface PlayerViewController ()

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property BLPBeatModel *model;
@property NSManagedObjectID *songID;
@property AVAudioPlayer *player;

- (void)loadPlayer;

@end

@implementation PlayerViewController

- (id)initWithSongID:(id)songID {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if ((self = [storyboard instantiateViewControllerWithIdentifier:@"PlayerViewController"])) {
        // assign properties
        _model = [[BLPBeatModel alloc] init];
        _songID = songID;

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[[self playButton] imageView] setContentMode:UIViewContentModeScaleAspectFit];
    [self loadPlayer];
}

- (void)loadPlayer {
//    NSString *resourceURL = [[NSBundle mainBundle] pathForResource:@"temp" ofType:@"mp3"];
    //    NSString *mannyURL = @"/Users/isaak/Library/Developer/CoreSimulator/Devices/60B08052-9106-472A-BBD6-FBB004BE872E/data/Containers/Data/Application/007CF272-517B-4DF5-999F-91A3B38B9511/Library/Ok.mp3";

    NSURL *resourceUrl = [[self model] getURLForCachedSong:[self songID]];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL exists = [fileManager fileExistsAtPath:resourceUrl.path];

    if (!exists) {
        NSLog(@"File does not exist at path %@", resourceUrl.path);
    } else {
        NSError *error;
        [self setPlayer:[[AVAudioPlayer alloc] initWithContentsOfURL:resourceUrl error:&error]];
        if (error) {
            NSLog(@"Error creating AVAudioPlayer: %@", error);
        }
    }
 
}

- (IBAction)playOrPauseSong:(id)sender {
    if ([self player].playing) {
        [[self player] stop];
    } else {
        [[self player] play];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
