//
//  GeoRSSParser.m
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

#import "GeoRSSParser.h"
#import "GeoRSSAccessPoint.h"

#pragma mark - Private interface

@interface GeoRSSParser() {
    NSMutableString *_currentElementValue;
    GeoRSSAccessPoint *_accessPoint;
}

@end

#pragma mark - Implementation

@implementation GeoRSSParser

#pragma mark - Properties synthetization

@synthesize accessPoints = _accessPoints;

#pragma mark - Constructors

- (GeoRSSParser *)initGeoRSSParser
{
    self = [super init]; 
    
    self.accessPoints = [[NSMutableArray alloc] init];
    
    return self;
}

#pragma mark - Private methods

- (void)parser:(NSXMLParser *)parser 
didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qualifiedName 
    attributes:(NSDictionary *)attributeDict {
	
    if ([elementName isEqualToString:@"item"]) {
        //NSLog(@"item element found – create a new instance of AccessPoint class...");
        _accessPoint = [[GeoRSSAccessPoint alloc] init];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    if (!_currentElementValue) {
        // init the ad hoc string with the value     
        _currentElementValue = [[NSMutableString alloc] initWithString:string];
    } else {
        // append value to the ad hoc string    
        [_currentElementValue appendString:string];
    }
}  

- (void)parser:(NSXMLParser *)parser 
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName {
    
    if ([elementName isEqualToString:@"channel"]) {
        // We reached the end of the XML document
        return;
    }
    
    if ([elementName isEqualToString:@"item"]) {
        // We are done with entry – add the parsed user 
        // object to our user array
        if ([_accessPoint isValid])
            [self.accessPoints addObject:_accessPoint];
        else
            NSLog(@"Invalid access point entry discarded!");
        // release the object
        _accessPoint = nil;
    } else {
        NSString *value = [NSString stringWithString:_currentElementValue];
        
        while (value && [value length] && ([value characterAtIndex:0] == '\n' || [value characterAtIndex:0] == ' '))
        {
            value = [value substringFromIndex:1];  
        }
        
        //NSLog(@"Value '%@' for key '%@'", value, elementName);
        
        if ([elementName isEqualToString:@"georss:lat"] || [elementName isEqualToString:@"lat"])
            [_accessPoint setValue:[NSNumber numberWithDouble:[value doubleValue]] forKey:@"lat"];         
        else if ([elementName isEqualToString:@"georss:long"] || [elementName isEqualToString:@"long"])
            [_accessPoint setValue:[NSNumber numberWithDouble:[value doubleValue]] forKey:@"lon"]; 
        else if ([elementName isEqualToString:@"georss:point"]) {
            NSArray *latLon = [value componentsSeparatedByString:@" "];
            [_accessPoint setValue:[NSNumber numberWithDouble:[[latLon objectAtIndex:0] doubleValue]] forKey:@"lat"];
            [_accessPoint setValue:[NSNumber numberWithDouble:[[latLon objectAtIndex:1] doubleValue]] forKey:@"lon"];
        }
        else if ([elementName isEqualToString:@"description"]) {
            NSArray *descriptions = [value componentsSeparatedByString:@"-"];
            if (descriptions) {
                [_accessPoint setValue:[[descriptions lastObject] capitalizedString] forKey:@"city"];
                [_accessPoint setValue:[[descriptions objectAtIndex:0] capitalizedString] forKey:@"address"];
            } else
                [_accessPoint setValue:[value capitalizedString] forKey:@"city"];
        }
        else if ([elementName isEqualToString:@"category"])
            [_accessPoint setValue:[value capitalizedString] forKey:@"category"];         
        else if ([elementName isEqualToString:@"title"])
            [_accessPoint setValue:[value capitalizedString] forKey:@"title"];         
    }
    
    _currentElementValue = nil;
}

@end
