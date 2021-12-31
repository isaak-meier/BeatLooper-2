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

//@property BLPBeatModel *model;
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

    }
    return self;
}

-(void)viewDidLoad {
    [self setupKeyboardToolbar];
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

- (void)doneBarButtonPressed {
    // save all the values
    NSString *tempoStr = [self.tempoTextField text];
    self.tempo = [tempoStr intValue]; // save this to core data
    NSString *startBarStr = [self.startBarTextField text];
    self.startBar = [startBarStr intValue];
    NSString *endBarStr = [self.endBarTextField text];
    self.endBar = [endBarStr intValue];
    // we don't know who pressed done, so call it for all of them
    [self.tempoTextField resignFirstResponder];
    [self.startBarTextField resignFirstResponder];
    [self.endBarTextField resignFirstResponder];
}


- (IBAction)loopButtonTapped:(id)sender {
    if (!self.isLooping) {
        CMTimeRange timeRangeOfLoop = [BLPBeatModel timeRangeFromBars:self.startBar to:self.endBar withTempo:self.tempo];
        if (CMTIMERANGE_IS_INVALID(timeRangeOfLoop)
            || CMTIMERANGE_IS_EMPTY(timeRangeOfLoop)
            || CMTIMERANGE_IS_INDEFINITE(timeRangeOfLoop)) {
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
                                     message:@"Hey Buddy, you provided an invalid time range. Make sure to set the tempo, start bar, and end bar, or else I can't be loopin' with much success."
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

- (void)dealloc {
    NSLog(@"Goodnight.");
}

@end
