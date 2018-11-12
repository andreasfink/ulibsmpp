//
//  TestLogFile.m
//  ulibsmpp
//
//  Created by Aarno Syvänen on 09.10.12.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import "TestLogFile.h"

#import "ulib/UMLogFeed.h"
#import "ulib/UMConfig.h"

@implementation TestLogFile

@synthesize fileName;
@synthesize fileHandler;
@synthesize lineDelimiter;
@synthesize chunkSize;
@synthesize filemgr;

- (TestLogFile *)initWithFileName:(NSString *)name
{
    BOOL ret;
    NSString *localName = name;
    NSFileHandle *localHandler = [NSFileHandle fileHandleForUpdatingAtPath:name];
    
    if ((self = [super init]))
    {
        fileName = localName;
        self.filemgr = [NSFileManager defaultManager];
        
        ret = [filemgr fileExistsAtPath:name];
        if (ret == FALSE)
        {
            ret = [filemgr createFileAtPath:name contents:nil attributes:nil];
            if (ret == FALSE)
                goto error;
        }
        
        fileHandler =  localHandler;
        if (!fileHandler)
            goto error;
    }
    return self;
    
error:
    return nil;
}

- (void)closeLog
{
    [self lock];
    [fileHandler closeFile];
    [self unlock];
}

- (void)emptyLog
{
    [self lock];
    [fileHandler truncateFileAtOffset:0];
    [self unlock];
}

- (BOOL) removeLog
{
    BOOL ret;
    [self lock];
    ret = [filemgr removeItemAtPath:fileName error:nil];
    [self unlock];
    return ret;
}

- (void) LogAnEntry:(UMLogEntry *)logEntry
{
	UMLogLevel	entryLevel;
	
	entryLevel = [logEntry level];
    
	if((entryLevel == UMLOG_DEBUG) && ([debugSections count]  > 0))
	{
		if ([debugSections indexOfObject: [logEntry subsection]] != NSNotFound )
		{
			[self lock];
			[self LogNow: logEntry];
			[self unlock];
		}
	}
    
	else if( entryLevel >= level )
	{
		[self lock];
		[self LogNow: logEntry];
		[self unlock];
	}
}

- (void) unlockedLogAnEntry:(UMLogEntry *)logEntry
{
	UMLogLevel	entryLevel;
	
	entryLevel = [logEntry level];
    
	if((entryLevel == UMLOG_DEBUG) && ([debugSections count]  > 0))
	{
		if ([debugSections indexOfObject: [logEntry subsection]] != NSNotFound )
		{
			[self LogNow: logEntry];
		}
	}
    
	else if( entryLevel >= level )
	{
		[self LogNow: logEntry];
	}
}

- (void)LogNow:(UMLogEntry *)logEntry
{
	NSString *s;
    NSData *data;
	
    [fileHandler seekToEndOfFile];
	s = [logEntry description];
    data = [s dataUsingEncoding:NSUTF8StringEncoding];
    [fileHandler writeData:data];
}

- (void) flush
{
    [self lock];
    [fileHandler synchronizeFile];
    [self unlock];
}

- (void) flushUnlocked
{
    [fileHandler synchronizeFile];
}

- (ssize_t)cursor
{
    ssize_t pos;
    
    [self lock];
    pos = (ssize_t)[fileHandler offsetInFile];
    [self unlock];
    return pos;
}

- (ssize_t)cursorUnlocked
{
    ssize_t pos;
    
    pos = (ssize_t)[fileHandler offsetInFile];
    return pos;
}

- (ssize_t) cursorToEnd
{
    ssize_t size;
    
    [self lock];
    size = (ssize_t)[fileHandler seekToEndOfFile];
    [self unlock];
    return size;
}

- (ssize_t) cursorToEndUnlocked
{
    ssize_t size;
    
    size = (ssize_t)[fileHandler seekToEndOfFile];
    return size;
}

- (ssize_t) size
{
    ssize_t size;
    NSDictionary *fileAttributes;
    NSString *fileSize;
    NSError *error;
    
    size = -1;
    [self lock];
    fileAttributes = [filemgr attributesOfItemAtPath:fileName error:&error];
    [self unlock];
    if(fileAttributes)
	{
		fileSize = [fileAttributes objectForKey:@"NSFileSize"];
		size = (ssize_t)[fileSize longLongValue];
	}
    return size;
}

- (ssize_t) sizeUnlocked
{
    ssize_t size;
    NSDictionary *fileAttributes;
    NSString *fileSize;
    NSError *error;
    
    size = -1;
    fileAttributes = [filemgr attributesOfItemAtPath:fileName error:&error];
    if(fileAttributes)
	{
		fileSize = [fileAttributes objectForKey:@"NSFileSize"];
		size = [fileSize integerValue];
	}
    return size;
}


- (NSString *)description
{
    NSMutableString *desc;
    
    desc = [NSMutableString stringWithString:@"file log dump starts\r\n"];
    if (fileName)
        [desc appendFormat:@"uses %@\r\n", fileName];
    else
        [desc appendString:@"has no log file attached\r\n"];
    if (fileHandler)
        [desc appendString:@"has file handler defined\r\n"];
    else
        [desc appendString:@"has no file handler defined\r\n"];
    [desc appendString:@"file log dump ends\r\n"];
    return desc;
}

