//
//  NSData+smppFunctions.h
//  ulibsmpp
//
//  Created by Andreas Fink on 27.02.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//


#import <ulib/ulib.h>
#import <ulibsmpp/NSString+smppFunctions.h>


@interface NSData (smppFunctions)

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

