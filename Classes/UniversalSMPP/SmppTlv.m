//
//  SmppTlv.m
//  ulibsmpp
//
//  Created by Andreas Fink on 28/03/14.
//
//

#import "SmppTlv.h"

@implementation SmppTlv

@synthesize name;
@synthesize tag;
@synthesize length;
@synthesize type;


- (int) equals:(SmppTlv *)tlv
{
    int ret = 1;
    
    if ([self name] != [tlv name])
    {
        ret = 0;
    }
    return ret;
}


+(SmppTlv *)tlvWithName:(NSString *)n tag:(int)ta length:(int)len type:(int)ty
{
    SmppTlv *tlv =[[SmppTlv alloc]initWithName:n tag:ta length:len type:ty];
    return tlv;
}

-(SmppTlv *)initWithName:(NSString *)n tag:(int)ta length:(int)len type:(int)ty
{
    self = [super init];
    if(self)
    {
        self.tag = ta;
        self.length = len;
        self.type = ty;
        self.name = n;
    }
    return self;
}

@end
