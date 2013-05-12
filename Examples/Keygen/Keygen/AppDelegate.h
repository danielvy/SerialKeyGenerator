//
//  AppDelegate.h
//  Keygen
//
//  Copyright (c) 2013 danielv. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;


@property (assign) IBOutlet NSTextField *secretKeyTextField;

@property (assign) IBOutlet NSTextField *serialCountTextField;
@property (assign) IBOutlet NSTextField *startSequenceTextField;
@property (assign) IBOutlet NSTextField *dataTextField;

@property (assign) IBOutlet NSTextView *serialsListTextView;


@property (assign) IBOutlet NSTextField *serialTextField;
@property (assign) IBOutlet NSTextField *decodedSequenceTextField;
@property (assign) IBOutlet NSTextField *decodedDataTextField;
@property (assign) IBOutlet NSTextField *decodedDateTextField;

@property (assign) IBOutlet NSTextField *invalidSerialTextField;


- (IBAction)generate:(id)sender;


@end
