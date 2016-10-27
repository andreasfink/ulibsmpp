//
//  TestDelegate.h
//  smsrouter
//
//  Created by Aarno Syvänen on 14.02.13.
//  Copyright (c) 2013 Andreas Fink. All rights reserved.
//

#import "AppDelegate.h"

@class TestRouter;

@interface TestDelegate : AppDelegate
{
    TestRouter *messageRouter;
}

@property(readwrite,retain) TestRouter *messageRouter;

@end
