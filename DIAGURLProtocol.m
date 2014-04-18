//
//  DIAGURLProtocol.m
//  CC Diagnostic URLProtocol
//
//  Created by Walter Tyree on 02/15/14.
//  Copyright (c) 2014 Tyree Apps, LLC. All rights reserved.
//
#import <CommonCrypto/CommonDigest.h>
#import "DIAGURLProtocol.h"

static NSString * const kTagKey = @"com.tyreeapps.requestModified";

@interface DIAGURLProtocol () <NSURLConnectionDelegate>

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *mutableData;
@property (nonatomic, strong) NSURLResponse *response;

@end

@implementation DIAGURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
        //We want to capture ALL requests.
  //However, the protocol will get hit by a request multiple times, so we want to ignore it after the first time.
    BOOL requestTagged = [[NSURLProtocol propertyForKey:kTagKey inRequest:request] boolValue];
    return !requestTagged;
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void) startLoading {
        
    NSMutableURLRequest *mutableRequest = [[self request] mutableCopy];

    [NSURLProtocol setProperty:@YES
                        forKey:kTagKey
                     inRequest:mutableRequest];

    //We are making ourself the delegate for this request so we can get the responses
    //then we are sending the connection along to the network
    [self setConnection:[NSURLConnection connectionWithRequest:mutableRequest
                                                delegate:self]];

    //We are creating a text file to hold our log
    //the filename for the text file is the md5 hash of the URL
    NSURL *dataPath = [[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory
                                                            inDomains:NSUserDomainMask] firstObject];
    dataPath = [dataPath URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.log",[self makeHash:[[self request] description]]]];
    
    //This just writes some pretty text to the file so it is human readable
    [self writeAtEndOfFile:@"Request\n" atURL:dataPath];
    [self writeAtEndOfFile:[NSString stringWithFormat:@"VERB:%@\n",self.request.HTTPMethod] atURL:dataPath];

    //If there is an HTTP body we want to print that
    [self writeAtEndOfFile:[NSString stringWithFormat:@"BODY:%@\n\n",[[NSString alloc] initWithData:[[self request] HTTPBody] encoding:NSUTF8StringEncoding]] atURL:dataPath];

    //add the request itself
    NSString *dataString = [[self request] description];
    
    [self writeAtEndOfFile:dataString atURL:dataPath];
        
}

- (void) stopLoading {
    
    [self.connection cancel];
    self.mutableData = nil;
    
}

#pragma mark - NSURLConnectionDelegate

//This is normal NSURLDelegate stuff
//Notice, though, that we pass everything back to the self.client object
//so that the app continues to function.....like we aren't even there....
- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    
    self.response = response;
    self.mutableData = [[NSMutableData alloc] init];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
    
    [self.mutableData appendData:data];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
    
    [self saveResponse];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}

#pragma mark - Private
-(NSString *)makeHash:(NSString *)valueToHash
{
    const char *ptr = [valueToHash UTF8String];
    
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(ptr, strlen(ptr), md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

-(void)writeAtEndOfFile:(NSString *)dataString atURL:(NSURL *)fileURL
{
    NSError *urlTestErr = nil;
    if([fileURL checkResourceIsReachableAndReturnError:&urlTestErr])
    {
        //file exists already so, append
        NSError *error = nil;
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingToURL:fileURL error:&error];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[dataString dataUsingEncoding:NSUTF8StringEncoding]];
        if (error) {
            NSLog(@"Unable to write to file %@",error.localizedDescription);
        }
    } else {
        //file doesn't exist, create it
        [dataString writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:nil];

    }
   
}

- (void) saveResponse {
    NSURL *dataPath = [[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory
                                                 inDomains:NSUserDomainMask] firstObject];
    dataPath = [dataPath URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.log",[self makeHash:[[self request] description]]]];
    

    //This just writes the whole response Payload to the file using the same filename as we used for the request
    NSString *dataString = [[NSString alloc] initWithData:[self mutableData] encoding:NSUTF8StringEncoding];
    
    [self writeAtEndOfFile:[NSString stringWithFormat:@"\n\nResponse:\n%@",dataString] atURL:dataPath];
  
    
    
}

@end
