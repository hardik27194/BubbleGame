//
//  BubbleControllerManager.h
//  BubbleGame
//
//  Created by Naomi Leow on 28/2/14.
//  Copyright (c) 2014 nus.cs3217. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BubbleManager.h"
#import "GameLevelLoader.h"
#import "BubbleGridLayout.h"
#import "BubbleControllerDelegate.h"
#import "BubbleModel.h"

@interface ControllerDataManager: NSObject <BubbleControllerDelegate>

@property (strong) BubbleManager *bubbleControllerManager;
@property (strong) GameLevelLoader *gameLoader;
@property (strong) BubbleGridLayout *gridTemplate;
@property (strong) UICollectionView *bubbleGrid;
@property (strong) UIView *gameArea;
@property (strong, nonatomic) NSDictionary *paletteImages;

- (id)initWithView:(UIView *)view andBubbleGrid:(UICollectionView *)grid andImageMappings:(NSDictionary *)mappings;

- (id)getBubbleControllerAtCollectionViewIndex:(NSIndexPath *)index;

- (NSInteger)getBubbleTypeForBubbleAtCollectionViewIndex:(NSIndexPath *)index;

- (BOOL)modifyBubbleAtCollectionViewIndex:(NSIndexPath *)index ToType:(NSInteger)type;
//Modifies type of bubble at given index
//Returns YES if a bubble exists at the given index. NO otherwise

- (void)addBubbleFromModel:(BubbleModel *)model atIndex:(NSIndexPath *)index;

- (void)insertBubbleController:(id)controller AtCollectionViewIndex:(NSIndexPath *)index;

- (void)removeBubbleControllerAtCollectionViewIndex:(NSIndexPath *)index;

- (void)addOrModifyBubbleAtCollectionViewIndex:(NSIndexPath *)index withType:(NSInteger)type;
//Adds bubble of given type to given index
//If a bubble already exists at the stated index, its type is modified 

- (void)removeBubbleAtCollectionViewIndex:(NSIndexPath *)index;

- (NSArray *)getAllObjects;


- (void)removeAllBubbles;

- (void)saveUnsavedStateToTempFile;

- (NSDictionary *)loadUnsavedStateFromTempFile;

- (NSDictionary *)loadPreviousLevel;

- (NSDictionary *)loadLevel:(NSInteger)level;

- (NSInteger)saveLevel;

- (void)resetLevel;

- (void)loadNewLevel;

- (void)loadBubblesFromModels:(NSDictionary *)bubbleModels;

- (void)loadGameLevelWithModels:(NSDictionary *)models;

- (void)loadLevelFromTempIfTempFileExists;

//gameloader stuff
- (BOOL)hasUnsavedBubbles;

- (NSInteger)currentLevel;

- (NSArray *)getAvailableLevels;

- (NSDictionary *)getAllBubbleModels;

@end
