//
//  UMPrefs.h
//  UniversalSMSUtilities
//
//  Created by Andreas Fink on 03.03.09.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import <Foundation/Foundation.h>


@interface UMPrefs : NSObject
{

}


+ (int) prefsGetInteger:(NSObject *)obj;
+ (int) prefsGetInteger:(NSObject *)obj default:(int)def;

+ (double) prefsGetDouble:(NSObject *)obj;
+ (double) prefsGetDouble:(NSObject *)obj default:(double)def;

+ (NSString *) prefsGetString:(NSObject *)obj;
+ (NSString *) prefsGetString:(NSObject *)obj default:(NSString *)def;

+(NSDate *) prefsGetDate:(NSDate *)obj;
+(NSDate *) prefsGetDate:(NSObject *)obj default:(NSDate *)def;

+ (BOOL) prefsGetBoolean:(NSObject *)obj;
+ (BOOL) prefsGetBoolean:(NSObject *)obj default:(BOOL)def;

+(NSDictionary *)mergePrefs:(NSDictionary*) prefs withDefaults:(NSDictionary *)defaults;
+(NSDictionary *) diffPrefs:(NSDictionary*) prefs withDefaults:(NSDictionary *)defaults;

@end

