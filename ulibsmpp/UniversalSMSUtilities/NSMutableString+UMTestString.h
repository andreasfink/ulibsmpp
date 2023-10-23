//
//  NSMutableString+UMTestString.h
//  ulib
//
//  Created by Aarno Syvänen on 11.10.12.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import <ulib/ulib.h>

@interface NSMutableString (UMTestString)

- (void)stripSpaces;
- (void)stripQuotes;
- (BOOL)blankAtBeginning:(int)start;
- (BOOL)blankAtEnd:(int)end;
- (BOOL)spaceAtBeginning:(int)start;
- (BOOL)spaceAtEnd:(int)end;
/* This will convert UTF8 string to base64*/
- (void)binaryToBase64;

@end
