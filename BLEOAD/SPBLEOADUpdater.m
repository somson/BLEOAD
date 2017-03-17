//
//  SPBLEOADManager.m
//  GardenApp
//
//  Created by 史庆帅 on 2016/12/14.
//  Copyright © 2016年 xhoogee. All rights reserved.
//

#import "SPBLEOADUpdater.h"
#import "SPOADImageMetadata.h"
#define BlocksPerTime 8
@interface SPBLEOADUpdater ()
@property (nonatomic) int nBlocks;
@property (nonatomic) int nBytes;
@property (nonatomic) int iBlocks;
@property (nonatomic) int iBytes;
@property (nonatomic) BOOL isStart;
@property (nonatomic, strong) CBPeripheral *currentPeripheral;
@property (nonatomic, strong) NSData *currentImage;
@property (nonatomic, strong) CBUUID *oadServiceUUID;
@property (nonatomic, strong) CBUUID *oadWriteUUID;
@property (nonatomic, assign) CGFloat progress;

@end

@implementation SPBLEOADUpdater
{
    unsigned char* imageFileData;
    uint8_t *sendData;
}
- (void)startUpdate{
    CBPeripheral *currentPeripheral = [self currentPeripheral];
    NSData *requestData = [self metadata];
    if(currentPeripheral == nil || requestData == nil || [self imageData] == nil){
        return;
    }
    self.currentPeripheral = currentPeripheral;
    self.currentImage = [self imageData];
    NSInteger length = self.currentImage.length;
     imageFileData = (unsigned char*)malloc(length*sizeof(unsigned char));
    [self.currentImage getBytes:imageFileData length:self.currentImage.length];
    sendData = (uint8_t *)malloc((2 + OAD_BLOCK_SIZE)*sizeof(uint8_t));
    _isStart = YES;
    CBUUID *sUUID = [CBUUID UUIDWithString:OADService];
    CBUUID *c1UUID = [CBUUID UUIDWithString:OADFFC1];
    
    CBUUID *c2UUID = [CBUUID UUIDWithString:OADFFC2];
    self.oadServiceUUID = sUUID;
    self.oadWriteUUID = c2UUID;
    [SPBLE writeCharacteristic:currentPeripheral sCBUUID:sUUID cCBUUID:c1UUID data:requestData];
    self.nBlocks = [self nBlocks];
    self.nBytes = [self nBytes];
    self.iBytes = 0;
    self.iBlocks = 0;
}

