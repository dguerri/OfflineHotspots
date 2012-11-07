//
//  AccessPointsController.m
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

#import "AccessPointsManager.h"
#import "GeoRSSParser.h"
#import "GeoRSSAccessPoint.h"

#pragma mark - Macros

#define cFactoryHotspotListFilenamePrefix @"Factory-OfflineHotspots"
#define cStoreFilenamePrefix @"OfflineHotspots"
#define cStoreFilename @"OfflineHotspots.sqlite"
#define cGeoRSSURL1 [NSURL URLWithString:@"http://fly.provinciawifi.it/georss2/index-detailed.xml"]
#define cGeoRSSURL2 [NSURL URLWithString:@"http://fly.provinciawifi.it/georss/index-detailed.xml"]
#define cGeoRSSURLArray [NSArray arrayWithObjects:cGeoRSSURL1, cGeoRSSURL2, nil]

#pragma mark - Private interface

@interface AccessPointsManager() {
    NSMutableArray *_accessPointCityArray;
    NSMutableArray *_accessPointCityIndex;
    NSMutableArray *_accessPoints;
    
    UIAlertView *pleaseWaitAlert;
}

- (void)reloadData;
- (BOOL)dropPersistentStore:(NSError **)error;
- (NSPersistentStore *)addPersistentStore:(NSError **)error;
- (BOOL)resetPersistentStore:(NSError **)error;
- (NSURL *)factoryStoreURL;
- (NSURL *)storeURL;

@end

#pragma mark - Implementation

@implementation AccessPointsManager

#pragma mark - Properties synthetization

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize fetchedResultsController = _fetchedResultsController;

#pragma mark - Constructors

- (AccessPointsManager *)init
{
    self = [super init];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:[[self storeURL] path]]) {
        NSLog(@"Core Data Store not present, copying the factory default.");
        [self resetToFactory];
    } else
        [self reloadData];
    
    return self;
}

#pragma mark - Custom accessors

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil)
    {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil)
    {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"OfflineHotspots" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSError *error = nil;
    if (![self addPersistentStore:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Alert Views

- (void)showErrorAlert:(NSString *)message 
{
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) 
                                message:message 
                               delegate:self 
                      cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                      otherButtonTitles:nil] show];
}

- (void)showSuccessAlert:(NSString *)message 
{
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Operation completed", nil) 
                                message:message 
                               delegate:self 
                      cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                      otherButtonTitles:nil] show];
}

#pragma mark - Files management

- (NSURL *)factoryStoreURL
{
    return [[NSBundle mainBundle] URLForResource:cFactoryHotspotListFilenamePrefix withExtension:@"sqlite"];
}

- (NSURL *)storeURL
{
    return [[self applicationDocumentsDirectory] URLByAppendingPathComponent:cStoreFilename];
}

- (void)resetToFactory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([self factoryStoreURL]) {
        NSError *error;
        
        [fileManager removeItemAtURL:[self storeURL] error:nil];
        [fileManager copyItemAtURL:[self factoryStoreURL] toURL:[self storeURL] error:&error];
        
        if (error)
            NSLog(@"Error copying factory default Core Data store: %@", [error description]);
    }
    
    _persistentStoreCoordinator = nil;
    _managedObjectContext = nil;
    [self reloadData];
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Access point list update
- (void)updateUtilityArrays
{
    _accessPointCityArray = [[NSMutableArray alloc] init];
    _accessPointCityIndex = [[NSMutableArray alloc] init];
    
    for (AccessPoint *accessPoint in _accessPoints) {
        NSUInteger index = [_accessPointCityIndex indexOfObject:accessPoint.city];
        if (index == NSNotFound) {
            [_accessPointCityIndex addObject:accessPoint.city];
            [_accessPointCityArray addObject:[NSMutableArray arrayWithObject:accessPoint]];
        } else {
            [[_accessPointCityArray objectAtIndex:index] addObject:accessPoint];
        }
    }
}

