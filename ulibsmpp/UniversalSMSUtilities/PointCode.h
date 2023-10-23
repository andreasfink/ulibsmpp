//
//  PointCode.h
//  UniversalSMSUtilitites
//
//  Created by Andreas Fink on 27.02.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import <Foundation/Foundation.h>

#ifndef POINTCODE_H
#define POINTCODE_H 1

typedef	enum PointCodeVariant
{
	PCVARIANT_UNKNOWN	= 0,
	PCVARIANT_ITU		= 1,
	PCVARIANT_ANSI		= 2,
	PCVARIANT_CHINA		= 3,
	PCVARIANT_JAPAN		= 4,
	PCVARIANT_RANDOM	= 5,
} PointCodeVariant;

@interface PointCode : NSObject
{
	PointCodeVariant	variant;
	NSInteger			pc;
}

@end
#endif /* #ifndef POINTCODE_H */
