//
//  UMSigAddr.m
//  UniversalSMSUtilitites
//
//  Created by Andreas Fink on 27.02.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import "UMSigAddr.h"
#import "NSString+HexFunctions.h"
#import "NSData+HexFunctions.h"
#import <ulibsms/ulibsms.h>

static int is_all_digits(NSString *str, int startpos);

@implementation UMSigAddr
@synthesize		ton;
@synthesize		npi;
@synthesize		addr;
@synthesize     debugString;

- (UMSigAddr *) initWithString: (NSString *)digits
{
    self=[super init];
    if(self)
    {	
        if(digits == nil)
        {
            _addr = @"";
            _ton = 0;
            _npi = 0;
        }
        else if([digits length] < 2)
        {
            _addr = @"";
            _ton = 0;
            _npi = 0;
        }
        else if ([digits compare:@"+" options:NSLiteralSearch range:NSMakeRange(0,1)] == NSOrderedSame )
        {
            _addr = [digits substringFromIndex:1];
            _ton = UMTON_INTERNATIONAL;
            _npi = UMNPI_ISDN_E164;
        }
        
        else if(([digits length] >= 2) && ( [digits compare:@"00" options:NSLiteralSearch  range:NSMakeRange(0,2)] == NSOrderedSame ))
        {
            _addr = [digits substringFromIndex:2];
            _ton = UMTON_INTERNATIONAL;
            _npi = UMNPI_ISDN_E164;
        }
        else if ( [digits compare:@"0" options:NSLiteralSearch range:NSMakeRange(0,1)] == NSOrderedSame )
        {
            _addr = [digits substringFromIndex:1];
            _ton = UMTON_NATIONAL;
            _npi = UMNPI_ISDN_E164;
        }
        else if ([digits isEqualToString:@":EMPTY:"])
        {
            _addr = @":EMPTY:";
            _ton = UMTON_EMPTY;
            _npi = UMNPI_UNKNOWN;
        }
        else if ([digits compare:@":" options:NSLiteralSearch range:NSMakeRange(0,1)] == NSOrderedSame )
        {
            int aton;
            int anpi;
            
            char number[257];
            char numstr[257];
            memset(number,0,sizeof(number) );
            memset(numstr,0,sizeof(numstr));
            strncpy(numstr,[digits UTF8String],(sizeof(numstr)-1));
            
            /* this should do somehting like this sscanf(numstr,":%d:%d:%s",&aton,&anpi,number);
                but it should be safe to have additional : in the remaining string part */
            size_t i=0;
            size_t n=strlen(numstr);
            size_t colon_pos[3];
            int colon_index=0;
            
            for(i=0;i<n;i++)
            {
                if(numstr[i]==':')
                {
                    colon_pos[colon_index++] = i;
                    if (colon_index >=3)
                    {
                        break;
                    }
                }
            }
            if(colon_index < 3)
            {
                _addr = @":EMPTY:";
                _ton = UMTON_EMPTY;
                _npi = UMNPI_UNKNOWN;
               return self;
            }
            numstr[colon_pos[1]]='\0';
            numstr[colon_pos[2]]='\0';
            aton = atoi(&numstr[colon_pos[0]+1]);
            anpi = atoi(&numstr[colon_pos[1]+1]);
            strncpy(number,&numstr[colon_pos[2]+1],(sizeof(number)-1));
            
            _ton = aton % 8;
            _npi = anpi % 16;
            size_t len = strlen(number);
            if(_ton==UMTON_ALPHANUMERIC)
            {
                _addr = [[NSString alloc] initWithBytes:number length:len encoding:(NSUTF8StringEncoding)];

            }
            else
            {
                size_t j=0;
                if(len >= sizeof(number))
                {
                    len = sizeof(number)-1;
                }
                for(i=0;i<len;i++)
                {
                    switch(number[i])
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
                            number[j++]=number[i];
                            break;
                        case 'A':
                        case 'a':
                            number[j++]='A';
                            break;
                        case 'B':
                        case 'b':
                            number[j++]='B';
                            break;
                        case 'C':
                        case 'c':
                            number[j++]='C';
                            break;
                        case 'D':
                        case 'd':
                            number[j++]='D';
                            break;
                        case 'E':
                        case 'e':
                            number[j++]='E';
                            break;
                        case 'F':
                        case 'f':
                            number[j++]='F';
                            break;
                        default:
                            break;
                    }
                }
                number[j] = '\0';
                _addr = @(number);
            }
        }
        else
        {
            if(is_all_digits(digits, 0)==0)
            {
                _ton = UMTON_ALPHANUMERIC;
                _npi = UMNPI_UNKNOWN;
                _addr = [[[digits gsm8]gsm8to7withNibbleLengthPrefix]hexString];
            }
            else
            {
                _ton = UMTON_INTERNATIONAL;
                _npi = UMNPI_ISDN_E164;
                _addr = digits;
            }
        }
    }
	return self;
}

