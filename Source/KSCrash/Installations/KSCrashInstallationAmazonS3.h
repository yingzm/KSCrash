//
//  KSCrashInstallationS3.h
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


#import "KSCrashInstallation.h"


/**
 * This installation uses Amazon S3 and lambda to upload the reports.
 * The serer is setup by  https://aws.amazon.com/blogs/compute/uploading-to-amazon-s3-directly-from-a-web-or-mobile-application/
 * Also refer to https://github.com/aws-samples/amazon-s3-presigned-urls-aws-sam
 * if the aws link is unreachable.
 * The lambda function also needs minor modification to accept json files instead of jpg.
 */
@interface KSCrashInstallationAmazonS3 : KSCrashInstallation

/**
 * The URL to connect to.
 * Should be something like https://{id}.execute-api.{region}.amazonaws.com/uploads
 */
@property(nonatomic,readwrite,retain) NSURL* url;

+ (instancetype) sharedInstance;

@end
