//
//  HJYBLE.m
//  FindOADVersion
//
//  Created by LunaticMe on 14-7-19.
//  Copyright (c) 2014年 JinyouHu. All rights reserved.
//

#import "SPBLE.h"
@implementation SPBLE

+ (SPBLE *)shareBLE
{
    static SPBLE *shareBle ;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareBle = [[SPBLE alloc] init];
    });
    return shareBle;
}


+(void)writeCharacteristic:(CBPeripheral *)peripheral sCBUUID:(CBUUID *)sCBUUID cCBUUID:(CBUUID *)cCBUUID data:(NSData *)data {
        // Sends data to BLE peripheral to process HID and send EHIF command to PC
    for ( CBService *service in peripheral.services ) {
        if ([service.UUID isEqual:sCBUUID]) {
            for ( CBCharacteristic *characteristic in service.characteristics ) {
                if ([characteristic.UUID isEqual:cCBUUID]) {
                    /* EVERYTHING IS FOUND, WRITE characteristic ! */
                    [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                    
                }
            }
        }
    }
}

+(void)setNotificationForCharacteristic:(CBPeripheral *)peripheral sCBUUID:(CBUUID *)sCBUUID cCBUUID:(CBUUID *)cCBUUID enable:(BOOL)enable {
    for ( CBService *service in peripheral.services ) {
        if ([service.UUID isEqual:sCBUUID]) {
            for (CBCharacteristic *characteristic in service.characteristics ) {
                if ([characteristic.UUID isEqual:cCBUUID])
                {
                    /* Everything is found, set notification ! */
                    [peripheral setNotifyValue:enable forCharacteristic:characteristic];
                    
                }
                
            }
        }
    }
}

+(void)writeNoResponseCharacteristic:(CBPeripheral *)peripheral sCBUUID:(CBUUID *)sCBUUID cCBUUID:(CBUUID *)cCBUUID data:(NSData *)data {
        // Sends data to BLE peripheral to process HID and send EHIF command to PC
    for ( CBService *service in peripheral.services ) {
        if ([service.UUID isEqual:sCBUUID]) {
            for ( CBCharacteristic *characteristic in service.characteristics ) {
                if ([characteristic.UUID isEqual:cCBUUID]) {
                    /* EVERYTHING IS FOUND, WRITE characteristic ! */
                    [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
                }
            }
        }
    }
}


@end
