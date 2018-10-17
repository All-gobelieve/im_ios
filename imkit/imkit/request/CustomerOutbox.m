//
//  CustomerOutbox.m
//  imkit
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "CustomerOutbox.h"
#import "IMService.h"
#import "CustomerMessageDB.h"

@implementation CustomerOutbox
+(CustomerOutbox*)instance {
    static CustomerOutbox *box;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!box) {
            box = [[CustomerOutbox alloc] init];
        }
    });
    return box;
}

-(id)init {
    self = [super init];
    if (self) {
    }
    return self;
}


- (void)sendMessage:(IMessage*)m{
    ICustomerMessage *msg = (ICustomerMessage*)m;
    CustomerMessage *im = [[CustomerMessage alloc] init];

    im.customerAppID = msg.customerAppID;
    im.customerID = msg.customerID;
    im.storeID = msg.storeID;
    im.sellerID = msg.sellerID;
    im.msgLocalID = msg.msgLocalID;
    im.content = msg.rawContent;
    
    [[IMService instance] sendCustomerMessage:im];
}

-(void)markMessageFailure:(IMessage*)msg {
    ICustomerMessage *cm = (ICustomerMessage*)msg;
    [[CustomerMessageDB instance] markMessageFailure:cm.msgLocalID];
}

-(void)saveMessageAttachment:(IMessage*)msg url:(NSString*)url {
#ifdef SQL_ENGINE_DB
    if (msg.audioContent) {
        MessageAudioContent *audioContent = [msg.audioContent cloneWithURL:url];
        [[CustomerMessageDB instance] updateMessageContent:msg.msgLocalID content:audioContent.raw];
    } else if (msg.imageContent) {
        MessageImageContent *imageContent = [msg.imageContent cloneWithURL:url];
        [[CustomerMessageDB instance] updateMessageContent:msg.msgLocalID content:imageContent.raw];
    }
#else
    ICustomerMessage *cm = (ICustomerMessage*)msg;
    MessageAttachmentContent *att = [[MessageAttachmentContent alloc] initWithAttachment:msg.msgLocalID url:url];
    ICustomerMessage *attachment = [[ICustomerMessage alloc] init];
    attachment.storeID = cm.storeID;
    attachment.sellerID = cm.sellerID;
    attachment.customerID = cm.customerID;
    attachment.customerAppID = cm.customerAppID;
    attachment.rawContent = att.raw;
    
    [[CustomerMessageDB instance] insertMessage:attachment uid:cm.storeID];
#endif
}

-(void)saveMessageAttachment:(IMessage*)msg url:(NSString*)url thumbnail:(NSString*)thumbnail {
#ifdef SQL_ENGINE_DB
    MessageVideoContent *videoContent = [msg.videoContent cloneWithURL:url thumbnail:thumbnail];
    [[CustomerMessageDB instance] updateMessageContent:msg.msgLocalID content:videoContent.raw];
#endif
}

@end
