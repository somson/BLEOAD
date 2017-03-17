//
//  SPOADImageMetadata.h
//  GardenApp
//
//  Created by 史庆帅 on 2016/12/19.
//  Copyright © 2016年 xhoogee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "oad.h"
@interface SPOADImageMetadata : NSObject
- (instancetype)initWithImageData:(NSData *)data;

- (Image_header)imageHeader;

@end
