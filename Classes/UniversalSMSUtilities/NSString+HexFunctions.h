//
//  NSString+HexFunctions.h
//  UniversalSMSUtilitites
//
//  Created by Andreas Fink on 27.02.09.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import <Foundation/Foundation.h>

@interface NSString (SMSUtilitiesHexFunctions)

+ (int) nibbleToInt:(char)c;
- (NSString *) hex;
- (NSString *) unhex;
- (NSString *) urlencode;
- (NSData *) unhexData;
- (NSMutableData *) gsm16;
- (NSMutableData *) gsm8;
- (NSMutableData *) gsm7:(int *)nibblelen;
- (NSMutableData *) gsm7WithNibbleLenPrefix;
- (NSString *) randomize;

@end
