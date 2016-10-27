//
//  UMPrefs.m
//  UniversalSMSUtilities
//
//  Created by Andreas Fink on 03.03.09.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import "UMPrefs.h"
#include <time.h>


@implementation UMPrefs


+ (int) prefsGetInteger:(NSObject *)obj
{
	return [self prefsGetInteger:obj default:0];
}

+ (int) prefsGetInteger:(NSObject *)obj default:(int)def
{
	NSString	*s;
	NSNumber	*n;
	
	if( obj == nil)
		return def;
	if( [obj isKindOfClass:[NSString class]])
	{
		s = (NSString *) obj;
		return [s intValue];
	}
	else if ([obj isKindOfClass:[NSNumber class]])
	{
		n = (NSNumber *) obj;
		return [n intValue];
	}
	return def;
}

+(double) prefsGetDouble:(NSObject *)obj
{
	return [self prefsGetDouble:obj default:0.0];
}

+ (double) prefsGetDouble:(NSObject *)obj default:(double)def
{
	NSString	*s;
	NSNumber	*n;
	
	if( obj == nil)
		return def;
	if( [obj isKindOfClass:[NSString class]])
	{
		s = (NSString *) obj;
		return [s doubleValue];
	}
	else if ([obj isKindOfClass:[NSNumber class]])
	{
		n = (NSNumber *) obj;
		return [n doubleValue];
	}
	return def;
}

+(BOOL) prefsGetBoolean:(NSObject *)obj
{
	return [self prefsGetBoolean:obj default:NO];
}

+ (BOOL) prefsGetBoolean:(NSObject *)obj default:(BOOL)def
{
	NSString	*s;
	NSNumber	*n;
	
	if( obj == nil)
		return def;
	if( [obj isKindOfClass:[NSString class]])
	{
		s = (NSString *) obj;
		return [s boolValue];
	}
	else if ([obj isKindOfClass:[NSNumber class]])
	{
		n = (NSNumber *) obj;
		return [n boolValue];
	}
	return def;
}

+(NSString *) prefsGetString:(NSObject *)obj
{
	return [self prefsGetString:obj default:@""];
}

+(NSString *) prefsGetString:(NSObject *)obj default:(NSString *)def
{
	NSString	*s;
	NSNumber	*n;

	if( obj == nil)
		return def;
	if( [obj isKindOfClass:[NSString class]])
	{
		s = (NSString *) obj;
		return s;
	}
	else if ([obj isKindOfClass:[NSNumber class]])
	{
		n = (NSNumber *) obj;
		return [n stringValue];
	}
	return def;
}

+(NSDate *) prefsGetDate:(NSDate *)obj
{
	return [self prefsGetDate:obj default:nil];
}

+(NSDate *) prefsGetDate:(NSObject *)obj default:(NSDate *)def
{
	NSString	*s;
	NSDate		*d;
	if( obj == nil)
		return def;
	if( [obj isKindOfClass:[NSDate class]])
	{
		d = (NSDate *) obj;
		return d;
	}
	else if ([obj isKindOfClass:[NSString class]])
	{
        s = (NSString *) obj;
/*
 Cocotron doesnt have:
    - (NSDate *)dateFromString:(NSString *)string;
 hence we have to do it the old unix style
*/ 
		int year = 0;
        int month = 0;
        int day = 0;
        int hour = 0;
        int min = 0;
        int sec = 0;
        sscanf([s UTF8String],"%04d-%02d-%02d %02d:%02d:%02d",&year,&month,&day,&hour,&min,&sec);

        struct tm mytm;
        memset(&mytm,0x00,sizeof(mytm));

        mytm.tm_sec = sec;
        mytm.tm_min = min;
        mytm.tm_hour = hour;
        mytm.tm_mday = day;
        mytm.tm_mon = month -1 ;
        mytm.tm_year = year +1900;
        time_t myTime = mktime(&mytm);
        return [NSDate dateWithTimeIntervalSince1970:myTime];
	}
	else if ([obj isKindOfClass:[NSNumber class]])
	{
		//n = (NSNumber *) obj;
        s = (NSString *) obj;
		return [NSDate dateWithTimeIntervalSinceReferenceDate:[s integerValue]];
	}
	return def;
}

+(NSDictionary *) mergePrefs:(NSDictionary*) prefs withDefaults:(NSDictionary *)defaults
{
	NSMutableDictionary *dict;
	NSArray *keys;
	NSString *key;
	id		obj;
	
	dict = [NSMutableDictionary dictionaryWithDictionary:defaults];
	keys = [prefs allKeys];

	for (key in keys)
	{
		obj = prefs[key];
		if(obj)
		{
            assert(key!=NULL);
			dict[key] = obj;
		}
	}
	return dict;
}

+(NSDictionary *) diffPrefs:(NSDictionary*) prefs withDefaults:(NSDictionary *)defaults
{
	NSMutableDictionary *dict;
	NSArray		*keys;
	NSString	*key;
	id			objDef=NULL;
	id			obj=NULL;
	
	dict = [[NSMutableDictionary alloc]init];
	keys = [obj allKeys]; /*FIXME: what the hell is the intention of this ?!? */
	
	for (key in keys)
	{
		obj		= prefs[key];
		objDef	= defaults[key];
		if(!objDef)
		{
			/* theres no default, we must include the value */
            assert(key!=NULL);
			dict[key] = obj;
			continue;
		}
		if((obj) && (objDef))
		{
			/* there is a default value. we only include the value if its different from the default */
			if (![obj isEqual: objDef])
			{
                assert(key!=NULL);
				dict[key] = obj;
			}
		}
	}
	return dict;
}

@end
