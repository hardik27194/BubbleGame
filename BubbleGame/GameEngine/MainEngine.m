//
//  Engine.m
//  ps04
//
//  Created by Naomi Leow on 11/2/14.
//
//

#import "MainEngine.h"
#import "BubbleEngine.h"
#import "BubbleGridLayout.h"
#import <QuartzCore/QuartzCore.h>
#import "GameCommon.h"

#define DEFAULT_ID 0
#define DEFAULT_SPEED_FACTOR 20

//All bubbleviews will be wrapped in a BubbleEngine instance which will act as its controller
@implementation MainEngine{
    CADisplayLink *displayLink;
    NSMutableArray *mobileBubblesToRemove;
    NSInteger nextEngineID;
}

@synthesize defaultSpeed;
@synthesize bubbleGameState;
@synthesize frameHeight;
@synthesize frameWidth;
@synthesize gridTemplateDelegate;
@synthesize gameLevel;

- (void)checkGridBubbles{
    //Checks if stored GridBubbles tally with view, ie all of the BubbleEngine instances have their corresponding views rendered
    for(BubbleEngine *engine in [bubbleGameState getAllObjects]){
        id view = [engine bubbleView];
        if(view == nil || ![view isRendered]){
            [NSException raise:@"BubbleGrid and view rendering error" format:
             @"Bubble data stored inconsistent with view!"];
        }
    }
}

- (id)initWithGameLevel:(NSString *)level{
    if(self = [super init]){
        defaultSpeed = DEFAULT_SPEED_FACTOR;
        nextEngineID = DEFAULT_ID;
        gameLevel = level;
        mobileBubbles = [[NSMutableArray alloc] init];
        mobileBubblesToRemove = [[NSMutableArray alloc] init];
        bubbleGameState = [[GameState alloc] initWithLevel:gameLevel];
        [self createDisplayLink];
    }
    return self;
}

- (void)reload{
    [self clearAllExistingBubbleViews];
    mobileBubbles = [[NSMutableArray alloc] init];
    mobileBubblesToRemove = [[NSMutableArray alloc] init];
    [bubbleGameState reload];
}

- (void)shutdownDisplayLink{
    [displayLink invalidate];
}

- (void)clearAllExistingBubbleViews{
    NSArray *bubbles = [bubbleGameState getAllObjects];
    for(BubbleEngine *engine in bubbles){
        [engine removeBubbleView];
    }
    for(BubbleEngine *engine in mobileBubbles){
        [engine removeBubbleView];
    }
}

- (void)createDisplayLink{
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateMobilePositions:)];
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (BubbleEngine *)addMobileEngine:(id)bubble withType:(NSInteger)type{
    BubbleEngine *bubbleEngine = [self createBubbleEngineWithView:(id)bubble andType:type];
    [mobileBubbles addObject:bubbleEngine];
    return bubbleEngine;
}

- (BubbleEngine *)addMobileEngine:(id)bubble withType:(NSInteger)type andInitialUnitDisplacement:(CGPoint)vector{
    BubbleEngine *bubbleEngine = [self addMobileEngine:bubble withType:type];
    [self setDisplacementVectorForBubbleEngine:bubbleEngine withUnitDisplacement:vector];
    return bubbleEngine;
}

- (BubbleEngine *)createBubbleEngineWithView:(id)bubble andType:(NSInteger)type{
    BubbleEngine *bubbleEngine = [[BubbleEngine alloc] initWithBubbleView:bubble andID:nextEngineID];
    [bubbleEngine setBubbleType:type];
    nextEngineID += 1;
    [bubbleEngine setMainEngine:self];
    return bubbleEngine;
}

- (BubbleEngine *)createBubbleEngineWithView:(id)bubble andType:(NSInteger)type andCenter:(CGPoint)center{
    BubbleEngine *bubbleEngine = [[BubbleEngine alloc] initAsGridBubbleWithCenter:center view:bubble andID:nextEngineID];
    [bubbleEngine setBubbleType:type];
    nextEngineID += 1;
    [bubbleEngine setMainEngine:self];
    return bubbleEngine;
}
- (void)addGridEngine:(id)bubble withType:(NSInteger)type andCenter:(CGPoint)center{
    BubbleEngine *bubbleEngine = [self createBubbleEngineWithView:bubble andType:type andCenter:center];
    NSIndexPath *path = [gridTemplateDelegate indexPathForItemAtPoint:center];
    [self insertBubble:bubbleEngine intoGridAtIndexPath:path];
    [self checkGridBubbles];
}

