//
//  Tools.m
//  qlImageSize
//
//  Created by @Nyx0uf on 02/02/12.
//  Copyright (c) 2012 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import "Tools.h"
#import <Foundation/NSURL.h> // For NSString & NSURL
#import <sys/stat.h>
#import <sys/types.h>
#import <QuickLook/QLGenerator.h> // For kQLPreviewPropertyDisplayNameKey


CFDictionaryRef createQLPreviewPropertiesForFile(CFURLRef url, CFTypeRef src, CFStringRef name, CGSize* imgSize, CGImageRef* img)
{
	// Create the image source
	CGImageSourceRef imgSrc = (CFGetTypeID(src) == CFDataGetTypeID()) ? CGImageSourceCreateWithData(src, NULL) : CGImageSourceCreateWithURL(src, NULL);
	if (NULL == imgSrc)
		return NULL;

	// Copy images properties
	CFDictionaryRef imgProperties = CGImageSourceCopyPropertiesAtIndex(imgSrc, 0, NULL);
	if (NULL == imgProperties)
	{
		CFRelease(imgSrc);
		return NULL;
	}

	// Get image width
	CFNumberRef w = CFDictionaryGetValue(imgProperties, kCGImagePropertyPixelWidth);
	int width = 0;
	CFNumberGetValue(w, kCFNumberIntType, &width);
	// Get image height
	CFNumberRef h = CFDictionaryGetValue(imgProperties, kCGImagePropertyPixelHeight);
	int height = 0;
	CFNumberGetValue(h, kCFNumberIntType, &height);
	CFRelease(imgProperties);

	if (imgSize != NULL)
		*imgSize = (CGSize){.width = width, .height = height};

	if (img != NULL)
	{
		*img = CGImageSourceCreateImageAtIndex(imgSrc, 0, NULL);
	}
	CFRelease(imgSrc);

	// Get the filesize, because it's not always present in the image properties dictionary :/
	struct stat st;
	stat([[(__bridge NSURL*)url path] UTF8String], &st);
	// Create the display size format
	NSString* fmtSize = nil;
	if (st.st_size > 1048576) // More than 1Mb
		fmtSize = [[NSString alloc] initWithFormat:@"%.1fMb", (float)((float)st.st_size / 1048576.0f)];
	else if (st.st_size < 1048576 && st.st_size > 1024) // 1Kb - 1Mb
		fmtSize = [[NSString alloc] initWithFormat:@"%.2fKb", (float)((float)st.st_size / 1024.0f)];
	else // Less than 1Kb
		fmtSize = [[NSString alloc] initWithFormat:@"%lldb", st.st_size];

	// Create the properties dic
	CFTypeRef keys[1] = {kQLPreviewPropertyDisplayNameKey};
	CFTypeRef values[1] = {CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%@ (%dx%d - %@)"), name, width, height, fmtSize)}; // bla.png (64x64 - 137b)
	CFDictionaryRef properties = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	CFRelease(values[0]);
	return properties;
}

CF_RETURNS_RETAINED CFDictionaryRef properties_for_file(CFURLRef url)
{
	// Create the image source
	CGImageSourceRef imgSrc = CGImageSourceCreateWithURL(url, NULL);
	if (NULL == imgSrc)
		return NULL;
	
	// Copy images properties
	CFDictionaryRef imgProperties = CGImageSourceCopyPropertiesAtIndex(imgSrc, 0, NULL);
	if (NULL == imgProperties)
	{
		CFRelease(imgSrc);
		return NULL;
	}
	
	// Get image width
	CFNumberRef pWidth = CFDictionaryGetValue(imgProperties, kCGImagePropertyPixelWidth);
	int width = 0;
	CFNumberGetValue(pWidth, kCFNumberIntType, &width);
	// Get image height
	CFNumberRef pHeight = CFDictionaryGetValue(imgProperties, kCGImagePropertyPixelHeight);
	int height = 0;
	CFNumberGetValue(pHeight, kCFNumberIntType, &height);
	CFRelease(imgProperties);

	//CGRect imgFrame = (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height};
	//const bool b = CGRectContainsRect(screenFrame, imgFrame);

	CGImageRef imgRef = CGImageSourceCreateImageAtIndex(imgSrc, 0, NULL);
	/*if (b)
	{
		imgRef = CGImageSourceCreateImageAtIndex(imgSrc, 0, NULL);
	}
	else
	{
		CFTypeRef keys[2] = {kCGImageSourceCreateThumbnailFromImageIfAbsent, kCGImageSourceThumbnailMaxPixelSize};
		CFTypeRef values[2] = {kCFBooleanTrue, (__bridge CFNumberRef)(@(MAX(screenFrame.size.width, screenFrame.size.height)))};
		CFDictionaryRef opts = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		imgRef = CGImageSourceCreateThumbnailAtIndex(imgSrc, 0, opts);
		CFRelease(opts);
	}*/
	
	CFRelease(imgSrc);
	
	// Get the filesize, because it's not always present in the image properties dictionary :/
	struct stat st;
	stat([[(__bridge NSURL*)url path] UTF8String], &st);

	// Create the properties dic
	const CFIndex MAXVALS = 4;
	CFTypeRef keys[MAXVALS] = {@"nyx.width", @"nyx.height", @"nyx.size", @"nyx.repr"};
	CFTypeRef values[MAXVALS] = {pWidth, pHeight, (__bridge CFNumberRef)(@(st.st_size)), imgRef};
	CFDictionaryRef properties = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, MAXVALS, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	CGImageRelease(imgRef);
	return properties;
}
