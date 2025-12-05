//
//  NSString+ulibsmpp
//  ulibsmpp
//
//  Created by Andreas Fink on 23.10.12.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland all rights reserved.
//

#import <ulibsmpp/NSString+ulibsmpp.h>
#include <stdlib.h>
#include <string.h>
#import "GsmCharSet.h"
#import <ulibsmpp/NSData+ulibsmpp.h>

@implementation NSString(ulibsmpp)

- (int) smppCheckRange:(NSRange)range withFunction:(range_func_t2)filter
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

- (long) smppInteger16Value
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

- (BOOL)smppHasOnlyDecimalDigits
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

-(BOOL)smppHasOnlyHexDigits
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

- (NSString *) smppRandomize
{
    NSMutableData *d;
    long i;
    long n;
    unsigned char *b;
    NSString *str;
    
    d = [ NSMutableData dataWithData: [ self dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES ]];
    n = [ d length ];
    b = [ d mutableBytes ];
    for(i=0;i<n;i++)
    {
        if((b[i]=='X') || (b[i]=='x'))
            b[i] = '0' + (rand() % 10);
    }
    str = [[ NSString alloc ] initWithBytes:b length:n encoding:NSASCIIStringEncoding ];
    return str;
    
}


- (NSString *) smppHex
{
    NSMutableString *result;
    long i;
    long n;
    result = [[ NSMutableString alloc]init];
    n = [self length];
    for(i=0;i<n;i++)
    {
        [ result appendFormat:@"%02X",[self characterAtIndex:i ] % 256];
    }
    return result;
}

+ (int)smppNibbleToInt:(char)c
{
    if(c < 16)
        return c;
    switch(c)
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
            return c - '0';
        case 'A':
        case 'a':
            return 0x0A;
        case 'B':
        case 'b':
            return 0x0B;
        case 'C':
        case 'c':
            return 0x0C;
        case 'D':
        case 'd':
            return 0x0D;
        case 'E':
        case 'e':
            return 0x0E;
        case 'F':
        case 'f':
            return 0x0F;
    }
    return 0;
}

- (NSString *) smppUnhex
{
    NSMutableString *result;
    long i;
    long n;
    int a;
    int b;
    unichar c;
    result = [[ NSMutableString alloc]init];
    n = [self length];
    for(i=0;i<n;i+=2)
    {
        a = [NSString smppNibbleToInt:[self characterAtIndex: i]];
        if((i+1) < n)
            b = [NSString smppNibbleToInt:[self characterAtIndex: i+1]];
        else
            b = 0;
        c = (a <<4) | b;
        [ result appendFormat:@"%c",c];
    }
    return result;
}

- (NSData *) smppUnhexData
{
    NSData *result;
    NSMutableData *r = NULL;
    long i;
    long n;
    int a;
    int b;
    unichar c;
    
    
    r = [[ NSMutableData alloc] initWithCapacity: [ self length ]/2];
    n = [self length];
    for(i=0;i<n;i+=2)
    {
        a = [NSString smppNibbleToInt:[self characterAtIndex: i]];
        b = [NSString smppNibbleToInt:[self characterAtIndex: i+1]];
        c = (a <<4) | b;
        [ r appendBytes:&c    length:1 ];
    }
    result = [ NSData dataWithData: r ];
    return result;
}


