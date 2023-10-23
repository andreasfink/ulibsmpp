//
//  PriorityQueue.m
//  UniversalSMSUtilities
//
//  Created by Andreas Fink on 09.03.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import "PriorityQueue.h"

#define	VALIDATE_PRIORITY(p)	{ if( ((p)>=MAX_QUEUE_PRIORITIES) || ( (p) <0)) { p=PRIORITY_NORMAL; } }

static const int PriorityQueuePriorities[] =
{
	PRIORITY_EMERGENCY,
	PRIORITY_HIGH,
	PRIORITY_MEDIUM,
	PRIORITY_BULK,
	PRIORITY_EMERGENCY,
	PRIORITY_DLR,
	PRIORITY_HIGH,
	PRIORITY_NORMAL,
	PRIORITY_EMERGENCY,
	PRIORITY_MEDIUM,
	PRIORITY_LOW,
	PRIORITY_EMERGENCY,
	PRIORITY_HIGH,
	PRIORITY_MEDIUM,
	PRIORITY_EMERGENCY,
	PRIORITY_HIGH,
	PRIORITY_NORMAL,
	PRIORITY_EMERGENCY,
	PRIORITY_MEDIUM,
	PRIORITY_LOW,
	PRIORITY_BULK,
	PRIORITY_EMERGENCY,
	PRIORITY_HIGH,
	PRIORITY_NORMAL,
	PRIORITY_EMERGENCY,
	PRIORITY_HIGH,
	PRIORITY_LOW,
	PRIORITY_EMERGENCY,
	PRIORITY_MEDIUM,
	PRIORITY_NORMAL,
	PRIORITY_EMERGENCY,
	PRIORITY_HIGH,
	PRIORITY_LOW,
	PRIORITY_DLR,
	PRIORITY_CLEANUP,
}; 

@implementation PriorityQueue

- (PriorityQueue *)init
{
	int i;

    if((self=[super init]))
    {
        for(i=0;i<MAX_QUEUE_PRIORITIES;i++)
        {
            queue[i]	= [[NSMutableArray alloc] init];
            lock[i]		= [[NSLock alloc]init];
        }
    }
	return self;
}


- (void)	addToQueue:(id) m priority:(int)p
{
	VALIDATE_PRIORITY(p);
	[lock[p]    lock];
	[queue[p] addObject:m];
	[lock[p]    unlock];	
}

- (void)	addToQueue:(id) m
{
	[self addToQueue:m priority:PRIORITY_NORMAL];
}

- (id)		getFromQueue
{
	ssize_t i;
	int p;
	ssize_t s;
	id obj = nil;
	
	i = MAX_QUEUE_PRIORITIES;
	while(i--)
	{
		p = PriorityQueuePriorities[pos];
        [lock[p] lock];
		pos++;
		pos %= (sizeof (PriorityQueuePriorities) / sizeof(int));
		s = [queue[p] count];
		if(s > 0)
		{
			obj = queue[p][0];
			[queue[p] removeObjectAtIndex:0];
            [lock[p] unlock];
			return obj;
		}
        [lock[p] unlock];
	}
    
	return nil;	
}

- (int)		objectsInQueue
{
	int i;
	int n;

	n = 0;
	for(i=0;i<MAX_QUEUE_PRIORITIES;i++)
	{
		[lock[i] lock];
		n += [queue[i] count];
		[lock[i] unlock];
	}
	return n;
}

- (NSString *)description
{
    NSMutableString *desc;
    long i;
    
    desc = [[NSMutableString alloc] initWithFormat:@"Dump of priority queue %p starts\n", self];
    
    i = 0;
    while (i < MAX_QUEUE_PRIORITIES)
    {
        [desc appendFormat:@"queue for priority %ld is %@\n", i, queue[i]];
        ++i;
    }
    
    [desc appendString:@"Priority queuue dump ends\n"];
    
    return desc;
}

- (int)count
{
    return [self objectsInQueue];
}
@end
