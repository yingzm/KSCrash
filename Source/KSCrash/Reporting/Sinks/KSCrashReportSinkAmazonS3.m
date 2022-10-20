//
//  KSCrashReportSinkAmazonS3.m
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//


#import "KSCrashReportSinkAmazonS3.h"

#import "KSHTTPMultipartPostBody.h"
#import "KSHTTPRequestSender.h"
#import "NSData+KSGZip.h"
#import "KSJSONCodecObjC.h"
#import "KSReachabilityKSCrash.h"
#import "NSError+SimpleConstructor.h"

//#define KSLogger_LocalLevel TRACE
#import "KSLogger.h"


@interface KSCrashReportSinkAmazonS3 ()

@property(nonatomic,readwrite,retain) NSURL* url;

@property(nonatomic,readwrite,retain) KSReachableOperationKSCrash* reachableOperation;


@end


@implementation KSCrashReportSinkAmazonS3

@synthesize url = _url;
@synthesize reachableOperation = _reachableOperation;

+ (KSCrashReportSinkAmazonS3 *) sinkWithURL:(NSURL*) url
{
    return [[self alloc] initWithURL:url];
}

- (id) initWithURL:(NSURL*) url
{
    if((self = [super init]))
    {
        self.url = url;
    }
    return self;
}

- (id <KSCrashReportFilter>) defaultCrashReportFilterSet
{
    return self;
}

- (void) filterReports:(NSArray*) reports
          onCompletion:(KSCrashReportFilterCompletion) onCompletion
{
    NSError* error = nil;
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self.url
        cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
        timeoutInterval:15];
    NSData* jsonData = [KSJSONCodec encode:reports
                                   options:KSJSONEncodeOptionSorted
                                     error:&error];
    if(jsonData == nil)
    {
        kscrash_callCompletion(onCompletion, reports, NO, error);
        return;
    }

    request.HTTPMethod = @"PUT";
	request.HTTPBody = jsonData;
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"KSCrashReporter" forHTTPHeaderField:@"User-Agent"];

    self.reachableOperation = [KSReachableOperationKSCrash operationWithHost:[self.url host]
                                                                   allowWWAN:YES
                                                                       block:^
    {
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:self.url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
        [[KSHTTPRequestSender sender] sendRequest:req onSuccess:^(NSHTTPURLResponse *response, NSData *data) {
            NSDictionary *top = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (!top) {
                NSLog(@"Failed to parse JSON when getSignedURL");
                return;
            }
            NSString *signedURL = [top objectForKey:@"uploadURL"];
            if (!signedURL) {
                NSLog(@"No uploadURL from getSignedURL result");
                return;
            }
            request.URL = [NSURL URLWithString:signedURL];
            [[KSHTTPRequestSender sender] sendRequest:request
                                            onSuccess:^(__unused NSHTTPURLResponse* response1, __unused NSData* data1) {
                kscrash_callCompletion(onCompletion, reports, YES, nil);
             } onFailure:^(NSHTTPURLResponse* response2, NSData* data2) {
                 NSString* text = [[NSString alloc] initWithData:data2 encoding:NSUTF8StringEncoding];
                 NSLog(@"Failed to upload %@ with code %d", text, (int)response2.statusCode);
                 kscrash_callCompletion(onCompletion, reports, NO,
                                        [NSError errorWithDomain:[[self class] description]
                                                            code:response2.statusCode
                                                        userInfo:[NSDictionary dictionaryWithObject:text
                                                                                             forKey:NSLocalizedDescriptionKey]
                                         ]);
             } onError:^(NSError* error2) {
                 NSLog(@"%@", error2.description);
                 kscrash_callCompletion(onCompletion, reports, NO, error2);
             }];
        } onFailure:^(NSHTTPURLResponse *response3, NSData *data3) {
            NSLog(@"Failed to get upload URL %d", (int)response3.statusCode);
        } onError:^(NSError *error3) {
            NSLog(@"Error when get upload URL");
            NSLog(@"%@", error3.description);
        }];
    }];
}

@end
