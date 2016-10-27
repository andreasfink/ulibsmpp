//
//  TestLogFile.h
//  ulibsmpp
//
//  Created by Aarno Syvänen on 09.10.12.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import "ulib/UMLogDestination.h"

@class UMLogFeed, UMLogHandler;

@interface TestLogFile : UMLogDestination
{
    NSString __weak  *fileName;
    NSFileHandle __weak  *fileHandler;
    NSFileManager *filemgr;
    ssize_t currentOffset;
    ssize_t totalFileLength;
    
    NSString *lineDelimiter;
    NSUInteger chunkSize;
}

@property (readwrite,weak) NSString *fileName;
@property (readwrite,weak) NSFileHandle *fileHandler;
@property (readwrite,strong) NSFileManager *filemgr;
@property (nonatomic, copy) NSString *lineDelimiter;
@property (nonatomic) NSUInteger chunkSize;

- (TestLogFile *) initWithFileName:(NSString *)name;
- (BOOL) removeLog;
- (void) emptyLog;
- (void) closeLog;
- (void) LogAnEntry:(UMLogEntry *)logEntry;
- (void) unlockedLogAnEntry:(UMLogEntry *)logEntry;
- (void) LogNow:(UMLogEntry *)logEntry;
- (void) flush;
- (void) flushUnlocked;
- (ssize_t) cursor;
- (ssize_t) cursorUnlocked;
- (ssize_t) cursorToEnd;
- (ssize_t) cursorToEndUnlocked;
- (ssize_t) size;
- (ssize_t) sizeUnlocked;
- (NSString *) description;
+ (void)configWithConfig:(NSString*)config withLogFile:(NSString **)logFile;
- (TestLogFile *) initWithFileName:(NSString *)aPath andSeparator:(NSString *)sep;
- (ssize_t)updateFileSize;
- (NSString *) readLine:(int *)ret;
- (NSString *) readTrimmedLine:(int *)ret;
- (BOOL) splittedSepatorInChunk:(NSData *)chunk;
+ (UMLogFeed *) setLogHandler:(UMLogHandler *)handler  withName:(NSString *)name withSection:(NSString *)type withSubsection:(NSString *)sub andWithLogFile:(TestLogFile *)dst;
- (ssize_t)LogNowAndGiveSize:(UMLogEntry *)logEntry;

#if NS_BLOCKS_AVAILABLE
- (void) enumerateLinesUsingBlock:(void(^)(NSString*, BOOL *))block withResult:(int *)ret;
#endif

@end
