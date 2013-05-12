//
//  AppDelegate.m
//  Keygen
//
//  Copyright (c) 2013 danielv. All rights reserved.
//

#import "AppDelegate.h"
#import "SerialKeyGenerator.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
}


#pragma mark - 
#pragma mark actions

- (IBAction)generate:(id)sender {

	[_serialsListTextView setString:@""];
	
	if(_secretKeyTextField.stringValue.length == 0) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:@"No secret was set"];
		[alert beginSheetModalForWindow:_window modalDelegate:nil didEndSelector:nil contextInfo:nil];
		return;
	}


	SerialKeyGenerator *skg = [SerialKeyGenerator serialKeyGeneratorWithSecret:[_secretKeyTextField stringValue]];
	NSUInteger count = [_serialCountTextField integerValue];
	NSUInteger start = [_startSequenceTextField integerValue];
	UInt32 data = (UInt32)[_dataTextField integerValue];
	NSArray *serials = [skg generateSerials:count start:start data:data];
	
	for (NSString *s in serials) {
		[[[_serialsListTextView textStorage] mutableString] appendString:[NSString stringWithFormat:@"%@\n", s]];

	}
	[[_serialsListTextView textStorage] setFont:[NSFont fontWithName:@"Menlo" size:14]];
	
}

- (void)controlTextDidChange:(NSNotification *)notification {

	NSString *secret = [_secretKeyTextField stringValue];
	NSString *serial = [_serialTextField stringValue];
	SerialKeyGenerator *skg = [SerialKeyGenerator serialKeyGeneratorWithSecret:secret];
	id<SerialKeyInfo> serialInfo = [skg decodeSerial:serial];
	if(serialInfo == NULL) {
		[_invalidSerialTextField setHidden:false];
		[_decodedSequenceTextField setStringValue:@""];
		[_decodedDataTextField setStringValue:@""];
		[_decodedDateTextField setStringValue:@""];
		return;
	}
	
	[_invalidSerialTextField setHidden:true];
	
	[_decodedSequenceTextField setIntegerValue:[serialInfo sequence]];
	[_decodedDataTextField setIntegerValue:[serialInfo data]];
	[_decodedDateTextField setStringValue:[serialInfo.date description]];

}

@end
