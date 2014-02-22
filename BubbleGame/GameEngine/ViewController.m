//
//  ViewController.m
//  GameEngine
//
//  Created by Naomi Leow on 11/2/14.
//
//

#import "ViewController.h"
#import "BubbleView.h"
#import "BubbleGridLayout.h"
#import "BubbleModel.h"
#import "Constants.h"

#define NUM_OF_CELLS_IN_ROW 12
#define BUBBLE_LOADER_BUFFER 5
#define CANNON_SIDE_BUFFER 10
#define CANNON_HEIGHT 150
#define CANNON_ANIMATION_DURATION 0.5

@implementation ViewController{
    NSMutableArray *cannonAnimation;
    UIImageView *cannon;
    TaggedObject *taggedCannonBubble;
    CGPoint cannonDefaultCenter;
}

@synthesize gameBackground;
@synthesize defaultBubbleRadius;
@synthesize bubbleMappings;
@synthesize engine;
@synthesize bubbleGridTemplate;
@synthesize bubbleLoader;

- (void)viewDidLoad{
    [super viewDidLoad];
    [self loadBackground];
    [self initialiseBubbleGrid];
    [self loadDefaultBubbles]; //for testing
    [self loadEngine];
    [self addGestureRecognisers];
    [self loadCannon];
    [self loadBubbleLoader];
    [self loadNextBubble];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

- (void)loadBubbleLoader{
    CGFloat height = self.defaultBubbleRadius * 2 + BUBBLE_LOADER_BUFFER;
    CGFloat width = self.defaultBubbleRadius * 2 * BUBBLE_QUEUE_SIZE + BUBBLE_LOADER_BUFFER;
    CGFloat xPos = self.gameBackground.center.x + CANNON_HEIGHT + self.defaultBubbleRadius * 2;
    CGFloat yPos = self.gameBackground.frame.size.height - height;
    CGRect loaderFrame = CGRectMake(xPos, yPos, width, height);
    bubbleLoader = [[BubbleLoader alloc] initWithFrame:loaderFrame andTypeMapping:bubbleMappings andBubbleRadius:self.defaultBubbleRadius];
    [self.gameBackground addSubview:[bubbleLoader mainFrame]];
}

- (void)loadCannon{
    [self loadCannonImages];
    [self loadCannonBody];
    [self setUpCannonAnimation];
    [self loadCannonBase];
}

- (void)loadCannonBody{
    CGFloat width = self.defaultBubbleRadius * 2 + CANNON_SIDE_BUFFER * 2;
    CGFloat xPos = self.gameBackground.center.x - width / 2;
    CGFloat yPos = self.gameBackground.frame.size.height - CANNON_HEIGHT;
    CGRect baseFrame = CGRectMake(xPos, yPos, width, CANNON_HEIGHT);
    cannon = [[UIImageView alloc] initWithFrame:baseFrame];
    [cannon setImage:[cannonAnimation objectAtIndex:0]];
    cannonDefaultCenter = cannon.center;
    [self.gameBackground addSubview:cannon];
}

- (void)setUpCannonAnimation{
    [cannon setAnimationImages:cannonAnimation];
    [cannon setAnimationRepeatCount:1];
    [cannon setAnimationDuration:CANNON_ANIMATION_DURATION];
}

- (void)loadCannonImages{
    if(!cannonAnimation){
        cannonAnimation = [[NSMutableArray alloc] init];
        UIImage *cannonImage = [UIImage imageNamed:@"cannon"];
        CGFloat imageWidth = cannonImage.size.width;
        CGFloat imageHeight = cannonImage.size.height;
        NSInteger spritesRow = 2;
        NSInteger spritesCol = 6;
        for(NSInteger i = 0; i < spritesRow; i++){
            CGFloat xPos = 0;
            CGFloat yPos = i * imageHeight / spritesRow;
            for(NSInteger j  = 0; j < spritesCol ; j++){
                CGImageRef imageRef = CGImageCreateWithImageInRect(cannonImage.CGImage, CGRectMake(xPos, yPos, imageWidth / spritesCol, imageHeight / spritesRow));
                [cannonAnimation addObject:[UIImage imageWithCGImage:imageRef]];
                xPos += imageWidth / spritesCol;
            }
        }
    }
}

- (void)loadCannonBase{
    CGFloat width = self.defaultBubbleRadius * 2 + CANNON_SIDE_BUFFER * 2;
    CGFloat height = self.defaultBubbleRadius;
    CGFloat xPos = self.gameBackground.center.x - width / 2;
    CGFloat yPos = self.gameBackground.frame.size.height - height;
    CGRect baseFrame = CGRectMake(xPos, yPos, width, height);
    UIImageView *cannonBase = [[UIImageView alloc] initWithFrame:baseFrame];
    [cannonBase setImage:[UIImage imageNamed:@"cannon-base"]];
    [self.gameBackground addSubview:cannonBase];
}

- (void)loadEngine{
    if(!engine){
        engine = [[MainEngine alloc] init];
        [engine setFrameHeight:gameBackground.frame.size.height];
        [engine setFrameWidth:gameBackground.frame.size.width];
        [engine setGridTemplateDelegate:self];
    }
}

- (void)loadBackground{
    self.gameBackground.contentMode = UIViewContentModeScaleAspectFit;
    self.gameBackground.clipsToBounds = YES;
    self.gameBackground.userInteractionEnabled = YES;
    UIImage *background = [UIImage imageNamed:@"background"];
    [self.gameBackground setImage:background];
}

- (void)loadDefaultBubbles{
    //for testing mapping will be passed from game designer when PS3 is fully integrated with this.
    if(!self.bubbleMappings){
        self.bubbleMappings =
                       @{[NSNumber numberWithInt:0]: [UIImage imageNamed:@"bubble-orange"],
                         [NSNumber numberWithInt:1]: [UIImage imageNamed:@"bubble-blue"],
                         [NSNumber numberWithInt:2]: [UIImage imageNamed:@"bubble-green"],
                         [NSNumber numberWithInt:3]: [UIImage imageNamed:@"bubble-red"],
                        };
    }
}

- (void)loadDefaultBubbleMapping:(NSDictionary *)mapping{
    self.bubbleMappings = mapping;
}

- (void)loadGridBubblesFromModel:(NSDictionary *)models{
    for(BubbleModel *model in models){
        NSInteger bubbleTypeNum = [model bubbleType];
        NSNumber *bubbleType = [NSNumber numberWithInteger:bubbleTypeNum];
        
        CGPoint bubbleCenter = [model center];
        BubbleView *bubbleView = [BubbleView createWithCenter:bubbleCenter andWidth:[model width] andImage:[self.bubbleMappings objectForKey:bubbleType]];
        [self.gameBackground addSubview:bubbleView];
        [self addGridBubbleToEngine:bubbleView forType:bubbleTypeNum withCenter:bubbleCenter];
    }
}

- (void)addGridBubbleToEngine:(BubbleView *)bubble forType:(NSInteger)type withCenter:(CGPoint)center{
    [self.engine addGridEngine:bubble withType:type andCenter:center];
}

- (void)initialiseBubbleGrid{
    NSInteger frameWidth = self.gameBackground.frame.size.width;
    NSInteger frameHeight = self.gameBackground.frame.size.height;
    CGRect collectionFrame = CGRectMake(0, 0, frameWidth, frameHeight);
    NSInteger numOfRows = floor(NUM_OF_CELLS_IN_ROW*frameHeight/frameWidth);
    BubbleGridLayout *layout = [[BubbleGridLayout alloc] initWithFrameWidth:frameWidth andNumOfCellsInRow:NUM_OF_CELLS_IN_ROW andNumOfRows:numOfRows];
    bubbleGridTemplate = [[UICollectionView alloc] initWithFrame:collectionFrame collectionViewLayout:layout];

    [bubbleGridTemplate setBackgroundColor:[UIColor clearColor]];
    [bubbleGridTemplate setDataSource:self];
    [bubbleGridTemplate setDelegate:self];
    
    self.defaultBubbleRadius = (layout.cellWidth)/2;

}

- (void)addGestureRecognisers{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandler:)];
    [self.gameBackground addGestureRecognizer:tapGesture];
    
      UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panHandler:)];
    [self.gameBackground addGestureRecognizer:panGesture];
    
       UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressHandler:)];
    [self.gameBackground addGestureRecognizer:longPressGesture];
}

