//
//  NSMutableData+UMTestString.h
//  ulib
//
//  Created by Aarno Syvänen on 11.10.12.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import <Foundation/Foundation.h>

@interface NSMutableData (UMTestString)

- (void)binaryToBase64;
- (void)stripBlanks;
- (BOOL)blankAtBeginning:(int)start;
- (BOOL)blankAtEnd:(int)end;


@end
