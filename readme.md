
# SerialKeyGenerator #

SerialKeyGenerator is an Objective-C library for Mac OSX for creating and validating serial keys (to be used, for instance, in software licensing). The output is serial keys in the form *XXXXX-XXXXX-XXXXX-XXXXX-XXXXX* made from numbers [0-9] and upper case characters [A-Z] (essentially, a base36 number).

### Features: ###

- Encrypted/decrypted using a secret key with [Skipjack block cipher](http://en.wikipedia.org/wiki/Skipjack_%28cipher%29)
- Serial key contains: date of generation, sequence number and a 32 bit custom data
- Serials keys are randomized
- Supports both ARC and non ARC applications

### Internal packed (unencoded) format ###

	Byte 0: Identifier, always 0xAA
	Byte 1:	Random byte
	Bytes 2-5: 32 bit sequence
	Bytes 6-9: 32 bit user data
	Bytes 10-13: 32 bit date
	Byte 14: Random byte
	Byte 16: Identifier, always 0xAA

# Usage #

Add the following files to your project:

	- skipjack.h
	- skipjack.m
	- SerialKeyGenerator.h
	- SerialKeyGenerator.m

And `#import "SerialKeyGenerator.h"` in your source.

### Generation Sample ###

	NSString *secret = @"mysecret";
	// Create the SerialKeyGenerator with your secret
	SerialKeyGenerator *skg = [SerialKeyGenerator serialKeyGeneratorWithSecret:secret];
	// Set count, start sequence and user data
	NSUInteger count = 50;
	UInt32 start = 1;
	UInt32 data = 0;
	
	// generate ONE serial key with given sequence number and user data
	NSString * serial = [skg generateSerialWithSequence:start data:data];

	// generate a LIST of 50 serial keys with given sequence start number, count and user data
	NSArray *serials = [skg generateSerials:count start:start data:data];
	

### Validation Sample ###

	// don't actually save your secret like this
	NSString *secret = @"mysecret";
	NSString *serial = @"CR70H-64SLH-DY3R1-UDN96-VDK6B";
	// Create the SerialKeyGenerator with your secret
	SerialKeyGenerator *skg = [SerialKeyGenerator serialKeyGeneratorWithSecret:secret];
	// decode the serial and get the info structure
	id<SerialKeyInfo> serialInfo = [skg decodeSerial:serial];

	UInt32 sequence = [serialInfo sequence];
	UInt32 data = [serialInfo data];
	NSString *dateString = [serialInfo.date description];


# About Security #


Skipjack block cipher is not bullet proof and has known attacks (see [wikipedia article on Skipjack](http://en.wikipedia.org/wiki/Skipjack_%28cipher%29))

Another problem is that if the secret key needs to be included in the client software in order to decrypt the entered serial key that makes it potentially susceptible to reverse engineering and discovering your secret key. This is not a problem if you add some online serial validation scheme (not a feature included with this library). But if you include your secret in the client, don't add it as plain text like this:

	NSString *secret = @"mysecretkey";

Rather, try to mangle it a bit. It won't stop a determined hacker but it won't be just plainly seen with a hex editor:

	// create a the secret string: *$#12345abcABC
	NSString *part = @"ABC";
	NSString *secret = [[NSString stringWithFormat:@"%@%i%@%@", @"*$#", 12345, @"abc", part]]; 

Or be creative.

