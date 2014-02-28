//
//  GameState.m
//  BubbleGame
//
//  Created by Naomi Leow on 27/2/14.
//  Copyright (c) 2014 nus.cs3217. All rights reserved.
//

#import "GameState.h"
#define DROPPED_SCORE 25
#define POPPED_SCORE 10

@implementation GameState{
    NSInteger totalBubbles;
    NSInteger numOfLaunchedBubbles;
}

@synthesize gridBubbles;
@synthesize totalScore;

- (id)init{
    if(self = [super init]){
        gridBubbles = [[BubbleEngineManager alloc] init];
        totalBubbles = 0;
        totalScore = 0;
        numOfLaunchedBubbles = 0;
    }
    return self;
}

- (void)updateTotalScoresForDroppedBubbles:(NSInteger)num{
    totalBubbles += num * DROPPED_SCORE;
}

- (void)updateTotalScoresForPoppedBubbles:(NSInteger)num{
    totalBubbles += num * POPPED_SCORE;
}


- (NSSet *)insertBubble:(BubbleEngine *)bubbleEngine intoGridAtRow:(NSInteger)row andCol:(NSInteger)col{
    totalBubbles += 1;
    return [gridBubbles insertObject:bubbleEngine AtRow:row andPosition:col];
}

- (NSArray *)getNeighboursForObjectAtRow:(NSInteger)row andPosition:(NSInteger)pos{
    return [gridBubbles getNeighboursForObjectAtRow:row andPosition:pos];
}

- (NSArray *)getObjectsAtRow:(NSInteger)row{
    return [gridBubbles getObjectsAtRow:row];
}

- (NSArray *)getAllObjects{
    return [gridBubbles getAllObjects];
}

- (NSSet *)getAllObjectsOfType:(NSInteger)type{
    return [gridBubbles getAllObjectsOfType:type];
}

- (NSDictionary *)getAllClusters{
    return [gridBubbles getAllClusters];
}

- (void)removeGridBubbleAtRow:(NSInteger)row andPositions:(NSInteger)col{
    totalBubbles -= 1;
    [gridBubbles removeObjectAtRow:row andPosition:col];
}

- (NSMutableSet *)getOrphanedBubblesIncludingCluster:(id)cluster{
    NSMutableSet *accumulated = nil;
    NSMutableSet *allAccumulated = [[NSMutableSet alloc] init];
    NSMutableSet *visited = [[NSMutableSet alloc] init];
    BOOL searchResult;
    
    for(BubbleEngine *engine in cluster){
        if([visited containsObject:engine]){
            continue;
        }
        //New cluster
        accumulated = [[NSMutableSet alloc] init];
        searchResult = [self searchForRootBubble:accumulated startPoint:engine visitedBubbles:visited];
        if(!searchResult){
            [allAccumulated addObject:accumulated];
        }
    }
    return allAccumulated;
}

- (NSMutableSet *)getOrphanedBubblesNeighbouringCluster:(NSSet *)cluster{
    //Deprecated but used in old tests
    NSMutableSet *accumulated = nil;
    NSMutableSet *allAccumulated = [[NSMutableSet alloc] init];
    NSMutableSet *visited = [[NSMutableSet alloc] init];
    BOOL searchResult;
    for(BubbleEngine *removedEngine in cluster){
        NSArray *neighbours = [gridBubbles getNeighboursForObjectAtRow:removedEngine.gridRow andPosition:removedEngine.gridCol];
        for(BubbleEngine *engine in neighbours){
            if([visited containsObject:engine]){
                continue;
            }
            //New cluster
            accumulated = [[NSMutableSet alloc] init];
            searchResult = [self searchForRootBubble:accumulated startPoint:engine visitedBubbles:visited];
            if(!searchResult){
                [allAccumulated addObject:accumulated];
            }
        }
    }
    return allAccumulated;
}

- (BOOL)searchForRootBubble:(NSMutableSet *)accumulatedCluster startPoint:(BubbleEngine *)bubble visitedBubbles:(NSMutableSet *)visited{
    BOOL (^searchCondition)(BubbleEngine *) = ^(BubbleEngine *bubbleEngine){
        if(bubbleEngine.gridRow == 0){
            return YES;
        }else{
            return NO;
        }
    };
    return [gridBubbles depthFirstSearchAndCluster:accumulatedCluster
                                        startPoint:bubble
                             accumulationCondition:nil
                               andSearchConditions:searchCondition
                                      visitedItems:visited];
}

- (void)increaseLaunchedBubblesCount{
    numOfLaunchedBubbles += 1;
}

@end