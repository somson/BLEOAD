//
//  SPOADImageMetadata.m
//  GardenApp
//
//  Created by 史庆帅 on 2016/12/19.
//  Copyright © 2016年 xhoogee. All rights reserved.
//

#import "SPOADImageMetadata.h"

@interface SPOADImageMetadata ()
@property (nonatomic, copy) NSData *data;
@end
@implementation SPOADImageMetadata
- (instancetype)initWithImageData:(NSData *)data{
    if(self = [super init]){
        self.data = data;
    }
    return self;
}

- (Image_header)imageHeader{
    Image_header image_header;
    image_header.crc0 = [self calcImageCRC:0];
    image_header.crc1 = 0xffff;
    image_header.ver = 0;
    image_header.len = self.data.length / 4;
    image_header.uid[0] = image_header.uid[1] = image_header.uid[2] = image_header.uid[3] = 'E';
    image_header.address = 0x1000 / 4;
    image_header.imgType = 1;
    image_header.state = 0xff;
    return image_header;
}

- (uint16)calcImageCRC:(int)page{
    short crc = 0;
    long addr = page * 0x1000;
    Byte buf[self.data.length];
    [self.data getBytes:buf length:self.data.length];
    
    uint8 pageBeg = (uint8)page;
    uint8 pageEnd = (uint8)(self.data.length/4 / (0x1000 / 4));
    int osetEnd = (int)((self.data.length/4 - (pageEnd * (0x1000 / 4))) * 4);
    
    pageEnd += pageBeg;
    while (true) {
        int oset;
        
        for (oset = 0; oset < 0x1000; oset++) {
            if ((page == pageBeg) && (oset == 0x00)) {
                //Skip the CRC and shadow.
                //Note: this increments by 3 because oset is incremented by 1 in each pass
                //through the loop
                oset += 3;
            }
            else if ((page == pageEnd) && (oset == osetEnd)) {
                crc = [self crc16:crc val:(uint8)0x00];
                crc =  [self crc16:crc val:(uint8)0x00];
                return crc;
            }
            else {
                crc = [self crc16:crc val:buf[(int)(addr + oset)]];
            }
        }
        page += 1;
        addr = page * 0x1000;
    }
}

- (uint16)crc16:(short)crc val:(uint8)val{
    int poly = 0x1021;
    uint8 cnt;
    for (cnt = 0; cnt < 8; cnt++, val <<= 1) {
        uint8 msb;
        if ((crc & 0x8000) == 0x8000) {
            msb = 1;
        }
        else msb = 0;
        
        crc <<= 1;
        if ((val & 0x80) == 0x80) {
            crc |= 0x0001;
        }
        if (msb == 1) {
            crc ^= poly;
        }
    }
    
    return crc;
}
@end