- (NSMutableData *) smppGsm8
{
    long i;
    long j;
    long n;
    unichar u;
    NSMutableData *result = NULL;
    int16_t    c;
    unsigned char outchar[4];
    
    n = [self length];
    result = [[NSMutableData alloc] init ];
    for(i=0;i<n;i++)
    {
        u = [self characterAtIndex:i];
        c = -1;
        switch(u)
        {
            case '{':
                c = 0x2729;
                break;
            case '}':
                c = 0x2729;
                break;
            case '[':
                c = 0x273C;
                break;
            case '~':
                c = 0x273D;
                break;
            case ']':
                c = 0x273E;
                break;
            case '\\':
                c = 0x272F;
                break;
            case 0x20AC: /* euro symbol */
                c = 0x2765;
                break;
            case '^':
                c = 0x2714;
                break;
            default:
                
                for(j=0;j<256;j++)
                {
                    if(smppGsmToUnicode[j] == u)
                    {
                        c = j;
                        break;
                    }
                }
                break;
        }
        if((c & 0xFF00) == 0x2700)
        {
            outchar[0] = 0x27;
            outchar[1] = c & 0xFF;
            [ result appendBytes:outchar length:2 ];
        }
        else if(c >= 0)
        {
            outchar[0] = c & 0xFF;
            [ result appendBytes:outchar length:1 ];
        }
        else
        {
            outchar[0] = '?';
            [ result appendBytes:outchar length:1 ];
        }
    }
    return result;
}


- (NSMutableData *)smppGsm7WithNibbleLenPrefix
{
    int nibblelen = 0;
    unsigned char b;
    NSMutableData *d;
    NSData *d8 = [self smppGsm8];
    d = [d8 smppGsm8to7:&nibblelen ];
    b = nibblelen & 0xFF;
    [ d replaceBytesInRange:NSMakeRange(0,0) withBytes:&b length:1 ];
    if((b==11) && (d.length > 7))
    {
        return [[NSData dataWithBytes:d.bytes length:7] mutableCopy];
    }
    return d;
}


- (NSMutableData *)smppGsm7:(int *)nibblelen
{
    return [[ self smppGsm8 ] smppGsm8to7:nibblelen ];
}

- (NSMutableData *)smppGsm16
{
    long i;
    long n;
    unichar u;
    NSMutableData *result = NULL;
    unsigned char outchar[4];
    
    n = [ self length ];
    result = [[ NSMutableData alloc] initWithCapacity: ([ self length] * 2) ];
    for(i=0;i<n;i++)
    {
        u = [ self characterAtIndex:i];
        outchar[0] = (u >> 8) & 0xFF;
        outchar[1] = u & 0xFF;
        [ result appendBytes:outchar length:2 ];
    }
    return result;
    
}


#if !defined(LINUX)
- (NSString *)smppUrlencode
{
    // Escape all Reserved characters from rfc 2396 section 2.2 // rfc3986 section 2.3
    // except "/" since that's used explicitly in format strings.
    CFStringRef escapeChars = (CFStringRef)@":/?#[]@!$&'()*+,;=";
    
    return (NSString*)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self, NULL, escapeChars, kCFStringEncodingUTF8));
}
#else
//simple API that encodes reserved characters according to:
//RFC 3986
//http://tools.ietf.org/html/rfc3986
- (NSString *)smppUrlencode
{
    NSArray *escapeChars = [NSArray arrayWithObjects:
                            @";"    , @"/"   , @"?"   , @":"   , @"@"   , @"&"   ,
                            @"="    , @"+"   , @"$"   , @","   , @"["   , @"]"   ,
                            @"#"    , @"!"   , @"'"   , @"("   , @")"   , @"*"   ,
                            @" "    , NULL];
    
    NSArray *replaceChars = [NSArray arrayWithObjects:
                             @"%3B" , @"%2F" , @"%3F" , @"%3A" , @"%40" , @"%26" ,
                             @"%3D" , @"%2B" , @"%24" , @"%2C" , @"%5B" , @"%5D" ,
                             @"%23" , @"%21" , @"%27" ,     @"%28", @"%29" , @"%2A" ,
                             @"+"   , NULL];
    
    NSUInteger len = [escapeChars count];
    
    NSMutableString *temp =  [[ self stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding ] mutableCopy ];
    
    NSUInteger i;
    for(i = 0; i < len; i++)
    {
        
        [temp replaceOccurrencesOfString: [escapeChars objectAtIndex:i]
                              withString: [replaceChars objectAtIndex:i]
                                 options: NSLiteralSearch
                                   range: NSMakeRange(0, [temp length])];
    }
    
    NSString *out = [NSString stringWithString: temp];
    
    return out;
}
#endif

@end

