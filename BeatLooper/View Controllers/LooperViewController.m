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

//@property BLPBeatModel *model;
@property NSManagedObjectID *songID;
@property int tempo;

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
    NSLog(@"Yay");
    self.tempoTextField.delegate = self;
    self.startBarTextField.delegate = self;
    self.endBarTextField.delegate = self;
}

// MARK: UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if (textField == self.tempoTextField) {
        NSString *tempoStr = [textField text];
        [self setTempo:[tempoStr intValue]];
        return YES;
    }
    return YES;
}

- (void)dealloc {
    NSLog(@"Goodnight.");
}

@end
