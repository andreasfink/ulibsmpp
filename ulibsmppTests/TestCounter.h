//
//  TestCounter.h
//  ulibsmpp
//
//  Created by Aarno Syvänen on 16.10.12.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import <Foundation/Foundation.h>

@interface TestCounter : NSObject
{
    NSLock *lock;
    unsigned long n;
}

@property(readonly,strong) NSLock *lock;

/* create a new counter object.*/
- (TestCounter *)init;

/* return the current value of the counter and increase counter by one */
- (unsigned long)increase;

/* return the current value of the counter and increase counter by value */
- (unsigned long)increaseWith:(unsigned long)value;

/* return the current value of the counter */
-(unsigned long)value;

/* return the current value of the counter and decrease counter by one */
- (unsigned long)decrease;

/* return the current value of the counter and set it to the supplied value */
- (unsigned long)setTo:(unsigned long)value;


@end
