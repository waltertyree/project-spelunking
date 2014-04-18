#import <Foundation/Foundation.h>
#import <objc/runtime.h>


@interface NSNotificationCenter (AllObservers)

- (NSSet *) observersForNotificationName:(NSString *)notificationName;
- (NSString *) allObservers; 

@end


@implementation NSNotificationCenter (AllObservers)

const static void *namesKey = &namesKey;

+ (void) load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
	method_exchangeImplementations(class_getInstanceMethod(self, @selector(addObserver:selector:name:object:)),
	                               class_getInstanceMethod(self, @selector(cc_addObserver:selector:name:object:)));
    });
}

- (void) cc_addObserver:(id)notificationObserver selector:(SEL)notificationSelector name:(NSString *)notificationName object:(id)notificationSender
{
	[self cc_addObserver:notificationObserver selector:notificationSelector name:notificationName object:notificationSender];
	
	if (!notificationObserver || !notificationName)
		return;
	
	NSMutableDictionary *names = objc_getAssociatedObject(self, namesKey);
	if (!names)
	{
		names = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, namesKey, names, OBJC_ASSOCIATION_RETAIN);
	}
	
	NSMutableSet *observers = [names objectForKey:notificationName];
	if (!observers)
	{
		observers = [NSMutableSet setWithObject:notificationObserver];
		[names setObject:observers forKey:notificationName];
	}
	else
	{
		[observers addObject:notificationObserver];
	}
}

- (NSSet *) observersForNotificationName:(NSString *)notificationName
{
	NSMutableDictionary *names = objc_getAssociatedObject(self, namesKey);
	return [names objectForKey:notificationName] ?: [NSSet set];
}

- (NSString *) allObservers {
    NSMutableDictionary *names = objc_getAssociatedObject(self, namesKey);
    return [NSString stringWithFormat:@"%@",names];
}

@end
