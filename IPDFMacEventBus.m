//
//  IPDFMacEventBus.m
//  InstaPDF for Mac
//
//  Created by mmackh on 18.10.19.
//  Copyright © 2019 mackh ag. All rights reserved.
//

#import "IPDFMacEventBus.h"

@interface NSEvent_Catalyst : NSObject

- (id)addLocalMonitorForEventsMatchingMask:(long)mask handler:(id _Nullable (^)(id))block;
- (void)removeMonitor:(id)eventMonitor;

@property (readonly) unsigned short keyCode;
@property (readonly,copy) NSString *characters;

@end

@interface IPDFMacEventBusEvent ()

@property (nonatomic,readwrite) IPDFMacEventBusType type;

@property (nonatomic,readwrite) NSEvent_Catalyst *underlyingEvent;

@property (nonatomic,readwrite) IPDFMacEventBusAppStateEvent appStateEvent;

@end

@interface IPDFMacEventBusMonitor ()

@property (nonatomic) IPDFMacEventBusType type;
@property (nonatomic, copy) IPDFMacEventBusEvent *(^eventHandler)(IPDFMacEventBusEvent *event);

@property (nonatomic) id eventMonitor;

- (void)appStateEventNotification:(NSNotification *)notification;

@end

@interface IPDFMacEventBus ()

@property (nonatomic) NSMutableArray *monitorsMutable;

@end

@implementation IPDFMacEventBus

+ (instancetype)sharedBus
{
    static IPDFMacEventBus *bus = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        bus = [IPDFMacEventBus new];
        bus.monitorsMutable = [NSMutableArray new];
    });
    return bus;
}

- (void)addMonitor:(IPDFMacEventBusMonitor *)monitor
{
    NSEvent_Catalyst *class = (id)NSClassFromString(@"NSEvent");
    __weak typeof(monitor) weakMonitor = monitor;
    
    if (monitor.type == IPDFMacEventBusTypeAppState)
    {
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [[IPDFMacEventBus appStateEventsMap] enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSNumber *obj, BOOL *stop)
        {
            [notificationCenter addObserver:monitor selector:@selector(appStateEventNotification:) name:key object:nil];
        }];
    }
    else
    {
        
        monitor.eventMonitor = [class addLocalMonitorForEventsMatchingMask:monitor.type handler:^id(NSEvent_Catalyst *event)
        {
            if (!weakMonitor.enabled) return event;
            
            IPDFMacEventBusEvent *busEvent = [IPDFMacEventBusEvent new];
            busEvent.type = weakMonitor.type;
            busEvent.underlyingEvent = event;
            return weakMonitor.eventHandler(busEvent).underlyingEvent;
        }];
    }
    [self.monitorsMutable addObject:monitor];
}

- (void)removeMonitor:(IPDFMacEventBusMonitor *)monitor
{
    NSEvent_Catalyst *class = (id)NSClassFromString(@"NSEvent");
    [class removeMonitor:monitor.eventMonitor];
    monitor.eventMonitor = nil;
    monitor.eventHandler = nil;
    monitor.enabled = NO;
    [self.monitorsMutable removeObject:monitor];
}

#pragma mark -
#pragma mark Helpers

+ (NSDictionary *)appStateEventsMap
{
    static NSDictionary *appStateEventsMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        appStateEventsMap =
        @{
            @"NSApplicationWillHideNotification" : @(IPDFMacEventBusAppStateEventHide),
            @"NSApplicationWillUnhideNotification" : @(IPDFMacEventBusAppStateEventUnhide),
            @"NSApplicationWillBecomeActiveNotification" : @(IPDFMacEventBusAppStateEventBecomeActive),
            @"NSApplicationWillResignActiveNotification" : @(IPDFMacEventBusAppStateEventResignActive),
            @"NSApplicationWillTerminateNotification" : @(IPDFMacEventBusAppStateEventTerminate),
            @"NSApplicationDidChangeScreenParametersNotification" : @(IPDFMacEventBusAppStateEventScreenParameters),
        };
    });
    return appStateEventsMap;
}

@end

@implementation IPDFMacEventBusMonitor

+ (instancetype)monitorWithType:(IPDFMacEventBusType)type eventHandler:(IPDFMacEventBusEvent *(^)(IPDFMacEventBusEvent *event))eventHandler
{
    IPDFMacEventBusMonitor *monitor = [IPDFMacEventBusMonitor new];
    monitor.type = type;
    monitor.eventHandler = eventHandler;
    monitor.enabled = YES;
    return monitor;
}

- (void)appStateEventNotification:(NSNotification *)notification
{
    IPDFMacEventBusAppStateEvent appStateEvent = [[IPDFMacEventBus appStateEventsMap][notification.name] integerValue];
    
    IPDFMacEventBusEvent *event = [IPDFMacEventBusEvent new];
    event.appStateEvent = appStateEvent;
    event.underlyingEvent = (id)notification;
    self.eventHandler(event);
}

- (void)dealloc
{
    if (self.type != IPDFMacEventBusTypeAppState) return;

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [[IPDFMacEventBus appStateEventsMap] enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSNumber *obj, BOOL *stop)
    {
        [notificationCenter removeObserver:self name:key object:nil];
    }];
}

@end

@implementation IPDFMacEventBusEvent

@end

@implementation IPDFMacEventBusEvent (Keyboard)

- (NSString *)characters
{
    return [(NSEvent_Catalyst *)self.underlyingEvent characters];
}

- (BOOL)isTab
{
    return [self.characters isEqualToString:@"\t"];
}

- (BOOL)isEnter
{
    return [self.characters isEqualToString:@"\r"];
}

- (BOOL)isESC
{
    return self.underlyingEvent.keyCode == 0x35;
}

@end

@implementation IPDFMacEventBusEvent (AppState)

- (IPDFMacEventBusAppStateEvent)appState
{
    return _appStateEvent;
}

@end