- (void)loadNextBubble{
    taggedCannonBubble = [bubbleLoader getNextBubble];
    BubbleView *bubbleView = [taggedCannonBubble object];
    [bubbleView setCenter:[self getStartingBubbleCenter]];
    [self.gameBackground insertSubview:bubbleView belowSubview:cannon];
}

- (BubbleView *)createAndAddNewBubbleViewWithType:(NSInteger)type{
    CGPoint bubbleCenter = [self getStartingBubbleCenter];
    BubbleView *bubbleView = [BubbleView createWithCenter:bubbleCenter andWidth:(self.defaultBubbleRadius * 2) andImage:[self.bubbleMappings objectForKey:[NSNumber numberWithInteger:type]]];
    [self.gameBackground addSubview:bubbleView];
    return bubbleView;
}

- (CGPoint)getStartingBubbleCenter{
    //TODO:
    CGPoint base = CGPointMake(self.gameBackground.center.x, self.gameBackground.frame.size.height);
    CGPoint offset = [self getUnitVectorStart:base toEnd:cannon.center];
    CGFloat xPos = offset.x * (CANNON_HEIGHT / 2 - self.defaultBubbleRadius) + cannon.center.x;
    CGFloat yPos = offset.y * (CANNON_HEIGHT / 2 - self.defaultBubbleRadius) + cannon.center.y;
    return CGPointMake(xPos, yPos);
}

