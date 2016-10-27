//
//  NSData+HexFunctions.h
//  UniversalSMSUtilitites
//
//  Created by Andreas Fink on 27.02.09.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import <Foundation/Foundation.h>
#import "NSString+HexFunctions.h"


@interface NSData (DataHexFunctions)

- (NSString *) gsmHexString;
- (NSString *) hexString;
+ (NSData *) unhexFromString:(NSString *)str;
- (NSData *) unhex;

- (NSString *) stringFromGsm7withNibbleLengthPrefix;
- (NSString *) stringFromGsm7:(int)nibblelen;
- (NSString *) stringFromGsm8;
- (NSMutableData *) gsm7to8:(int)nibblelen;	/* Note: the 7 bit presentation always have a 'length' byte in nibbles in front */
- (NSMutableData *) gsm8to7:(int *)nibblelen;
- (NSMutableData *) gsm8to7withNibbleLengthPrefix;
@end