-(UMSigAddr *) initWithInternationalString: (NSString *)digits
{
	if ([digits characterAtIndex:0] == '+') 
	{
		_addr = [digits substringFromIndex:1];
	}
	else
	{
		_addr = digits;
	}
	_ton = UMTON_INTERNATIONAL;
	_npi = UMNPI_ISDN_E164;
	return self;
}

-(UMSigAddr *) initWithAlpha: (NSString *)digits
{	
    _addr = digits;
	_ton = UMTON_ALPHANUMERIC;
	_npi = UMNPI_UNKNOWN;
	return self;
}

-(UMSigAddr *) initWithPackedAlpha: (NSData *)digits
{	
	
	if( digits.length)
	{
		_ton = UMTON_ALPHANUMERIC;
		_npi = UMNPI_UNKNOWN;
		_addr = @"";
		return self;
	}
	_ton = UMTON_ALPHANUMERIC;
	_npi = UMNPI_UNKNOWN;
	_addr = [digits stringFromGsm7withNibbleLengthPrefix];
	return self;
}

- (NSString *)asString
{
	return [self asString:1];
}

- (NSData *)asPackedAlpha
{
	return [_addr gsm7WithNibbleLenPrefix];
}

- (NSString *)asString:(int)formatType	/* 0 = no prefix, 1 = with + for international/0 for national, 2 = with 00 for international /0 for national */
{
	if(_addr==nil)
    {
		return @"";
    }
    switch(_ton)
	{
		case UMTON_UNKNOWN:
            return [NSString stringWithFormat:@"%@", _addr];
            break;
		case UMTON_INTERNATIONAL:
			switch(formatType)
		{
			case 2:
				return [NSString stringWithFormat:@"00%@", _addr];
			case 1:
				return [NSString stringWithFormat:@"+%@", _addr];
			case 0:
			default:
				return [NSString stringWithString: _addr];
		}
			break;
		case UMTON_NATIONAL:
			switch(formatType)
		{
			case 2:
				return [NSString stringWithFormat:@"0%@" ,_addr];
			case 1:
				return [NSString stringWithFormat:@"0%@" ,_addr];
			case 0:
			default:
				return [NSString stringWithString:_addr];
		}
            break;
            
		default:
            return [NSString stringWithFormat:@":%d:%d:%@" ,_ton,_npi,_addr];
			break;
	}
}

- (UMSigAddr *) copyWithZone:(NSZone *)zone
{
    UMSigAddr *a = [[UMSigAddr alloc]initWithSigAddr:self];
    return a;
}

- (UMSigAddr *) initWithSigAddr: (UMSigAddr *)original
{
    if((self=[super init]))
    {
        _ton = original.ton;
        _npi = original.npi;
        _pointcode  = original.pointcode;
        _addr = original.addr;
        _debugString = original.debugString;
    }
	return self;
}

- (NSString *)asUrlEncodedString
{
	return [[self asString:1] urlencode];
}

+ (UMSigAddr *) sigAddrFromString:(NSString *)digits
{
	UMSigAddr *s;
	s = [[UMSigAddr alloc] initWithString:digits];
	return s;
}


- (UMSigAddr *) randomize
{
	UMSigAddr *s;
	s = [[UMSigAddr alloc] init];
	[s setTon:_ton];
	[s setNpi:_npi];
	[s setAddr: [_addr randomize]];
	return s;
}

- (NSString *)description
{
    NSMutableString *desc = [[NSMutableString alloc]init];
    [desc appendFormat:@"SigAddr { TON=%d, NPI=%d, ADDR=%@} =%@",_ton,_npi,_addr,[self asString:1]];
    return desc;
}


