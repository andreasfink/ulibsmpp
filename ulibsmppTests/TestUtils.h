//
//  TestUtils.h
//  ulibsmpp
//
//  Created by Aarno Syvänen on 14.09.12.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import <Foundation/Foundation.h>

@interface TestUtils : NSObject

+ (void) encodeToNetworkLong:(unsigned char *)data withValue:(unsigned long)value;
+ (int) decodeNetworkLong:(unsigned char *)data;

@end
