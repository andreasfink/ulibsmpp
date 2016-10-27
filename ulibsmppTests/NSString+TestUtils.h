//
//  NSString+TestUtils.h
//  ulibsmpp
//
//  Created by Aarno Syvänen on 03.10.12.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import <Foundation/Foundation.h>

#define	MAXADDRLEN		31

@class SigAddr;

@interface NSString (TestUtils)

- (void) toSigAddr:(SigAddr *)s useDefaultInternational:(BOOL)default_to_international;
- (int) isAllDigitsFrom:(int)startpos;
- (int) pack7bit;
- (void) binaryToHexWithUppercase:(int)uppercase;

@end
