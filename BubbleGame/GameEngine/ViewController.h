//
//  ViewController.h
//  GameEngine
//
//  Created by Naomi Leow on 11/2/14.
//
//

#import <UIKit/UIKit.h>
#import "MainEngine.h"
#import "GridTemplateDelegate.h"

@interface ViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, GridTemplateDelegate>

@property (strong, nonatomic) IBOutlet UICollectionView *bubbleGridTemplate;
@property (strong, nonatomic) IBOutlet UIImageView *gameBackground;

@property (strong) NSDictionary *bubbleMappings;
@property CGFloat defaultBubbleRadius;
@property (strong) MainEngine *engine;


- (void)panHandler:(UIGestureRecognizer *)recogniser;
//Tracks the gesture and changes the bubble's fire angle

- (void)tapHandler:(UIGestureRecognizer *)recogniser;
//Fire bubble with angle from tap point

- (void)longPressHandler:(UIGestureRecognizer *)recogniser;
//Note: longpressrecogniser is able to track the gesture till finger is lifted

- (void)loadNextBubble;

- (NSInteger)getNextBubbleType;

@end