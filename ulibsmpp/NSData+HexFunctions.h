//
//  NSData+HexFunctions.h
//  UniversalSMSUtilitites
//
//  Created by Andreas Fink on 27.02.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#if 0

#import <Foundation/Foundation.h>
#import <ulibsmpp/NSString+HexFunctions.h>


@interface NSData (DataHexFunctions)

- (NSString *) smppGsmHexString;
- (NSString *) smppHexString;
+ (NSData *) smppUnhexFromString:(NSString *)str;
- (NSData *) smppUnhex;

- (NSString *) smppStringFromGsm7withNibbleLengthPrefix;
- (NSString *) smppStringFromGsm7:(int)nibblelen;
- (NSString *) smppStringFromGsm8;
- (NSMutableData *) smppGsm7to8:(int)nibblelen;	/* Note: the 7 bit presentation always have a 'length' byte in nibbles in front */
- (NSMutableData *) smppGsm8to7:(int *)nibblelen;
- (NSMutableData *) smppGsm8to7withNibbleLengthPrefix;
@end


#endif