- (void)setDisplacementVectorForNewestBubble:(CGPoint)vector{
    BubbleEngine *bubbleEngine = [mobileBubbles lastObject];
    CGPoint displacement = CGPointMake(vector.x * defaultSpeed, vector.y * defaultSpeed);
    [bubbleEngine setDisplacementVector:displacement];
}

- (void)setDisplacementVectorForBubbleEngine:(BubbleEngine *)bubbleEngine withUnitDisplacement:(CGPoint)vector{
    CGPoint displacement = CGPointMake(vector.x * defaultSpeed, vector.y * defaultSpeed);
    [bubbleEngine setDisplacementVector:displacement];
}

- (void)updateMobilePositions:(CADisplayLink *)sender{
    for(BubbleEngine *bubbleEngine in mobileBubbles){
        [bubbleEngine moveBubble];
    }
    [self cleanUpMobileArray];
}

- (void)cleanUpMobileArray{
    [mobileBubbles removeObjectsInArray:mobileBubblesToRemove];
    [mobileBubblesToRemove removeAllObjects];
}

- (void)setMobileBubbleAsGridBubble:(id)object{
    //Expects object to be of type BubbleEngine
    //Will update BubbleEngine to store center and coordinates of grid
    object = (BubbleEngine *)object;
    [mobileBubblesToRemove addObject:object];
    NSIndexPath *path = [gridTemplateDelegate indexPathForItemAtPoint:[object center]];
    if(!path){
        CGPoint backtrack = [object getBacktrackedCenter];
        if(backtrack.x > 0 || backtrack.y > 0){
            //Check that backtrack is a possible previous bubble center coordinate in the game area.
            path = [gridTemplateDelegate indexPathForItemAtPoint:[object getBacktrackedCenter]];
        }
    }
    if(path){
        CGPoint gridCenter = [gridTemplateDelegate getCenterForItemAtIndexPath:path];
        [object setCenter:gridCenter];
        NSSet *matchingCluster = [self insertBubble:object intoGridAtIndexPath:path];
        [self removeBubblesIfNecessary:matchingCluster onInsertionOf:object];
    }else{
        NSDictionary *gameOverMessage = @{ENDGAME_STATUS:[NSNumber numberWithBool:NO],
                                          ENDGAME_MESSAGE: @"Maximum bubble layers exceeded",
                                          };
        NSNotificationCenter *notification = [NSNotificationCenter defaultCenter];
        [notification postNotificationName:ENDGAME object:self userInfo:gameOverMessage];
    }
}

- (void)removeBubblesIfNecessary:(NSSet *)matchingCluster onInsertionOf:(id)object{
    [self handleMatchingCluster:matchingCluster];
    [self removeAllOrphanedBubbles];
    [self checkGridBubbles];
}

- (void)handleMatchingCluster:(NSSet *)matchingCluster{
    if([matchingCluster count] >= 3){
        [self popBubblesInCollection:matchingCluster withCondition:nil];
    }
}

- (NSArray *)removeAllNeighboursForBubble:(BubbleEngine *)bubbleEngine{
    NSArray *neighbourList = nil;
    if(bubbleEngine){
        neighbourList = [bubbleGameState getNeighboursForObjectAtRow:bubbleEngine.gridRow andPosition:bubbleEngine.gridCol];
        BOOL (^filterCond)(BubbleEngine *) = ^(BubbleEngine *bubble){
            if(bubble.bubbleType == INDESTRUCTIBLE){
                return NO;
            }else{
                return YES;
            }
        };
        [self popBubblesInCollection:neighbourList withCondition:filterCond];
    }
    return neighbourList;
}

- (void)removeAllBubbleOfType:(NSInteger)type{
    NSSet *bubblesOfType = [bubbleGameState getAllObjectsOfType:type];
    [self popBubblesInCollection:bubblesOfType withCondition:nil];
}