- (void)addMobileBubbleToEngine:(BubbleView *)bubble forType:(NSInteger)type{
    [self.engine addMobileEngine:bubble withType:type];
}

- (void)panHandler:(UIGestureRecognizer *)recogniser{
    [self rotateCannonInDirection:[recogniser locationInView:self.gameBackground]];
    if(recogniser.state == UIGestureRecognizerStateEnded){
        [self launchBubbleWithInputPoint:[recogniser locationInView:self.gameBackground]];
    }
}

- (void)longPressHandler:(UIGestureRecognizer *)recogniser{
    [self rotateCannonInDirection:[recogniser locationInView:self.gameBackground]];
    if(recogniser.state == UIGestureRecognizerStateEnded){
        [self launchBubbleWithInputPoint:[recogniser locationInView:self.gameBackground]];
    }
}

- (void)tapHandler:(UIGestureRecognizer *)recogniser{
    [self rotateCannonInDirection:[recogniser locationInView:self.gameBackground]];
    [self launchBubbleWithInputPoint:[recogniser locationInView:self.gameBackground]];
}

- (void)rotateCannonInDirection:(CGPoint)point{
    CGPoint base = CGPointMake(self.gameBackground.center.x, self.gameBackground.frame.size.height);
    CGPoint unitOffSet = [self getUnitVectorStart:base toEnd:point];
    [self updateCannonPosition:base withOffset:unitOffSet];
    CGFloat tanRatio = (unitOffSet.x / unitOffSet.y) * -1;
    CGFloat angle = atanf(tanRatio);
    cannon.transform = CGAffineTransformMakeRotation(angle);
}

- (void)updateCannonPosition:(CGPoint)base withOffset:(CGPoint)unitOffSet{
    CGFloat newX = unitOffSet.x * CANNON_HEIGHT / 2 + base.x;
    CGFloat newY = unitOffSet.y * CANNON_HEIGHT / 2 + base.y;
    CGPoint newCannonCenter = CGPointMake(newX, newY);
    [cannon setCenter:newCannonCenter];
    [self shiftBubbleInCannonWithOffset:unitOffSet];
}

- (void)shiftBubbleInCannonWithOffset:(CGPoint)unitOffset{
    CGPoint newCenter = [self getStartingBubbleCenter];
    [[taggedCannonBubble object] setCenter:newCenter];
}

- (void)launchBubbleWithInputPoint:(CGPoint)point{
    [cannon startAnimating];//TODO
    [self addMobileBubbleToEngine:[taggedCannonBubble object] forType:[[taggedCannonBubble tag] integerValue]];
    CGPoint end = point;
    CGPoint start = [self getStartingBubbleCenter];
    CGPoint displacement = [self getUnitVectorStart:start toEnd:end];
    [self launchBubbleWithDisplacementVector:displacement];
}

- (void)launchBubbleWithDisplacementVector:(CGPoint)vector{
    [engine setDisplacementVectorForBubble:vector];
    [self loadNextBubble];
}

- (CGPoint)getUnitVectorStart:(CGPoint)start toEnd:(CGPoint)end{
    CGPoint vector = CGPointMake(end.x - start.x, end.y - start.y);
    CGFloat magnitude = sqrt(pow(vector.x, 2) + pow(vector.y, 2));
    return CGPointMake(vector.x/magnitude , vector.y/magnitude);
}

#pragma mark - UICollectionViewDataSource & UICollectionViewDelegate Methods
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    return nil;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [(BubbleGridLayout *)bubbleGridTemplate.collectionViewLayout defaultBubbleCellCount];
}

#pragma mark - Delegate method to get bubble grid details
- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)center{
    return [bubbleGridTemplate indexPathForItemAtPoint:center];
}

- (CGPoint)getCenterForItemAtIndexPath:(NSIndexPath *)path{
    return [(BubbleGridLayout *)bubbleGridTemplate.collectionViewLayout getCenterForItemAtIndex:path.item];
}

- (NSInteger)getRowNumberFromIndexPath:(NSIndexPath *)path{
   return [(BubbleGridLayout *)bubbleGridTemplate.collectionViewLayout getRowNumberFromIndex:path.item];
}

- (NSInteger) getRowPositionFromIndexPath:(NSIndexPath *)path{
   return [(BubbleGridLayout *)bubbleGridTemplate.collectionViewLayout getRowPositionFromIndex:path.item];
}

@end
