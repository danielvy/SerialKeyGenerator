//
//  SerialKeyGenerator.m
//
//  Copyright (c) 2012 danielv. All rights reserved.
//

#import "SerialKeyGenerator.h"
#import <CommonCrypto/CommonDigest.h>
#import "skipjack.h"

#if __has_feature(objc_arc)
# define SKGRelease(obj)
# define SKGAutorelease(obj) (obj)
# define SKGRetain(obj) (obj)
#else
# define SKGRelease(obj) [(obj) release]
# define SKGAutorelease(obj) [(obj) autorelease]
# define SKGRetain(obj) [(obj) retain]
#endif


// interface and implementation for SerialKeyInfo protocol
@interface SerialKeyInfoObject : NSObject <SerialKeyInfo> 
@end

@implementation SerialKeyInfoObject
@synthesize date = _date, sequence = _sequence, data = _data;


+(id)serialKeyInfoObjectWithDate:(NSDate *)theDate sequence:(UInt32)theSequence data:(UInt32)theData {
	return SKGAutorelease([[self alloc] initWithDate:theDate sequence:theSequence data:theData]);
}

-(id)initWithDate:(NSDate *)theDate sequence:(UInt32)theSequence data:(UInt32)theData {
	self = [super init];
	if (self) {
		_date = SKGRetain(theDate);
		_sequence = theSequence;
		_data = theData;
	}
	return self;

}

#if !__has_feature(objc_arc)
-(void)dealloc {
	[_date release];
 [super dealloc];
}
#endif

@end


// SerialKeyGenerator implementation
@implementation SerialKeyGenerator {
@private
	NSString *_secret;
	Byte _keyTable[10][256];
}


// alphabet to be used in final serial key string
static NSString const * alphabet = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

// generate SHA256 hash from string
- (NSData *)sha256:(NSString *)s {
	NSData* data = [s dataUsingEncoding:NSUTF8StringEncoding];
	unsigned char hash[CC_SHA256_DIGEST_LENGTH];
  if ( CC_SHA256([data bytes], (unsigned int)[data length], hash) ) {
		NSData *sha256 = [NSData dataWithBytes:hash length:CC_SHA256_DIGEST_LENGTH];
		return sha256;
	}
	return nil;
}

// add zero characters to the left of string
- (NSString *)padLeftZeros:(NSString *)source {
	if([source length] >= 25)
		return source;
	return [NSString stringWithFormat:@"%@%@", [@"" stringByPaddingToLength:25 - [source length] withString: @"0" startingAtIndex:0], source];
}


// convert NSData to a base36 string representing the data
- (NSString *)dataToBase36String:(NSData *)data {

	NSDecimalNumber *number = [NSDecimalNumber zero];
	NSDecimalNumber *x;
	
	const char *bytes = [data bytes];
	
	NSMutableString *base36 = [NSMutableString stringWithString:@""];

	
	// create a NSDecimalNumber from the bytes in data
	NSUInteger len = [data length];
	for(NSInteger i = 0; i < len; i++) {
		// 256
		x = (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:256];
		// 256 ^  (len - i - 1)
		x = [x decimalNumberByRaisingToPower:(len - i - 1)];
		// bytes[i] * 256 ^ (len - i - 1)
		x = [x decimalNumberByMultiplyingBy:(NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:(unsigned char)bytes[i]]];
		// sum the number
		number = [number decimalNumberByAdding:x];
	}

	// do some math with NSDecimalNumber's to calculate the remainder and quotient
	NSDecimalNumber *divisor = (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:36];
	while([number compare:[NSDecimalNumber zero]] == NSOrderedDescending) {
		NSDecimalNumber *quotient = [number decimalNumberByDividingBy:divisor withBehavior:[NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundDown scale:0 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO]];

		NSDecimalNumber *subtractAmount = [quotient decimalNumberByMultiplyingBy:divisor];

		NSInteger remainder = [[number decimalNumberBySubtracting:subtractAmount] integerValue];

		number = quotient;
		
		// now the remainder can be converted to characters and added in the beggining of our base36 string
		unichar c = [alphabet characterAtIndex:remainder];
		[base36 insertString:[NSString stringWithCharacters:&c length:1] atIndex:0];
	}
	
	return base36;
}


