//
//  BLPCoordinator.m
//  BeatLooper
//
//  Created by Isaak Meier on 4/4/21.
//

#import "BLPCoordinator.h"

@interface BLPCoordinator ()
@property UIWindow *window;
@property UINavigationController *navigationController;
@property PlayerViewController *playerController;
@property LooperViewController *looperController;
@property HomeViewController *homeController;

// override songID setter so if we change songs we reload the player
@end

@implementation BLPCoordinator


// MARK: Initializer
- (instancetype)initWithWindow:(UIWindow *)window {
    if (self = [super init]) {
        _window = window;
        _navigationController = [[UINavigationController alloc] init];
        [_window setRootViewController:_navigationController];
    }
    return self;
}

// MARK: Methods
- (void)start {
    // Initialize homeViewController from storyboard
    HomeViewController *homeViewController = [[HomeViewController alloc] initWithCoordinator:self inAddSongsMode:NO];
    [self.navigationController pushViewController:homeViewController animated:NO];
    [[self window] makeKeyAndVisible];
    [self checkForFirstTimeUserOrUpdate];
    [homeViewController refreshSongsAndReloadData:YES];
    self.homeController = homeViewController;
}

- (void)checkForFirstTimeUserOrUpdate {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL isFirstTime = ![userDefaults boolForKey:@"firstTime?"];
//    BOOL isFirstTime = YES;
//    BOOL shouldSetUpSampleSongs = ![userDefaults boolForKey:@"addSampleSongs"];
    BOOL shouldSetUpSampleSongs = YES;
    BOOL applicationDidUpdate = [self didSongDirectoryPathChange];

    if (isFirstTime) {
        [self presentOnboardingAlert];
    }
    if (shouldSetUpSampleSongs) {
        [self setupSampleSongs];
        [userDefaults setBool:YES forKey:@"addSampleSongs"];
    }
    if (applicationDidUpdate) {
        // change paths
        NSLog(@"Need to update all the damn paths");
        [[BLPBeatModel new] updatePathsOfAllEntities];
    }
}

- (void)presentOnboardingAlert {
    UIAlertController *alert = [UIAlertController
                                     alertControllerWithTitle:@"Hello There"
                                     message:@"Congrats on downloading this app. I hope you're having a wonderful day. To add songs, you need to open the file (mp3 or wav only) in this app, from the share sheet. For example, from Files, select the share button and select Beat Looper in the list of apps. In Google Drive, select 'Open In', and then select Beat Looper in the list of apps. Basically you need to tap on Beat Looper from a different app that's holding the file to import it. \n I've added some sample beats for you, try looping forgetMe or swish! (prod. credit No Gravity)\n Ok, that's all from me. Take it easy and enjoy."
                                     preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* okButton = [UIAlertAction actionWithTitle:@"Got it."
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstTime?"];
        return;
    }];
    UIAlertAction* notOkButton = [UIAlertAction actionWithTitle:@"Maybe show me that one more time next time."
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * action) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"firstTime?"];
        return;
    }];
    [alert addAction:okButton];
    [alert addAction:notOkButton];
    [self.navigationController presentViewController:alert animated:YES completion:nil];
}

- (void)setupSampleSongs {
    BLPBeatModel *model = [[BLPBeatModel alloc] init];
    [model deleteAllEntities]; // clear out
    
    NSBundle *main = [NSBundle mainBundle];
    NSArray *audioExtensions = @[@"mp3", @"wav", @"m4a", @"aac"];
    
    for (NSString *extension in audioExtensions) {
        NSArray *audioFiles = [main pathsForResourcesOfType:extension inDirectory:nil];
        for (NSString *audioPath in audioFiles) {
            [model saveSongFromURL:[NSURL fileURLWithPath:audioPath]];
        }
    }
    
    // can update tempo here if you want
    // [model saveTempo:120 forSong:song.objectID];
}

- (BOOL)didSongDirectoryPathChange {
    NSArray<Beat *> *songs = [[BLPBeatModel new] getAllSongs];
    if (songs.count != 0) {
        NSString *path = songs[0].fileUrl;
        NSFileManager *defaultManager = [NSFileManager defaultManager];
        if ([defaultManager fileExistsAtPath:path]) {
            NSLog(@"File Exists at Path");
            return NO;
        } else {
            NSLog(@"We Updated... nothing exists at Path");
            return YES;
        }
    }
    return NO;
}

- (void)songAdded {
    [self.navigationController popToRootViewControllerAnimated:YES];
    HomeViewController *vc = (HomeViewController *)[_navigationController visibleViewController];
    [vc refreshSongsAndReloadData:YES];
}

- (void)failedToAddSong {
    [self.navigationController popToRootViewControllerAnimated:YES];
    UIAlertController *alert = [UIAlertController
                                     alertControllerWithTitle:@"Error Adding Song"
                                     message:@"For some reason, we couldn't add this song. Please try again...?"
                                     preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* okButton = [UIAlertAction
                                    actionWithTitle:@"Haha, Ok"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        //Handle your yes please button action here
                                        return;
                                    }];
    [alert addAction:okButton];
    [self.navigationController presentViewController:alert animated:YES completion:nil];
}

- (void)showAddSongsView {
    HomeViewController *addSongsView = [[HomeViewController alloc] initWithCoordinator:self inAddSongsMode:YES];
    addSongsView.modalPresentationStyle = UIModalPresentationPageSheet;
    [self.navigationController presentViewController:addSongsView animated:YES completion:nil];
}

- (void)addSongToQueue:(Beat *)song {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self.playerController addSongToQueue:song];
}

- (void)openPlayerWithSongs:(NSArray *)songsForQueue {
    if (!self.playerController) {
        PlayerViewController *playerViewController = [[PlayerViewController alloc]
                                                      initWithCoordinator:self];

        NSArray<id <BLPPlayerDelegate>> *delegates = @[playerViewController, self.homeController];
        BLPPlayer *player = [[BLPPlayer alloc] initWithDelegates:delegates
                                                        andSongs:songsForQueue];
        [playerViewController setup:player];
        self.playerController = playerViewController;
    } else if (songsForQueue.count != 0) {
        Beat *songTapped = songsForQueue[0];
        [self.playerController changeCurrentSongTo:songTapped];
    }
    [self openPlayerWithoutSong];
}

- (void)openPlayerWithoutSong {
    [[self navigationController] pushViewController:self.playerController animated:YES];
}

- (void)openLooperViewForSong:(Beat *)song isLooping:(BOOL)isLooping {
    if (!self.looperController || self.looperController.song.objectID != song.objectID) {
        if (song) {
            LooperViewController *looperController = [[LooperViewController alloc] initWithSong:song isLooping:isLooping];
            looperController.modalPresentationStyle = UIModalPresentationPageSheet;
            looperController.coordinator = self;
            self.looperController = looperController; // retain a reference so the user can stop the loop
        } else {
            NSLog(@"cound't find song by name");
        }

    }
    [self.navigationController presentViewController:self.looperController animated:YES completion:nil];
}

- (void)dismissLooperViewAndBeginLoopingTimeRange:(CMTimeRange)timeRange {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self.playerController startLoopWithTimeRange:timeRange];
}

- (void)dismissLooperViewAndStopLoop {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self.playerController stopLooping];
}

// if the song changes, we need to clear the looper view.
- (void)clearLooperView {
    if (self.looperController) {
        self.looperController = nil;
    }
}

- (void)playerViewControllerRequestsDeath {
    // as you wish
    self.playerController = nil;
}

@end