- (void) processBeforeEncode
{
    [super processBeforeEncode];
    [_asn1_tag setTagIsConstructed];
    _asn1_list = [[NSMutableArray alloc]init];

    UMASN1Integer *i = [[UMASN1Integer alloc]initWithValue:_ton];
    i.asn1_tag.tagNumber = 1;
    i.asn1_tag.tagClass = UMASN1Class_ContextSpecific;
    [_asn1_list addObject:i];

    i = [[UMASN1Integer alloc]initWithValue:_npi];
    i.asn1_tag.tagNumber = 2;
    i.asn1_tag.tagClass = UMASN1Class_ContextSpecific;
    [_asn1_list addObject:i];

    if(_pointcode)
    {
        UMASN1Integer *i = [[UMASN1Integer alloc]initWithValue:_pointcode.intValue];
        i.asn1_tag.tagNumber = 3;
        i.asn1_tag.tagClass = UMASN1Class_ContextSpecific;
        [_asn1_list addObject:i];
    }
    if(_addr)
    {
        UMASN1UTF8String* i = [[UMASN1UTF8String alloc]initWithValue:_addr];
        i.asn1_tag.tagNumber = 4;
        i.asn1_tag.tagClass = UMASN1Class_ContextSpecific;
        [_asn1_list addObject:i];
    }
    if(_debugString)
    {
        UMASN1UTF8String *i = [[UMASN1UTF8String alloc]initWithValue:_debugString];
        i.asn1_tag.tagNumber = 101;
        i.asn1_tag.tagClass = UMASN1Class_ContextSpecific;
        [_asn1_list addObject:i];
    }
}

- (UMSigAddr *) processAfterDecodeWithContext:(id)context
{
    int p=0;
    UMASN1Object *o = [self getObjectAtPosition:p++];
    while(o)
    {
        if((o) && (o.asn1_tag.tagNumber == 1) && (o.asn1_tag.tagClass == UMASN1Class_ContextSpecific))
        {
            UMASN1Integer *i1 = [[UMASN1Integer alloc]initWithASN1Object:o context:context];
            _ton = (UMTonType)i1.value;
            o = [self getObjectAtPosition:p++];
        }
        else if((o) && (o.asn1_tag.tagNumber == 2) && (o.asn1_tag.tagClass == UMASN1Class_ContextSpecific))
        {
            UMASN1Integer *i1 = [[UMASN1Integer alloc]initWithASN1Object:o context:context];
            _npi = (UMNpiType) i1.value;
            o = [self getObjectAtPosition:p++];
        }
        else if((o) && (o.asn1_tag.tagNumber == 3) && (o.asn1_tag.tagClass == UMASN1Class_ContextSpecific))
        {
            UMASN1Integer *i1 = [[UMASN1Integer alloc]initWithASN1Object:o context:context];
            _pointcode = @((int)i1.value);
            o = [self getObjectAtPosition:p++];
        }
        if((o) && (o.asn1_tag.tagNumber == 4) && (o.asn1_tag.tagClass == UMASN1Class_ContextSpecific))
        {
            UMASN1UTF8String *u1 = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
            _addr = u1.stringValue;
            o = [self getObjectAtPosition:p++];
        }
        if((o) && (o.asn1_tag.tagNumber == 101) && (o.asn1_tag.tagClass == UMASN1Class_ContextSpecific))
        {
            UMASN1UTF8String *u1 = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
            _debugString = u1.stringValue;
            o = [self getObjectAtPosition:p++];
        }

    }
    return self;
}

- (NSString *) objectName
{
    return @"SigAddr";
}
- (id) objectValue
{
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    dict[@"ton"] = @(_ton);
    dict[@"npi"] = @(_npi);
    if(_pointcode)
    {
        dict[@"_pointcode"] = _pointcode;
    }
    if(_addr)
    {
        dict[@"add"] = _addr;
    }
    return dict;
}


@end

static int is_all_digits(NSString *str, int startpos)
{
	size_t i=0;
	size_t len=0;
	const char *c = [str UTF8String];
	len = strlen(c);
	for(i=startpos;i<len;i++)
	{
		switch(c[i])
		{
			case	'0':
			case	'1':
			case	'2':
			case	'3':
			case	'4':
			case	'5':
			case	'6':
			case	'7':
			case	'8':
			case	'9':
				break;
			default:
				return 0;
		}
	}
	return 1;
}