// convert base36 string to data
- (NSData *)base36StringToData:(NSString *)base36 {
	NSDecimalNumber *number = [NSDecimalNumber zero];
	NSDecimalNumber *x;
	NSUInteger len = [base36 length];
	for(NSInteger i = len - 1; i >= 0; i--) {
		Byte c = (Byte)[base36 characterAtIndex:i];
		if(c >= '0' && c <= '9')
			c -= '0';
		else
			c = c - 'A' + 10;

		// 36
		x = (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:36];
		// 36 ^ i */
		x = [x decimalNumberByRaisingToPower:(len - i - 1)];
		// alphabet[i] * 36 ^ (len - i - 1)
		x = [x decimalNumberByMultiplyingBy:(NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:c]];
		number = [number decimalNumberByAdding:x];
		
	}
	
	NSMutableData *data = [NSMutableData data];
	
	// now convert the NSDecimalNumber to base 16 bytes
	NSDecimalNumber *divisor = (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:256];
	while([number compare:[NSDecimalNumber zero]] == NSOrderedDescending) {

		NSDecimalNumber *quotient = [number decimalNumberByDividingBy:divisor withBehavior:[NSDecimalNumberHandler
				decimalNumberHandlerWithRoundingMode:NSRoundDown scale:0 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO]];

		NSDecimalNumber *subtractAmount = [quotient decimalNumberByMultiplyingBy:divisor];

		Byte remainder = (Byte)[[number decimalNumberBySubtracting:subtractAmount] integerValue];

		number = quotient;

		[data appendBytes:&remainder length:1];
	}
	
	// now just need to reverse the order of bytes
	NSMutableData *rightData = [NSMutableData data];
	len = [data length];
	const void *bytes =	[data bytes];
	for (NSInteger i = len - 1; i >= 0; i--) {
		[rightData appendBytes:&bytes[i] length:1];
	}

	return (NSData *)rightData;
}


+(id)serialKeyGeneratorWithSecret:(NSString *)theSecret {
	return SKGAutorelease([[self alloc] initWithSecret:theSecret]);
}

-(id)initWithSecret:(NSString *)theSecret {
	self = [super init];
	if (self) {
		_secret = SKGRetain(theSecret);
		// hash the encryption key
		NSData *keyHash = [self sha256:_secret];
		Byte keyBytes[10];
		// we only need 10 bytes
		[keyHash getBytes:keyBytes length:10];
		
		// make the key table
		makeKey(keyBytes, _keyTable);
		
	}
	return self;

}

