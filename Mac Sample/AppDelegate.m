//
//  AppDelegate.m
//
//  Created by Ben Copsey on 09/07/2008.
//  Copyright 2008 All-Seeing Interactive Ltd. All rights reserved.
//

#import "AppDelegate.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"

@implementation AppDelegate

- (id)init
{
	[super init];
	networkQueue = [[ASINetworkQueue alloc] init];
	return self;
}

- (void)dealloc
{
	[networkQueue release];
	[super dealloc];
}


- (IBAction)simpleURLFetch:(id)sender
{
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/"]] autorelease];
	
	//Customise our user agent, for no real reason
	[request addRequestHeader:@"User-Agent" value:@"ASIHTTPRequest"];
	
	[request start];
	if ([request responseString]) {
		[htmlSource setString:[request responseString]];
	}
}


- (IBAction)URLFetchWithProgress:(id)sender
{
	[startButton setTitle:@"Stop"];
	[startButton setAction:@selector(stopURLFetchWithProgress:)];
	
	NSString *tempFile = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"MemexTrails_1.0b1.zip.download"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:tempFile]) {
		[[NSFileManager defaultManager] removeItemAtPath:tempFile error:nil];
	}
	
	[self resumeURLFetchWithProgress:self];
}


- (IBAction)stopURLFetchWithProgress:(id)sender
{
	[startButton setTitle:@"Start"];
	[startButton setAction:@selector(URLFetchWithProgress:)];
	[networkQueue cancelAllOperations];
	[resumeButton setEnabled:YES];
}

- (IBAction)resumeURLFetchWithProgress:(id)sender
{
	[resumeButton setEnabled:NO];
	[startButton setTitle:@"Stop"];
	[startButton setAction:@selector(stopURLFetchWithProgress:)];
	
	[networkQueue cancelAllOperations];
	[networkQueue setShowAccurateProgress:YES];
	[networkQueue setDownloadProgressDelegate:progressIndicator];
	[networkQueue setDelegate:self];
	[networkQueue setRequestDidFinishSelector:@selector(URLFetchWithProgressComplete:)];
	
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://trails-network.net/Downloads/MemexTrails_1.0b1.zip"]] autorelease];
	[request setDownloadDestinationPath:[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"MemexTrails_1.0b1.zip"]];
	[request setTemporaryFileDownloadPath:[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"MemexTrails_1.0b1.zip.download"]];
	[request setAllowResumeForFileDownloads:YES];
	[networkQueue addOperation:request];
	[networkQueue go];
}

- (void)URLFetchWithProgressComplete:(ASIHTTPRequest *)request
{
	if ([request error]) {
		[fileLocation setStringValue:[NSString stringWithFormat:@"An error occurred: %@",[[[request error] userInfo] objectForKey:@"Title"]]];
	} else {
		[fileLocation setStringValue:[NSString stringWithFormat:@"File downloaded to %@",[request downloadDestinationPath]]];
	}
	[startButton setTitle:@"Start"];
	[startButton setAction:@selector(URLFetchWithProgress:)];
}

- (IBAction)fetchThreeImages:(id)sender
{
	[imageView1 setImage:nil];
	[imageView2 setImage:nil];
	[imageView3 setImage:nil];
	
	[networkQueue cancelAllOperations];
	[networkQueue setDownloadProgressDelegate:progressIndicator];
	[networkQueue setRequestDidFinishSelector:@selector(imageFetchComplete:)];
	[networkQueue setDelegate:self];
	[networkQueue setShowAccurateProgress:([showAccurateProgress state] == NSOnState)];
	
	ASIHTTPRequest *request;
	
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/i/logo.png"]] autorelease];
	[request setDownloadDestinationPath:[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"1.png"]];
	[networkQueue addOperation:request];
	
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/i/trailsnetwork.png"]] autorelease];
	[request setDownloadDestinationPath:[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"2.png"]];
	[networkQueue addOperation:request];
	
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/i/sharedspace20.png"]] autorelease];
	[request setDownloadDestinationPath:[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"3.png"]];
	[networkQueue addOperation:request];
	
	
	[networkQueue go];
}


- (void)imageFetchComplete:(ASIHTTPRequest *)request
{
	NSImage *img = [[[NSImage alloc] initWithContentsOfFile:[request downloadDestinationPath]] autorelease];
	if (img) {
		if ([imageView1 image]) {
			if ([imageView2 image]) {
				[imageView3 setImage:img];
			} else {
				[imageView2 setImage:img];
			}
		} else {
			[imageView1 setImage:img];
		}
	}

}


- (IBAction)fetchTopSecretInformation:(id)sender
{
	[networkQueue cancelAllOperations];
	[networkQueue setRequestDidFinishSelector:@selector(topSecretFetchComplete:)];
	[networkQueue setDelegate:self];
	
	[progressIndicator setDoubleValue:0];
	
	ASIHTTPRequest *request;
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/top_secret/"]] autorelease];
	[request setUseKeychainPersistance:[keychainCheckbox state]];
	[networkQueue addOperation:request];
	[networkQueue go];

}

- (IBAction)topSecretFetchComplete:(ASIHTTPRequest *)request
{
	if (![request error]) {
		[topSecretInfo setStringValue:[request responseString]];
		[topSecretInfo setFont:[NSFont boldSystemFontOfSize:13]];
	}
}

- (void)authorizationNeededForRequest:(ASIHTTPRequest *)request
{
	[realm setStringValue:[request authenticationRealm]];
	[host setStringValue:[[request url] host]];

	[NSApp beginSheet: loginWindow
		modalForWindow: window
		modalDelegate: self
		didEndSelector: @selector(authSheetDidEnd:returnCode:contextInfo:)
		contextInfo: request];
}

- (IBAction)dismissAuthSheet:(id)sender {
    [[NSApplication sharedApplication] endSheet: loginWindow returnCode: [(NSControl*)sender tag]];
}

- (void)authSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	ASIHTTPRequest *request = (ASIHTTPRequest *)contextInfo;
    if (returnCode == NSOKButton) {
		[request setUsername:[[[username stringValue] copy] autorelease]];
		[request setPassword:[[[password stringValue] copy] autorelease]];
		[request retryWithAuthentication];
    } else {
		[request cancelLoad];
	}
    [loginWindow orderOut: self];
}

- (IBAction)postWithProgress:(id)sender
{	
	//Create a 1mb file
	NSMutableData *data = [NSMutableData dataWithLength:1024*1024];
	NSString *path = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"bigfile"];
	[data writeToFile:path atomically:NO];
	
	[networkQueue cancelAllOperations];
	[networkQueue setShowAccurateProgress:YES];
	[networkQueue setUploadProgressDelegate:progressIndicator];
	[networkQueue setDelegate:self];
	
	ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ignore"]] autorelease];
	[request setPostValue:@"test" forKey:@"value1"];
	[request setPostValue:@"test" forKey:@"value2"];
	[request setPostValue:@"test" forKey:@"value3"];
	[request setFile:path forKey:@"file"];
	

	[networkQueue addOperation:request];
	[networkQueue go];
}



@end