- (TestLogFile *) initWithFileName:(NSString *)aPath andSeparator:(NSString *)sep;
{
    if (!sep || [sep length] == 0)
        return nil;
    
    if ((self = [self initWithFileName:aPath])) {
        lineDelimiter = [[NSString alloc] initWithString:sep];
        currentOffset = 0ULL;
        chunkSize = 10;
        [fileHandler seekToEndOfFile];
        totalFileLength = (ssize_t)[fileHandler offsetInFile];
        //we don't need to seek back, since readLine will do that.
    }
    return self;
}


- (ssize_t)updateFileSize
{
    totalFileLength = [self sizeUnlocked];
    return totalFileLength;
}

/* Set ret -1 when error, 0 when end-of-file and 1 otherwise*/
- (NSString *) readLine:(int *)ret
{
    if (currentOffset >= totalFileLength)
    {
        *ret = -1;
        return nil;
    }
    
    NSData * newLineData = [lineDelimiter dataUsingEncoding:NSUTF8StringEncoding];
    [self lock];
    [fileHandler seekToFileOffset:currentOffset];
    [self unlock];
    NSMutableData *currentData = [[NSMutableData alloc] init];
    BOOL shouldReadMore = YES;
    
    @autoreleasepool
    {
    while (shouldReadMore)
    {
        if (currentOffset >= totalFileLength)
        {
            break;
        }
        
        NSData *chunkToBeAdded;
        [self lock];
        NSMutableData *chunk = [[fileHandler readDataOfLength:chunkSize] mutableCopy];
        if (!chunk || [chunk length] == 0)
        {
            [self unlock];
            *ret = 0;
            return nil;
        }
        
        /* Heuristic: if the last byte of the chunk was one of separator bytes, read
         * separator length minus one bytes more. This quarantees that the chunk contains
         * the whole separator.*/
        if([self splittedSepatorInChunk:chunk])
        {
            NSData *newChunk = [fileHandler readDataOfLength:([newLineData length] - 1)];
            [self unlock];
            if (!newChunk)
            {
                *ret = 0;
                return nil;
            }
            
            [chunk appendData:newChunk];
        }
        [self unlock];
        
        NSRange newLineRange = [chunk rangeOfData:newLineData options:NSDataWritingAtomic range:NSMakeRange(0, [chunk length])];
        //include the length so we can include the delimiter in the string
        NSRange subData = NSMakeRange(0, newLineRange.location+[newLineData length]);
        if (newLineRange.location != NSNotFound)
        {
            chunkToBeAdded = [chunk subdataWithRange:subData];
            shouldReadMore = NO;
        }
        else
            chunkToBeAdded = chunk;
        
        [currentData appendData:chunkToBeAdded];
        currentOffset += [chunkToBeAdded length];
    }
    }
    
    NSString * line = [[NSString alloc] initWithData:currentData encoding:NSUTF8StringEncoding];
    *ret = 1;
    return line;
}

- (NSString *) readTrimmedLine:(int *)ret
{
    return [[self readLine:ret] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

#if NS_BLOCKS_AVAILABLE
- (void) enumerateLinesUsingBlock:(void(^)(NSString*, BOOL*))block withResult:(int *)ret
{
    NSString * line = nil;
    BOOL stop = NO;
    while (stop == NO && (line = [self readLine:ret])) {
        block(line, &stop);
    }
}
#endif

- (BOOL) splittedSepatorInChunk:(NSData *)chunk
{
    NSRange last;
    long len;
    long i = 0;
    unsigned char lastByte[1];
    unsigned char byte;
    
    if (!chunk || [chunk length] == 0)
        return FALSE;
    
    if (!lineDelimiter || [lineDelimiter length] == 0)
        return FALSE;
    
    last = NSMakeRange([chunk length] - 1, 1);
    [chunk getBytes:lastByte range:last];
    len = [lineDelimiter length];
    
    while(i < len)
    {
        byte = [lineDelimiter characterAtIndex:i];
        if (lastByte[0] == byte)
            return TRUE;
        ++i;
    }
    
    return FALSE;
}

+ (UMLogFeed *) setLogHandler:(UMLogHandler *)handler  withName:(NSString *)name withSection:(NSString *)type withSubsection:(NSString *)sub andWithLogFile:(TestLogFile *)dst
{
    UMLogFeed *logFeed;
    logFeed = [[UMLogFeed alloc] initWithHandler:handler section:type subsection:sub];
    [logFeed setCopyToConsole:0];
    [logFeed setName:name];
    [handler addLogDestination:dst];
    return logFeed;
}

+ (void)configWithConfig:(NSString *)cfgName withLogFile:(NSString **)logFile
{
    UMConfig *cfg = [[UMConfig alloc] initWithFileName:cfgName];
    [cfg allowSingleGroup:@"core"];
    [cfg read];
    
    NSDictionary *grp = [cfg getSingleGroup:@"core"];
    if (!grp)
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"configuration file must have group core"userInfo:nil];
    
    *logFile = [grp objectForKey:@"log-file"];
}

- (ssize_t)LogNowAndGiveSize:(UMLogEntry *)logEntry
{
	NSString *s;
    NSData *data;
	
    [fileHandler seekToEndOfFile];
	s = [logEntry description];
    data = [s dataUsingEncoding:NSUTF8StringEncoding];
    [fileHandler writeData:data];
    
    return [data length];
}

@end