-(NSString *)generateSerialWithSequence:(UInt32)seq data:(UInt32)data {
	
	Byte input[16];
	Byte encoded[16];

	// zero the input
	for(NSUInteger i = 0; i < 16; i++) {
		input[i] = 0;
	}

	// add the identifiers
	input[0] = 0xAA;
	input[15] = 0xAA;

	// add random bytes
	input[1] = arc4random_uniform(256);
	input[14] = arc4random_uniform(256);
	
	// add 4 bytes of the sequence to first bytes 2-5
	for(NSUInteger i = 0; i < 4; i++) {
		input[2 + i] = (seq >> ((7 - i) * 8)) & 0xFF;
	}


	// add 4 bytes of user data to bytes 6-9
	for(NSUInteger i = 0; i < 4; i++) {
		input[6 + i] = (data >> ((7 - i) * 8)) & 0xFF;
	}

	// get the current date/time, convert to 32 but and stick it into bytes 10-13
	NSDate *now = [NSDate date];
	UInt32 ti = (UInt32)[now timeIntervalSince1970];
	for(NSUInteger i = 0; i < 4; i++) {
		input[10 + i] = (ti >> ((7 - i) * 8)) & 0xFF;
	}
	

	// encode the first block (8 first bytes)
	skip_encrypt(_keyTable, &input[0], &encoded[0]);
	
	//	because the last 8 bytes are the date, they might be the same for a sequence,
	//	so XOR them with the encoded first 8 bytes
	for(NSUInteger i = 0; i < 8; i++) {
		input[8 + i] ^= encoded[i];
	}
	
	// encode the second block (8 last bytes)
	skip_encrypt(_keyTable, &input[8], &encoded[8]);
		

	// encoded is now a 16 bytes long crypted byte array, make base36
	NSString *base36 = [self dataToBase36String:[NSData dataWithBytes:encoded length:sizeof(encoded)]];
	// ensure 25 chars
	base36 = [self padLeftZeros:base36];

	// add some dashes after every 5 chars
	NSMutableString *mBase36 = [NSMutableString stringWithString:base36];
	for (NSInteger i = 4; i > 0; i--) {
		[mBase36 insertString:@"-" atIndex:5 * i];
	}
			
	return (NSString *)mBase36;
}


// generate a list of serials with start sequence
-(NSArray *)generateSerials:(NSUInteger)count start:(NSUInteger)start data:(UInt32)data {

	NSMutableArray *serials = [NSMutableArray arrayWithCapacity:count];
	for (UInt32 i = (UInt32)start; i < start + count; i++) {
		NSString *serial = [self generateSerialWithSequence:i data:data];
		[serials addObject:serial];
	}
	return serials;
}


// decode serial string and return SerialKeyInfo 
-(id<SerialKeyInfo>)decodeSerial:(NSString *)serial {

	// validate the serial and copy the needed parts 
	serial = [serial stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	serial = [serial uppercaseString];
	NSMutableString *s = [NSMutableString stringWithString:@""];
	for (NSInteger i = 0; i < [serial length]; i++) {
		unichar c = [serial characterAtIndex:i];
		if((c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')) {
			[s appendFormat:@"%c", c];
		} else if (c == '-' | c == ' ') {
			continue;
		} else {
			// wrong character in serial
			return NULL;
		}
	}

	// convert base36 string to data and then to 16 bytes
	NSData *data = [self base36StringToData:s];
	NSUInteger len = [data length];
	Byte encoded[len];
	[data getBytes:&encoded length:len];
	
	Byte decoded[16];
	
	// decode the second block
	skip_decrypt(_keyTable, &encoded[8], &decoded[8]);
	
	
	// XOR the second block with the encoded first block
	for(NSUInteger i = 0; i < 8; i++) {
		decoded[8 + i] ^= encoded[i];
	}
	// decode the first block
	skip_decrypt(_keyTable, &encoded[0], &decoded[0]);

	// 'decoded' now contains the plain 16 byte data
	//	If the first and last bytes aren't 'AA', it is invalid

	if(decoded[0] != 0xAA || decoded[15] != 0xAA)
		return NULL;


	// the sequence number
	UInt32 seq = 0;
	for(int i = 0; i < 4; i++) {
		seq = (seq << 8) | decoded[2 + i];
	}
	
	// user data
	UInt32 userData = 0;
	for(int i = 0; i < 4; i++) {
		userData = (userData << 8) | decoded[6 + i];
	}

	
	// assemble the date
	UInt32 ti = 0;
	for(int i = 0; i < 4; i++) {
		ti = (ti << 8) | decoded[10 + i];
	}
	
		
	// if it's in the future (more than a day), it doesn't make sense
	NSDate *now = [NSDate date];
	if(ti > [now timeIntervalSince1970] + 60 * 60 * 24)
		return NULL;
	
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)ti];
	
	SerialKeyInfoObject *serialObj = [SerialKeyInfoObject serialKeyInfoObjectWithDate:date sequence:seq data:userData];
	return serialObj;
}



@end