- (NSArray *)removeAllBubblesInRow:(NSInteger)row{
    NSArray *bubblesInRow = [bubbleGameState getObjectsAtRow:row];
    BOOL (^filterCond)(BubbleEngine *) = ^(BubbleEngine *bubble){
        if(bubble.bubbleType == INDESTRUCTIBLE){
            return NO;
        }else{
            return YES;
        }
    };
    [self popBubblesInCollection:bubblesInRow withCondition:filterCond];
    return bubblesInRow;
}

- (NSSet *)insertBubble:(BubbleEngine *)bubbleEngine intoGridAtIndexPath:(NSIndexPath *)path{
    NSInteger row = [gridTemplateDelegate getRowNumberFromIndexPath:path];
    NSInteger col = [gridTemplateDelegate getRowPositionFromIndexPath:path];
    
    [bubbleEngine setGridCol:col];
    [bubbleEngine setGridRow:row];
    return [bubbleGameState insertBubble:bubbleEngine intoGridAtRow:row andCol:col];
}

- (NSMutableSet *)getOrphanedBubblesNeighbouringCluster:(NSSet *)cluster{
    //Deprecated but used in old tests
    return [bubbleGameState getOrphanedBubblesNeighbouringCluster:cluster];
}

- (void)removeAllOrphanedBubbles{
    NSSet *allBubbles = [NSSet setWithArray:[bubbleGameState getAllObjects]];
    NSMutableSet *orphaned = [bubbleGameState getOrphanedBubblesIncludingCluster:allBubbles];
    for(NSMutableSet *set in orphaned){
        [self dropBubblesInCollection:set withCondition:nil];
    }
}

- (void)popBubble:(BubbleEngine *)bubbleEngine{
    if([bubbleEngine removeBubbleWithAnimationType:POP_ANIMATION] == YES){
        [bubbleGameState updateTotalScoresForPoppedBubbles:1];
    }
}

- (void)dropBubble:(BubbleEngine *)bubbleEngine{
    if([bubbleEngine removeBubbleWithAnimationType:DROP_ANIMATION] == YES){
        [bubbleGameState updateTotalScoresForDroppedBubbles:1];
    }
}
- (void)popBubblesInCollection:(id)bubbles withCondition:(BOOL(^)(BubbleEngine *))filter{
    NSInteger numRemoved = [self removeAllInCollection:bubbles removeType:POP_ANIMATION additionalRemoveFilter:filter];
    [bubbleGameState updateTotalScoresForPoppedBubbles:numRemoved];
}

- (void)dropBubblesInCollection:(id)bubbles withCondition:(BOOL(^)(BubbleEngine *))filter{
    NSInteger numRemoved = [self removeAllInCollection:bubbles removeType:DROP_ANIMATION additionalRemoveFilter:filter];
    [bubbleGameState updateTotalScoresForDroppedBubbles:numRemoved];
}

- (NSInteger)removeAllInCollection:(id)cluster removeType:(NSInteger)animationType additionalRemoveFilter:(BOOL(^)(BubbleEngine *))filter{
    /*!
     @param cluster: Collection of bubbles to remove. Parameter can be any iterable collection 1 dimentional data structure
     @param animationType: NSInteger corresponding to animation to apply when the bubble's view is removed.
     @param filter: Boolean block. Additional condition to apply to each bubble to which will determine if the bubble is actually removed
     @return number of bubbles actually removed
     */
    NSInteger totalRemoved = 0;
    for(BubbleEngine *engine in cluster){
        if(filter == nil || filter(engine)){
            if([engine removeBubbleWithAnimationType:animationType]){
                totalRemoved += 1;
            }
        }
    }
    return totalRemoved;
}


- (BOOL)hasCollisionWithGridForCenter:(CGPoint)point{
    NSArray *allGridBubbles = [bubbleGameState getAllObjects];
    for(BubbleEngine *engine in allGridBubbles){
        if([engine hasOverlapWithOtherCenter:point]){
            return YES;
        }
    }
    return NO;
}

- (NSInteger)getPreviousHighscore{
    return [bubbleGameState getPreviousHighscore];
}

- (void)saveGameHighScore{
    [bubbleGameState updateStoredHighscore];
}

- (void)removeGridBubbleAtRow:(NSInteger)row andPositions:(NSInteger)col{
    [bubbleGameState removeGridBubbleAtRow:row andPositions:col];
}

@end
