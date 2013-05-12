//
//  SerialKeyGenerator.h
//
//  Copyright (c) 2012 danielv. All rights reserved.
//
//	Packed format:
//	Byte 0: Identifier, always 0xAA
//	Byte 1:	Random
//	Bytes 2-5: 32 bit sequence
//	Bytes 6-9: 32 bit user data
//	Bytes 10-13: 32 bit date
//	Byte 14: Random
//	Byte 16: Identifier, always 0xAA

#import <Cocoa/Cocoa.h>

@protocol SerialKeyInfo
	@property (nonatomic, readonly) NSDate *date;
	@property (nonatomic, readonly) UInt32 sequence;
	@property (nonatomic, readonly) UInt32 data;
@end


@interface SerialKeyGenerator : NSObject

// return SerialKeyGenerator with given secret
+ (id)serialKeyGeneratorWithSecret:(NSString *)theSecret;

- (id)initWithSecret:(NSString *)theSecret;

// generate serial key with given sequence and data
- (NSString *)generateSerialWithSequence:(UInt32)seq data:(UInt32)data;

// generate multiple <count> serial keys with start sequence and data
- (NSArray *)generateSerials:(NSUInteger)count start:(NSUInteger)start data:(UInt32)data;

// decide a serial key, return object containing parsed data
- (id<SerialKeyInfo>)decodeSerial:(NSString *)serial;

@end
