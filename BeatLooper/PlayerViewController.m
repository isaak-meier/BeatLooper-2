//
//  PlayerViewController.m
//  BeatLooper
//
//  Created by Isaak Meier on 5/6/21.
//

#import "PlayerViewController.h"

@interface PlayerViewController ()

@property (weak, nonatomic) IBOutlet UIButton *playButton;

@end

@implementation PlayerViewController

- (id)init {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if ((self = [storyboard instantiateViewControllerWithIdentifier:@"PlayerViewController"])) {
        // assign properties
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[[self playButton] imageView] setContentMode:UIViewContentModeScaleAspectFit];
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
