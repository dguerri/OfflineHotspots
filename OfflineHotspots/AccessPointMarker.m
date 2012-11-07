//
//  TappableLabeledMarkers.m
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

#import "AccessPointMarker.h"
#import "RMMarker.h"
#import "AccessPoint.h"

#pragma mark - Macros

#define cCOImageTopInset 23 
#define cCOImageBottomInset 46
#define cCOImageLeftInset 10 
#define cCOImageRightInset 10
#define cCOImageBorder 40
#define cCODetailsImageBorder 10
#define cCOTileFontSize 13 
#define cCOAddressFontSize 12 

#pragma mark - Implementation

@implementation AccessPointMarker

#pragma mark - Properties synthetization

@synthesize accessPoint = _accessPoint;

#pragma mark - Class methods and attibutes

static NSMutableDictionary *_accessPointMarkersPool;

+ (UIImage *)iconForCategory:(NSString *)aCategory
{
    // Initialize _accessPointMarkersPool with momoization
    if (!_accessPointMarkersPool)
        _accessPointMarkersPool = [[NSMutableDictionary alloc] init];
    
    // Obtain a valid filename
    NSString *escapedValue = [[aCategory componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@""];
    
    if (escapedValue.length == 0) escapedValue = @"unknown";
    
    NSString *filename = [NSString stringWithFormat:@"%@-ap-marker.png", escapedValue];
    
    UIImage *image = [_accessPointMarkersPool objectForKey:filename];
    if (!image) {
        image = [UIImage imageNamed:filename];
        
        if (!image) image = [UIImage imageNamed:@"default-ap-marker.png"];
        
        [_accessPointMarkersPool setObject:image forKey:filename];
        
    }
    return image;
}

#pragma mark - Contructors

- (id)init
{
    self = [super init];
    
    // Set defaults
    UIImage *image = [UIImage imageNamed:@"default-ap-marker.png"];
    [self replaceUIImage:image anchorPoint:CGPointMake(image.size.width/2.0f, image.size.height)];
    self.enableRotation = NO;
    
    self.zPosition = 1.0f;
    
    return self;
}

- (void)dealloc
{
    [self setAccessPoint:nil];
}
#pragma make - Utilities

- (void)updateImage
{
    [self replaceUIImage:[AccessPointMarker iconForCategory:self.accessPoint.category]];
}


#pragma mark - Custom accessors

- (void)setAccessPoint:(AccessPoint *)accessPoint
{
    _accessPoint = accessPoint;
    [self updateImage];
}

#pragma mark - TappableRMMarker protocol

- (void)tapped
{
    if (self.label) {
        [self setLabel:nil]; 
        [self hideLabel];
        [self setZPosition:0.0f];
    } else {
        CGSize titleTextSize = [self.accessPoint.title sizeWithFont:[UIFont boldSystemFontOfSize:cCOTileFontSize]]; 
        CGSize addressTextSize = [self.accessPoint.address sizeWithFont:[UIFont boldSystemFontOfSize:cCOAddressFontSize]];
        CGSize textSize = CGSizeMake(MAX(titleTextSize.width, addressTextSize.width), addressTextSize.height + addressTextSize.height);
        
        UIImage *leftCalloutImage = [[UIImage imageNamed:@"callout_left.png"] resizableImageWithCapInsets:
                                     UIEdgeInsetsMake(cCOImageTopInset, cCOImageLeftInset, cCOImageBottomInset, 1)]; 
        UIImage *centerCalloutImage = [[UIImage imageNamed:@"callout_center.png"] resizableImageWithCapInsets:
                                       UIEdgeInsetsMake(cCOImageTopInset, 0, cCOImageBottomInset, 0)]; 
        UIImage *rightCalloutImage = [[UIImage imageNamed:@"callout_right.png"] resizableImageWithCapInsets:
                                      UIEdgeInsetsMake(cCOImageTopInset, 1, cCOImageBottomInset, cCOImageRightInset)];
        UIImage *detailsImage = [UIImage imageNamed:@"callout_details.png"];
        
        NSInteger centerWidth = centerCalloutImage.size.width;
        NSInteger leftWidth = leftCalloutImage.size.width + (textSize.width/2 - centerWidth/2) + detailsImage.size.width/2 + cCODetailsImageBorder/2;
        NSInteger rightWidth = leftWidth;
        NSInteger totalWidth = centerWidth + leftWidth + rightWidth;
        NSInteger totalHeight = MAX(textSize.height + cCOImageBorder, detailsImage.size.height + cCOImageBorder);
        
        UIView *labelView = [[UIView alloc] initWithFrame:CGRectMake(-totalWidth/2, 
                                                                     -totalHeight + 5, 
                                                                     totalWidth, 
                                                                     totalHeight)]; 
        labelView.backgroundColor = [UIColor clearColor]; 
        
        
        UIImageView *leftCalloutView =   [[UIImageView alloc] initWithFrame:CGRectMake(leftCalloutImage.size.width, 0, leftWidth, labelView.frame.size.height)]; 
        UIImageView *centerCalloutView = [[UIImageView alloc] initWithFrame:CGRectMake(leftCalloutView.frame.origin.x + leftCalloutView.frame.size.width, leftCalloutView.frame.origin.y, centerWidth, leftCalloutView.frame.size.height)];
        UIImageView *rightCalloutView =  [[UIImageView alloc] initWithFrame:CGRectMake(centerCalloutView.frame.origin.x + centerCalloutView.frame.size.width, centerCalloutView.frame.origin.y, rightWidth, centerCalloutView.frame.size.height)]; 
        
        leftCalloutView.image = leftCalloutImage; 
        centerCalloutView.image = centerCalloutImage; 
        rightCalloutView.image = rightCalloutImage;
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftCalloutView.frame.origin.x + cCOImageLeftInset + 8, 
                                                                        leftCalloutView.frame.origin.y + 10, 
                                                                        titleTextSize.width, 
                                                                        titleTextSize.height)]; 
        titleLabel.font = [UIFont boldSystemFontOfSize:cCOTileFontSize]; 
        titleLabel.text = self.accessPoint.title; 
        titleLabel.textColor = [UIColor whiteColor]; 
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.layer.name = cCOTitleLayerName;
        
        UILabel *addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(titleLabel.frame.origin.x,
                                                                          titleLabel.frame.origin.y + titleLabel.frame.size.height,
                                                                          addressTextSize.width,
                                                                          addressTextSize.height)]; 
        addressLabel.font = [UIFont boldSystemFontOfSize:cCOAddressFontSize]; 
        addressLabel.text = self.accessPoint.address; 
        addressLabel.textColor = [UIColor whiteColor]; 
        addressLabel.backgroundColor = [UIColor clearColor]; 
        addressLabel.layer.name = cCOAddressLayerName;
        
        UIImageView *detailsImageView = [[UIImageView alloc] 
                                         initWithFrame:CGRectMake(titleLabel.frame.origin.x + textSize.width + cCODetailsImageBorder,
                                                                  leftCalloutView.frame.origin.y + 13,
                                                                  detailsImage.size.width,
                                                                  detailsImage.size.height)]; 
        detailsImageView.image = detailsImage;
        detailsImageView.layer.name = cCODetailsBottonLayerName;
        
        [labelView addSubview:leftCalloutView];
        [labelView addSubview:centerCalloutView];
        [labelView addSubview:rightCalloutView];
        [labelView addSubview:titleLabel];
        [labelView addSubview:addressLabel];
        [labelView addSubview:detailsImageView];
        
        [self setLabel:labelView]; 
        [self showLabel];
        [self setZPosition:2.0f];
    } 
}

@end
