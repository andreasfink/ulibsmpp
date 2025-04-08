//
//  PriorityQueue.h
//  UniversalSMSUtilities
//
//  Created by Andreas Fink on 09.03.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import <Foundation/Foundation.h>
#import <ulib/ulib.h>

#define		MAX_QUEUE_PRIORITIES	8

#define	PRIORITY_EMERGENCY	0
#define	PRIORITY_HIGH		1
#define	PRIORITY_MEDIUM		2
#define	PRIORITY_NORMAL		3
#define	PRIORITY_LOW		4
#define	PRIORITY_BULK		5
#define	PRIORITY_DLR		6
#define	PRIORITY_CLEANUP	7

@interface PriorityQueue : UMObject
{
	NSMutableArray	*queue[MAX_QUEUE_PRIORITIES];
	NSLock			*lock[MAX_QUEUE_PRIORITIES];
	int				pos;
}

- (PriorityQueue *)init;
- (void)	addToQueue:(id) m priority:(int)p;
- (void)	addToQueue:(id) m;
- (id)		getFromQueue;
- (int)		objectsInQueue;
- (NSString *)description;
- (int)count;
@end