- (void)configUpdateParams{
    CBPeripheral *currentPeripheral = [self currentPeripheral];
    NSData *requestData = [self configData];
    if(currentPeripheral == nil || requestData == nil){
        return;
    }
    CBUUID *sUUID = [CBUUID UUIDWithString:OADConfigService];
    CBUUID *cUUID = [CBUUID UUIDWithString:OADConfigWriteCharacter];
    [SPBLE writeCharacteristic:currentPeripheral sCBUUID:sUUID cCBUUID:cUUID data:[self configData]];
}
-(void)configWithPeripheral:(CBPeripheral *)peripheral characteristics:(CBCharacteristic *)characteristic{
    if([characteristic.service.UUID.UUIDString isEqualToString:OADService]){
        if([characteristic.UUID.UUIDString isEqualToString:OADFFC1]){
            if(!characteristic.isNotifying){
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        }
        
        if([characteristic.UUID.UUIDString isEqualToString:OADFFC2]){
            if(!characteristic.isNotifying){
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        }
        
        if([characteristic.UUID.UUIDString isEqualToString:OADConfigNotifyCharacter]){
            if(!characteristic.isNotifying){
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        }

    }
}

- (void)dealWithNotifyValue:(NSData *)data peripheral:(CBPeripheral *)peripheral characteristics:(CBCharacteristic *)characteristic{
//    NSLog(@"------------%@",characteristic.UUID);
    if([characteristic.UUID.UUIDString isEqualToString:OADFFC1] && [characteristic.service.UUID.UUIDString isEqualToString:OADService]){
        NSLog(@"~~~~~~~~Notify data = %@",data);
    }
    if([characteristic.UUID.UUIDString isEqualToString:OADConfigNotifyCharacter] && [characteristic.service.UUID.UUIDString isEqualToString:OADConfigService]){
        NSLog(@"~~~~~~~~Notify data = %@",data);
    }
    if([characteristic.UUID.UUIDString isEqualToString:OADFFC2] && [characteristic.service.UUID.UUIDString isEqualToString:OADService]){
        uint16 blocks;
        [data getBytes:&blocks length:2];
//        NSLog(@"---blocks=%u",blocks);
        [self  updateWithOutNoResponse:data];
    }

}

- (void)updateOneBlockWithData:(NSData *)data{
    if(data && _isStart){
        uint16 blocks;
        [data getBytes:&blocks length:2];
        NSLog(@"---blocks=%u",blocks);
        [self writePerBlockWithNumber:1];
    }
}
- (void)updateManyBlocksWithData:(NSData *)data{
    if(data && _isStart){
        if(self.nBlocks!=0){
            //开始更新的时候会执行到这
            uint16 blocks;
            [data getBytes:&blocks length:2];
            NSLog(@"-------Block data = %d",blocks);
            if(blocks % BlocksPerTime == 0 && (self.nBlocks-blocks)>=BlocksPerTime)
                [self writePerBlockWithNumber:BlocksPerTime];
            else if(blocks % BlocksPerTime == 0 && (self.nBlocks-blocks) < BlocksPerTime){
                [self writePerBlockWithNumber:self.nBlocks-blocks];
            }
        }
    }
}

- (void)updateWithOutNoResponse:(NSData *)data{
    static int number = 0;
    if(number == 0){
        if(data && _isStart){
            [self writeBlockWithTimerNumber:BlocksPerTime];
            number = 1;
        }
    }
}

- (void)writeBlockWithTimerNumber:(int)number{
    
    CBPeripheral *currentPeripheral = self.currentPeripheral;
    if(self.currentImage == nil || currentPeripheral == nil){
        return;
    }
    uint8_t* requestData = sendData;
    for(int i = 0; i < number; i++){
        requestData[0] = LO_UINT16(self.iBlocks);
        requestData[1] = HI_UINT16(self.iBlocks);
        memcpy(&requestData[2], &imageFileData[self.iBytes], OAD_BLOCK_SIZE);
        [SPBLE writeNoResponseCharacteristic:currentPeripheral sCBUUID:self.oadServiceUUID cCBUUID:self.oadWriteUUID data:[NSData dataWithBytes:requestData length:(2 + OAD_BLOCK_SIZE)]];
        NSLog(@"%d %d %02hhx",self.iBlocks, self.iBytes, imageFileData[self.iBytes]);
        self.iBlocks ++;
        self.iBytes += OAD_BLOCK_SIZE;
        self.progress = (CGFloat)self.iBlocks / self.nBlocks;
        [self.delegate updater:self progress:self.progress];
        if (self.iBlocks == self.nBlocks) {
            NSLog(@"升级成功");
            _isStart = NO;
            return;
        }
    }
    [NSTimer scheduledTimerWithTimeInterval:0.005 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [self writeBlockWithTimerNumber:BlocksPerTime];
    }];

}
- (void)writePerBlockWithNumber:(int)number{
    NSData *image = [self imageData];
    CBPeripheral *currentPeripheral = [self currentPeripheral];
    if(image == nil || currentPeripheral == nil){
        return;
    }
    uint8_t requestData[2 + OAD_BLOCK_SIZE];
    for(int i = 0; i < number; i++){
        requestData[0] = LO_UINT16(self.iBlocks);
        requestData[1] = HI_UINT16(self.iBlocks);
        memcpy(&requestData[2], &imageFileData[self.iBytes], OAD_BLOCK_SIZE);
        
        CBUUID *sUUID = [CBUUID UUIDWithString:OADService];
        CBUUID *cUUID = [CBUUID UUIDWithString:OADFFC2];
        [SPBLE writeNoResponseCharacteristic:currentPeripheral sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:requestData length:(2 + OAD_BLOCK_SIZE)]];
        self.iBlocks ++;
        self.iBytes += OAD_BLOCK_SIZE;
        self.progress = (float)((float)self.iBlocks / (float)self.nBlocks);
        NSLog(@"Progress:%lf",self.progress);
        NSLog(@"%d %d %d %d %ld %02hhx",self.iBlocks, self.nBlocks, self.iBytes, self.nBytes, image.length, imageFileData[self.iBytes]);
        if (self.iBlocks == self.nBlocks) {
            NSLog(@"升级成功");
            _isStart = NO;
            return;
        }
    }
//    [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:NO block:^(NSTimer * _Nonnull timer) {
//        [self writePerBlockWithNumber:4];
//    }];
}

- (NSData *)metadata{
    NSData *image = [self imageData];
    if(image == nil){
        return nil;
    }
    unsigned char fileData[image.length];
    [image getBytes:fileData length:image.length];
    uint8_t requestData[OAD_METADATA_SIZE];
    SPOADImageMetadata *metadata = [[SPOADImageMetadata alloc] initWithImageData:image];
    Image_header image_header = metadata.imageHeader;
    requestData[0] = LO_UINT16(image_header.crc0);
    requestData[1] = HI_UINT16(image_header.crc0);
    requestData[2] = LO_UINT16(image_header.crc1);
    requestData[3] = HI_UINT16(image_header.crc1);
    requestData[4] = LO_UINT16(image_header.ver);
    requestData[5] = HI_UINT16(image_header.ver);
    requestData[6] = LO_UINT16(image_header.len);
    requestData[7] = HI_UINT16(image_header.len);
    requestData[8] = requestData[9] = requestData[10] = requestData[11] = image_header.uid[0];
    requestData[12] = LO_UINT16(image_header.address);
    requestData[13] = HI_UINT16(image_header.address);
    requestData[14] = image_header.imgType;
    requestData[15] = image_header.state;
    for(int i = 0; i < OAD_METADATA_SIZE; i++){
        NSLog(@"%02hhx",requestData[i]);
    }
    NSData *data = [NSData dataWithBytes:requestData length:(16)];
    return data;
}

- (int)nBlocks{
    NSData *image = [self imageData];
    if(image == nil){
        return 0;
    }
    SPOADImageMetadata *metadata = [[SPOADImageMetadata alloc] initWithImageData:image];
    return metadata.imageHeader.len / (OAD_BLOCK_SIZE / HAL_FLASH_WORD_SIZE);
}

- (int)nBytes{
    NSData *image = [self imageData];
    if(image == nil){
        return 0;
    }
    SPOADImageMetadata *metadata = [[SPOADImageMetadata alloc] initWithImageData:image];
    return metadata.imageHeader.len * HAL_FLASH_WORD_SIZE;
}
- (NSData *)imageData{
    NSData *imageData = nil;
    if(self.delegate && [self.delegate respondsToSelector:@selector(updatedImage)]){
        imageData = [self.delegate updatedImage];
    }
    return imageData;
}
- (CBPeripheral *)currentPeripheral{
    CBPeripheral *peripheral = nil;
    if(self.delegate && [self.delegate respondsToSelector:@selector(updatedPeripheral)]){
        peripheral = [self.delegate updatedPeripheral];
    }
    return peripheral;
}

- (NSData *)configData{
    uint16_t param[4] = {20,40,4,100};
    uint8_t  config[8];
    for(NSInteger i = 0; i < 4; i++){
        config[i*2] = LO_UINT16(param[i]);
        config[i*2+1] = HI_UINT16(param[i]);
    }
    NSData *data = [NSData dataWithBytes:config length:8];
    NSLog(@"%@",data);
    return data;
}
@end
