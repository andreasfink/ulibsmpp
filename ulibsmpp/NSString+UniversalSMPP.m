//
//  NSString+UniversalSMPP
//  ulibsmpp
//
//  Created by Andreas Fink on 23.10.12.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland all rights reserved.
//

#import <ulibsmpp/NSString+UniversalSMPP.h>
#include <stdlib.h>
#include <string.h>

@implementation NSString(UniversalSMPP)

- (int) checkRange:(NSRange)range withFunction:(range_func_t2)filter
{
    long end = range.location + range.length;
    long pos;
    
    if (range.location >= [self length])
        return 1;
    if (end > [self length])
        end = [self length];
    
    pos = range.location;
    for ( ; pos < end; pos++)
    {
        if (!filter([self characterAtIndex:pos]))
            return 0;
    }
    
    return 1;
}

- (long) integer16Value
{
    long number;
    char *endptr;
    
    int eno = 0;
    number = strtol([self UTF8String], &endptr, 16);
    eno = errno;
    if (eno == ERANGE)
    {
        return -1;
    }
    return number;
}

- (BOOL)hasOnlyDecimalDigits
{
    const char *c = [self UTF8String];
    size_t len = strlen(c);
    size_t i;
    for(i=0;i<len;i++)
    {
        switch(c[i])
        {
            case '0':
            case '1':
            case '2':
            case '3':
            case '4':
            case '5':
            case '6':
            case '7':
            case '8':
            case '9':
            break;
            default:
            return NO;
        }
    }
    return YES;
}

-(BOOL)hasOnlyHexDigits
{
    {
        const char *c = [self UTF8String];
        size_t len = strlen(c);
        size_t i;
        for(i=0;i<len;i++)
        {
            switch(c[i])
            {
                case '0':
                case '1':
                case '2':
                case '3':
                case '4':
                case '5':
                case '6':
                case '7':
                case '8':
                case '9':
                case 'a':
                case 'A':
                case 'b':
                case 'B':
                case 'c':
                case 'C':
                case 'd':
                case 'D':
                case 'e':
                case 'E':
                    break;
                default:
                    return NO;
            }
        }
        return YES;
    }

}

@end

