//
//  SPBLEOADManager.h
//  GardenApp
//
//  Created by 史庆帅 on 2016/12/14.
//  Copyright © 2016年 xhoogee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "oad.h"
#import "SPBLE.h"
#define OADService @"F000FFC0-0451-4000-B000-000000000000"
#define OADConfigService @"CCC0"
#define OADConfigWriteCharacter @"CCC2"
#define OADConfigNotifyCharacter @"CCC1"
#define OADFFC1 @"F000FFC1-0451-4000-B000-000000000000"
#define OADFFC2 @"F000FFC2-0451-4000-B000-000000000000"
@class SPBLEOADUpdater;
@protocol SPBLEOADUpdaterDelegate <NSObject>
- (NSData *)updatedImage;

- (CBPeripheral *)updatedPeripheral;

- (void)updater:(SPBLEOADUpdater *)updater progress:(CGFloat)progress;

@end
@interface SPBLEOADUpdater : NSObject
@property (nonatomic, weak) id<SPBLEOADUpdaterDelegate> delegate;


/**
 升级前的配置，打开相关特征值的通知

 @param peripheral 设备
 @param characteristic 特征
 */
- (void)configWithPeripheral:(CBPeripheral *)peripheral characteristics:(CBCharacteristic *)characteristic;


/**
 配置升级参数（设计到升级速度）
 */
- (void)configUpdateParams;


/**
 @return 升级参数信息
 */
- (NSData *)configData;

/**
 开始升级
 */
- (void)startUpdate;


/**
 @return Image 元数据
 */
- (NSData *)metadata;


/**
 处理蓝牙设备的响应信息

 @param data 响应信息
 @param peripheral 设备
 @param characteristic 特征
 */
- (void)dealWithNotifyValue:(NSData *)data peripheral:(CBPeripheral *)peripheral characteristics:(CBCharacteristic *)characteristic;


/**
 @return Image Block的总数
 */
- (int)nBlocks;


/**
 @return Image 字节数
 */
- (int)nBytes;

@end
