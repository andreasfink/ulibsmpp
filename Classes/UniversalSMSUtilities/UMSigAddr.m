//
//  UMSigAddr.m
//  UniversalSMSUtilitites
//
//  Created by Andreas Fink on 27.02.09.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import "UMSigAddr.h"
#import "NSString+HexFunctions.h"
#import "NSData+HexFunctions.h"


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
            self.addr = @"";
            ton = 0;
            npi = 0;
        }
        else if([digits length] < 2)
        {
            self.addr = @"";
            ton = 0;
            npi = 0;
        }
        else if ([digits compare:@"+" options:NSLiteralSearch range:NSMakeRange(0,1)] == NSOrderedSame )
        {
            self.addr = [digits substringFromIndex:1];
            ton = UMTON_INTERNATIONAL;
            npi = UMNPI_ISDN_E164;
        }
        
        else if(([digits length] >= 2) && ( [digits compare:@"00" options:NSLiteralSearch  range:NSMakeRange(0,2)] == NSOrderedSame ))
        {
            self.addr = [digits substringFromIndex:2];
            ton = UMTON_INTERNATIONAL;
            npi = UMNPI_ISDN_E164;
        }
        else if ( [digits compare:@"0" options:NSLiteralSearch range:NSMakeRange(0,1)] == NSOrderedSame )
        {
            self.addr = [digits substringFromIndex:1];
            ton = UMTON_NATIONAL;
            npi = UMNPI_ISDN_E164;
        }
        else if ([digits isEqualToString:@":EMPTY:"])
        {
            addr = @":EMPTY:";
            ton = UMTON_EMPTY;
            npi = UMNPI_UNKNOWN;
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
                addr = @":EMPTY:";
                ton = UMTON_EMPTY;
                npi = UMNPI_UNKNOWN;
               return self;
            }
            numstr[colon_pos[1]]='\0';
            numstr[colon_pos[2]]='\0';
            aton = atoi(&numstr[colon_pos[0]+1]);
            anpi = atoi(&numstr[colon_pos[1]+1]);
            strncpy(number,&numstr[colon_pos[2]+1],(sizeof(number)-1));
            
            ton = aton % 8;
            npi = anpi % 16;
            size_t len = strlen(number);
            if(ton==UMTON_ALPHANUMERIC)
            {
                self.addr = [[NSString alloc] initWithBytes:number length:len encoding:(NSUTF8StringEncoding)];

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
                self.addr = @(number);
            }
        }
        else
        {
            if(is_all_digits(digits, 0)==0)
            {
                ton = UMTON_ALPHANUMERIC;
                npi = UMNPI_UNKNOWN;
                self.addr = [[[digits gsm8]gsm8to7withNibbleLengthPrefix]hexString];
            }
            else
            {
                ton = UMTON_INTERNATIONAL;
                npi = UMNPI_ISDN_E164;
                self.addr = digits;
            }
        }
    }
	return self;
}

-(UMSigAddr *) initWithInternationalString: (NSString *)digits
{
	if ([digits characterAtIndex:0] == '+') 
	{
		[self setAddr: [digits substringFromIndex:1]];
	}
	else
	{
		[self setAddr:digits];
	}
	ton = UMTON_INTERNATIONAL;
	npi = UMNPI_ISDN_E164;
	return self;
}

-(UMSigAddr *) initWithAlpha: (NSString *)digits
{	
	[self setAddr:digits];
	ton = UMTON_ALPHANUMERIC;
	npi = UMNPI_UNKNOWN;
	return self;
}

-(UMSigAddr *) initWithPackedAlpha: (NSData *)digits
{	
	
	if( digits == nil )
	{
		ton = UMTON_ALPHANUMERIC;
		npi = UMNPI_UNKNOWN;
		[self setAddr:@""];
		return self;
	}
	if( [digits length] == 0 )
	{
		ton = UMTON_ALPHANUMERIC;
		npi = UMNPI_UNKNOWN;
		[self setAddr:@""];
		return self;
	}
	
	ton = UMTON_ALPHANUMERIC;
	npi = UMNPI_UNKNOWN;
	[self setAddr: [digits stringFromGsm7withNibbleLengthPrefix]];
	return self;
}

- (NSString *)asString
{
	return [self asString:1];
}

- (NSData *)asPackedAlpha
{
	return [addr gsm7WithNibbleLenPrefix];
}

- (NSString *)asString:(int)formatType	/* 0 = no prefix, 1 = with + for international/0 for national, 2 = with 00 for international /0 for national */
{
	if(addr==nil)
		return @"";
	switch(ton)
	{
		case UMTON_UNKNOWN:
            return [NSString stringWithFormat:@"%@", addr];
            break;
		case UMTON_INTERNATIONAL:
			switch(formatType)
		{
			case 2:
				return [NSString stringWithFormat:@"00%@", addr];
			case 1:
				return [NSString stringWithFormat:@"+%@", addr];
			case 0:
			default:
				return [NSString stringWithString: addr];
		}
			break;
		case UMTON_NATIONAL:
			switch(formatType)
		{
			case 2:
				return [NSString stringWithFormat:@"0%@" ,addr];
			case 1:
				return [NSString stringWithFormat:@"0%@" ,addr];
			case 0:
			default:
				return [NSString stringWithString:addr];
		}
            break;
            
		default:
            return [NSString stringWithFormat:@":%d:%d:%@" ,ton,npi,addr];
//			return [NSString stringWithString:addr];
			break;
	}
}

- (UMSigAddr *) initWithSigAddr: (UMSigAddr *)original
{
    if((self=[super init]))
    {
        ton = [original ton];
        npi = [original npi];
        addr = [[NSString alloc] initWithString: [original addr]];
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
	[s setTon:ton];
	[s setNpi:npi];
	[s setAddr: [addr randomize]];
	return s;
}

- (NSString *)description
{
    NSMutableString *desc = [[NSMutableString alloc]init];
    [desc appendFormat:@"SigAddr { TON=%d, NPI=%d, ADDR=%@} =%@",ton,npi,addr,[self asString:1]];
    return desc;
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


