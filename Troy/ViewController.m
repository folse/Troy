//
//  ViewController.m
//  Troy
//
//  Created by folse on 12/14/13.
//  Copyright (c) 2013 Folse. All rights reserved.
//

#import "ViewController.h"
#import <AudioToolbox/AudioToolbox.h>

@interface ViewController ()
{
    AFHTTPRequestOperationManager *manager;
    
    NSString *wantTypeId;
    int totalRetry;
    BOOL gotChance;
    UIImageView *backgroundBlurredImageView;
    NSString *availableTypeId;
    NSString *availableDate;
    NSString *availableCarId;
}

@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UILabel *chanceCountLabel;

@end

static  void  completionCallback (SystemSoundID  mySSID) {
    // Play again after sound play completion
    AudioServicesPlaySystemSound(mySSID);
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //[self systemLogin];
        
    NSString *path = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"txt"];
    NSString *contents = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSArray *contentsArray = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSString *docs = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/timezone.plist"] ;
    
    i(contentsArray.count)
    
    NSMutableArray *plistArray = [[NSMutableArray alloc] init];

    for (int i = 0; i < contentsArray.count; i++) {
        
        
        NSString* currentContent = contentsArray[i];
        
        NSArray* timezone = [currentContent componentsSeparatedByString:@","];
        
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:[timezone objectAtIndex:1] forKey:@"city"];
        [dic setObject:[timezone objectAtIndex:2] forKey:@"fix"];
        [plistArray addObject:dic];
    }
    [plistArray writeToFile:docs atomically:YES];
    
    s(docs)
}

-(void)systemLogin
{
    manager = [AFHTTPRequestOperationManager manager];
    [manager POST:@"http://haijia.bjxueche.net:8001/System/Login?username=bjcsxq&password=bjcsxq2012" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //s(responseObject)
        
        [self refreshTimeList];
        
        //[self getCars];

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        s(error)
    }];
}

-(void)refreshTimeList
{
    s([NSDate date])
    manager = [AFHTTPRequestOperationManager manager];
    [manager POST:@"http://haijia.bjxueche.net:8001/KM2/ClYyTimeSectionUIQuery2?xxzh=51137363&jlcbh=&trainType=&zip=false&osname=android" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        s(responseObject)
        
        NSDictionary *data = [responseObject valueForKey:@"data"];
        NSArray *dateArray = (NSArray *)[data valueForKey:@"UIDatas"];
        
        for (NSDictionary *item in dateArray) {
            
            int avaliableCarNum = [[item valueForKey:@"SL"] integerValue];
                       
            if (avaliableCarNum != 0) {
                
                availableDate = [item valueForKey:@"Yyrq"];
                availableDate = [availableDate componentsSeparatedByString:@" "][0];
                
                if ([availableDate isEqualToString:@"2013/12/28"]) {
                    
                    availableTypeId = [NSString stringWithFormat:@"%@", [item valueForKey:@"Xnsd"]];
                    
                    if ([availableTypeId isEqualToString:@"812"] || [availableTypeId isEqualToString:@"15"]) {
                        
                        //[self getCarNumber];
                        
                        gotChance = YES;
                        _statusLabel.text = @"Got One Chance";
                        
                        break;
                    }
                }
            }
        }
        
        if (!gotChance) {
            totalRetry += 1;
            //i(totalRetry)
            _statusLabel.text = [NSString stringWithFormat:@"%d",totalRetry];
            _chanceCountLabel.text = @"";
            [self refreshTimeList];
        }
    
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        s(error)
        
        _chanceCountLabel.text = @"Refresh Time List Failure";
        
        [self refreshTimeList];
    }];
}

-(void)getCars
{
    manager = [AFHTTPRequestOperationManager manager];
    [manager POST:@"http://haijia.bjxueche.net:8001/KM2/ClYyCars2?filters[jlcbh]=&filters[xxzh]=51137363&filters[trainType]=&zip=false&osname=android" parameters:@{@"filters[xnsd]":@"812",@"filters[yyrq]":@"2013/12/19"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        s(responseObject)
        
        NSDictionary *data = [responseObject valueForKey:@"data"];
        
        NSArray *availableCars = [data valueForKey:@"Result"];
        
        if (availableCars.count > 0) {
            
            availableCarId = [[availableCars lastObject] valueForKey:@"CNBH"];
            
            //[self makeReservation];
            
        }else{
            
            _chanceCountLabel.text = @"Lost At Got ID";
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        s(operation.responseString)
        
        s(error)
    }];
}

-(void)getCarNumber
{
    manager = [AFHTTPRequestOperationManager manager];
    [manager POST:@"http://haijia.bjxueche.net:8001/KM2/ClYyCars2?filters[jlcbh]=&filters[xxzh]=51137363&filters[trainType]=&zip=false&osname=android" parameters:@{@"filters[xnsd]": availableTypeId,@"filters[yyrq]":availableDate} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        s(responseObject)
        
        NSDictionary *data = [responseObject valueForKey:@"data"];
        
        NSArray *availableCars = [data valueForKey:@"Result"];
        
        if (availableCars.count > 0) {
            
            availableCarId = [[availableCars lastObject] valueForKey:@"CNBH"];
            
            [self makeReservation];
            
        }else{
            
            _chanceCountLabel.text = @"Lost At Got ID";
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        s(operation.responseString)

        s(error)
    }];
}

-(void)makeReservation
{
    availableDate = [availableDate stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    
    NSString *reservationParameter = [NSString stringWithFormat:@"%@.%@.%@.",availableCarId,availableDate,availableTypeId];
    
    manager = [AFHTTPRequestOperationManager manager];
    [manager POST:@"http://haijia.bjxueche.net:8001/KM2/ClYyAddByMutil?xxzh=51137361&jlcbh=&isJcsdYyMode=5&trainType=&zip=false&osname=android" parameters:@{@"params":reservationParameter} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        s(responseObject)
        
        int retCode = [[responseObject valueForKey:@"code"] integerValue];
       
        if (retCode == 0) {
            
             _statusLabel.text = @"Got One!";
            
             [self playSound];
            
        }else{
            
            _chanceCountLabel.text = @"Lost At Last Step";
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        s(error)
    }];
}

-(void)playSound
{
    static SystemSoundID soundIDTest = 0;
    
    NSString * path = [[NSBundle mainBundle] pathForResource:@"doorbell" ofType:@"wav"];
    
    if (path) {
        AudioServicesCreateSystemSoundID( (__bridge CFURLRef)[NSURL fileURLWithPath:path], &soundIDTest );
    }
    AudioServicesAddSystemSoundCompletion (soundIDTest, NULL, NULL , (void *)completionCallback, (void *)(__bridge CFURLRef)[NSURL fileURLWithPath:path]);
    AudioServicesPlaySystemSound(soundIDTest);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
