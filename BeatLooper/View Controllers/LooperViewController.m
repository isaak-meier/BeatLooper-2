//
//  LooperViewController.m
//  BeatLooper
//
//  Created by Isaak Meier on 12/30/21.
//

#import <Foundation/Foundation.h>
#import "LooperViewController.h"
@class BLPBeatModel;

@interface LooperViewController()

@property (weak, nonatomic) IBOutlet UITextField *tempoTextField;
@property (weak, nonatomic) IBOutlet UITextField *startBarTextField;
@property (weak, nonatomic) IBOutlet UITextField *endBarTextField;
@property (weak, nonatomic) IBOutlet UIButton *loopButton;

@property BLPBeatModel *model;
@property NSManagedObjectID *songID;
@property BOOL isLooping;
@property int tempo;
@property int startBar;
@property int endBar;

@end

@implementation LooperViewController

-(id)initWithSongID:(NSManagedObjectID *)songID {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if ((self = [storyboard instantiateViewControllerWithIdentifier:@"LooperViewController"])) {
        _songID = songID;
        _model = [[BLPBeatModel alloc] init];
    }
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    [self setupKeyboardToolbar];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self populateTextFields];
}

- (void)setupKeyboardToolbar {
    UIToolbar* keyboardToolbar = [[UIToolbar alloc] init];
    [keyboardToolbar sizeToFit];
    UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                      target:nil action:nil];
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self action:@selector(doneBarButtonPressed)];
    
    keyboardToolbar.items = @[flexBarButton, doneBarButton];
    self.tempoTextField.inputAccessoryView = keyboardToolbar;
    self.startBarTextField.inputAccessoryView = keyboardToolbar;
    self.endBarTextField.inputAccessoryView = keyboardToolbar;
}

- (void)populateTextFields {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    int lastStartBar = (int)[userDefaults integerForKey:@"startBar"];
    int lastEndBar = (int)[userDefaults integerForKey:@"endBar"];
    
    if (lastStartBar >= 0) {
        NSString *startBarStr = [NSString stringWithFormat:@"%d", lastStartBar];
        [self.startBarTextField setText:startBarStr];
        self.startBar = lastStartBar;
    }
    
    if (lastEndBar >= 0 && lastEndBar > lastStartBar) {
        NSString *endBarStr = [NSString stringWithFormat:@"%d", lastEndBar];
        [self.endBarTextField setText:endBarStr];
        self.endBar = lastEndBar;
    }
    
    Beat *currSong = [self.model getSongForUniqueID:self.songID];
    NSLog(@"Loaded song from id %@ with name %@ and tempo %d", currSong.objectID, currSong.title, currSong.tempo);
    
    int savedTempo = currSong.tempo;
    if (savedTempo > 0 && savedTempo != self.tempo) {
        self.tempo = savedTempo;
        NSString *tempoStr = [NSString stringWithFormat:@"%d", self.tempo];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tempoTextField setText:tempoStr];

        });
    }
}

- (void)doneBarButtonPressed {
    // save all the values
    NSString *tempoStr = [self.tempoTextField text];
    self.tempo = [tempoStr intValue]; // save this to core data
    [self.model saveTempo:self.tempo forSong:self.songID];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *startBarStr = [self.startBarTextField text];
    self.startBar = [startBarStr intValue];
    [userDefaults setInteger:self.startBar forKey:@"startBar"];
    
    NSString *endBarStr = [self.endBarTextField text];
    self.endBar = [endBarStr intValue];
    [userDefaults setInteger:self.endBar forKey:@"endBar"];
    // we don't know who pressed done, so call it for all of them
    [self.tempoTextField resignFirstResponder];
    [self.startBarTextField resignFirstResponder];
    [self.endBarTextField resignFirstResponder];
}

- (IBAction)loopButtonTapped:(id)sender {
    if (!self.isLooping) {
        CMTimeRange timeRangeOfLoop = [BLPBeatModel timeRangeFromBars:self.startBar
                                                                   to:self.endBar
                                                            withTempo:self.tempo];
        if (CMTIMERANGE_IS_INVALID(timeRangeOfLoop)
            || CMTIMERANGE_IS_EMPTY(timeRangeOfLoop)
            || CMTIMERANGE_IS_INDEFINITE(timeRangeOfLoop)
            || self.tempo <= 0) {
            [self handleTimeRangeError];
        } else {
            self.isLooping = YES;
            [self.loopButton setTitle:@"Stop Looping" forState:UIControlStateNormal];
            [self.coordinator dismissLooperViewAndBeginLoopingTimeRange:timeRangeOfLoop];
        }
    } else {
        self.isLooping = NO;
        [self.loopButton setTitle:@"Start Loop!" forState:UIControlStateNormal];
        [self.coordinator dismissLooperViewAndStopLoop];
    }
}

- (void)handleTimeRangeError {
    UIAlertController *alert = [UIAlertController
                                     alertControllerWithTitle:@"Ah ah ah~"
                                     message:@"Hey Buddy, you provided an invalid time range. Make sure to set the tempo, start bar, and end bar, or else I can't be loopin' with much success.\n\n You need to provide the right tempo, 0 as the start bar and 4 as the end bar is a pretty safe default."
                                     preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* okButton = [UIAlertAction
                                    actionWithTitle:@"Haha, Ok"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        //Handle your yes please button action here
                                        return;
                                    }];
    [alert addAction:okButton];
    [self presentViewController:alert animated:YES completion:nil];
}


@end
