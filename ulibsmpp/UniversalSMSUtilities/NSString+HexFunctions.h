//
//  NSString+HexFunctions.h
//  UniversalSMSUtilitites
//
//  Created by Andreas Fink on 27.02.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#if 0
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
#endif
