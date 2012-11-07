//
//  AccessPointsController.h
//  OfflineHotspots
//
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//  Created by Davide Guerri on 12/01/12.
//  Copyright (c) 2012 __Davide Guerri__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AccessPoint.h"
#import "RMLatLong.h"
#import "AccessPointMarker.h"

@interface AccessPointsManager : NSObject <NSFetchedResultsControllerDelegate>

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

- (BOOL)resetPersistentStore:(NSError **)error;

- (void)updateAccessPoints;

- (NSUInteger)citiesCount;
- (NSUInteger)indexForCity:(NSString *)city;
- (NSString *)cityForIndex:(NSUInteger)index;
- (NSArray *)accessPoints;
- (NSArray *)accessPointsInCityIndex:(NSUInteger)index;
- (NSArray *)accessPointsInCity:(NSString *)city;
- (NSArray *)accessPointsInSphericalTrapezium:(RMSphericalTrapezium)sphericalTrapezium;
- (NSInteger)accessPointCountInCity:(NSString *)city;
- (NSInteger)accessPointCountInCityIndex:(NSUInteger)index;

- (void)resetToFactory;

@end