- (void)reloadData
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"AccessPoint" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    
    NSSortDescriptor *sortByCityDescriptor = [[NSSortDescriptor alloc] initWithKey:@"city" ascending:YES];
    NSSortDescriptor *sortByTitleDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortByCityDescriptor, sortByTitleDescriptor, nil];
    
    [request setSortDescriptors:sortDescriptors];
    
    NSError *error = nil;
    _accessPoints = [[self.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
    if (_accessPoints == nil) {
        // Handle the error.
    }
    
    [self updateUtilityArrays];
}

- (void)updateAccessPoints
{
    NSError *error = nil;
    
    NSArray *geoRSSURLs = cGeoRSSURLArray;
    NSMutableArray *geoRSSAccessPoints = [NSMutableArray array];;
    
    for (NSURL *geoRSSURL in geoRSSURLs) {        
        NSLog(@"Loading data from URL: %@", [geoRSSURL description]);
        
        
        NSString *geoRSSFeed = [NSString stringWithContentsOfURL:geoRSSURL encoding:NSUTF8StringEncoding error:&error];
        
        if (!geoRSSFeed) {
            NSLog(@"Error: failed to load the geoRSSFeed @ URL '%@'", [geoRSSURL description]);
            continue;
        }
        
        // Delete headers
        NSUInteger beginningOfFeed = [geoRSSFeed rangeOfString:@"<rss"].location;
        if (beginningOfFeed == NSNotFound) {
            NSLog(@"Error: invalid geoRSSFeed @ URL '%@': RSS tag not found", [geoRSSURL description]);            
            continue;
        }            
        geoRSSFeed = [geoRSSFeed substringFromIndex:beginningOfFeed];
        
        
        NSData *data = [geoRSSFeed dataUsingEncoding:NSUTF8StringEncoding];
        NSXMLParser *nsXmlParser = [[NSXMLParser alloc] initWithData:data];
        GeoRSSParser *parser = [[GeoRSSParser alloc] initGeoRSSParser];
        [nsXmlParser setDelegate:parser];
        
        if ([nsXmlParser parse]) {
            [geoRSSAccessPoints addObjectsFromArray:[parser accessPoints]];
            NSLog(@"%d access points found", [geoRSSAccessPoints count]);
        } else {
            NSLog(@"Error: invalid geoRSSFeed @ URL '%@': failed to parse", [geoRSSURL description]);            
        }
    }
    
    if (geoRSSAccessPoints && [geoRSSAccessPoints count]) { 
        [self resetPersistentStore:&error];
        
        NSManagedObject *newAccessPoint;
        
        for (GeoRSSAccessPoint *geoRSSAccessPoint in geoRSSAccessPoints) {
            newAccessPoint = [NSEntityDescription insertNewObjectForEntityForName:@"AccessPoint" inManagedObjectContext:self.managedObjectContext];
            
            [newAccessPoint setValue:geoRSSAccessPoint.title forKey:@"title"];
            [newAccessPoint setValue:geoRSSAccessPoint.category forKey:@"category"];
            [newAccessPoint setValue:geoRSSAccessPoint.city forKey:@"city"];        
            [newAccessPoint setValue:geoRSSAccessPoint.address forKey:@"address"];   
            [newAccessPoint setValue:geoRSSAccessPoint.lat forKey:@"lat"];
            [newAccessPoint setValue:geoRSSAccessPoint.lon forKey:@"lon"];
            
            if ([self.managedObjectContext save:&error] == NO)            
                NSLog(@"Error saving access point '%@' in the object store: %@", geoRSSAccessPoint.title, error.description);
        }        
        
        [self showSuccessAlert:[NSString stringWithFormat:NSLocalizedString(@"%u hotspot loaded", nil), [geoRSSAccessPoints count]]];
    } else {
        NSLog(@"Error: access point list is empty!");
        [self showErrorAlert:NSLocalizedString(@"Error retry later", nil)];
    }
    [self reloadData];
}

#pragma mark - Utilities

- (NSUInteger)citiesCount
{
    return [_accessPointCityIndex count];
}

- (NSUInteger)indexForCity:(NSString *)city
{
    return [_accessPointCityIndex indexOfObject:city];
}

- (NSString *)cityForIndex:(NSUInteger)index 
{
    return [_accessPointCityIndex objectAtIndex:index];
}

- (NSArray *)accessPointsInCityIndex:(NSUInteger)index
{   
    return [_accessPointCityArray objectAtIndex:index];   
}

- (NSArray *)accessPointsInCity:(NSString *)city
{   
    return [self accessPointsInCityIndex:[self indexForCity:city]];   
}

- (NSInteger)accessPointCountInCity:(NSString *)city
{   
    return [[self accessPointsInCity:city] count];   
}

- (NSInteger)accessPointCountInCityIndex:(NSUInteger)index
{
    return [[self accessPointsInCityIndex:index] count];   
}

- (NSArray *)accessPoints
{
    return _accessPoints;
}

- (NSArray *)accessPointsInSphericalTrapezium:(RMSphericalTrapezium)sphericalTrapezium
{
    NSMutableArray *accessPointsInRect = [NSMutableArray array];
    
    for (AccessPoint *accessPoint in _accessPoints) {
        if (accessPoint.lat.doubleValue >= sphericalTrapezium.southwest.latitude &&
            accessPoint.lat.doubleValue <= sphericalTrapezium.northeast.latitude &&
            accessPoint.lon.doubleValue >= sphericalTrapezium.southwest.longitude &&
            accessPoint.lon.doubleValue <= sphericalTrapezium.northeast.longitude) {
            
            [accessPointsInRect addObject:accessPoint];
        }
            
    }
    return accessPointsInRect;
}

#pragma mark - Core Data stack

- (void)saveContext
{
    NSError *error = nil;
    if (self.managedObjectContext != nil)
    {
        if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error])
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

- (BOOL)dropPersistentStore:(NSError **)error
{
    if (self.persistentStoreCoordinator == nil) {
        return NO;
    }
    
    NSPersistentStore *store = [self.persistentStoreCoordinator persistentStoreForURL:self.storeURL];
    
    if ([self.persistentStoreCoordinator removePersistentStore:store error:error] == NO)
        return NO;
    return [[NSFileManager defaultManager] removeItemAtPath:[self.storeURL path] error:error];
}

- (NSPersistentStore *)addPersistentStore:(NSError **)error
{
    if (self.persistentStoreCoordinator == nil) {
        return nil;
    }
    
    return [self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeURL options:nil error:error];
    
}

- (BOOL)resetPersistentStore:(NSError **)error
{
    if ([self dropPersistentStore:error] == NO)
        return NO;
    return [self addPersistentStore:error] != nil;
}

@end
