project-spelunking
==================

Helper classes for dissecting new projects.

Introduction
--------

This set of classes and utilities are files I use when I come onto a new project and need to determine how the codebase works.

Files
------

###DIAGURLProtocol.h/.m

The `DIAGURLProtocol` is an implementation of an NSURLProtocol. NSHipster has a great [write up of how they can be used.] (http://nshipster.com/nsurlprotocol/). This particular code will capture every network request and response and write each one to a separate text file in the documents directory of the app. After adding the files to your project, simply add this line to your App Delegate's `application:didFinishLaunching:withOptions:` method.

    [NSURLProtocol registerClass:[DIAGURLProtocol class]];

If you are working with a codebase that uses the new NSURLSession architecture, this won't work the same way as each session gets its own set of protocols.

###Source Control Reports

The two `.awk` files are simple, and hacky, awk programs that will take either a git or SVN log as input and provde a report of the recent commits. The output will be the name of the committer, the number of commits they have made and the timestamp of their most recent commit. The list will be sorted so that the most recent committers come first. Use the files by creating a log and then running the awk program against it.

Examples:

     $ git log <filename> | awk -f '<absolute path to>/gitWho.awk'
     $ git log | awk -f '<absolute path to>/gitWho.awk'

The above commands will parse git logs. The first one will give you information on a single file. The second will provide information on the entire repository.

###Swizzle NSNotificationCenter

Following the path of notifications can be difficult with a new codebase. Apple doesn't provide a way to determine who is registered for each notification. By swizzling NSNotificationCenter's `addObserver:selector:name:object` to record who registers for each notification. This class does not swizzle `removeObserver:` so it will provide false positives. Swizzling is a dark art. 

To use this swizzle, add the `NSNotificationCenter+AllObservers.h/.m` files to the project. There is no need to `#import` or otherwise reference them in other classes. After running the app for a while, pause the app with the debugger and then execute the commands below to see who has registered for particular notifications.

Usage:

     po [[NSNotificationCenter defaultCenter] observersForNotificationName:<somename>]
     po [[NSNotificationCenter defaultCenter] allObservers]
