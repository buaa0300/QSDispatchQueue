//
//  ViewController.m
//  QSDispatchQueueDemo
//
//  Created by shaoqing on 2017/8/12.
//  Copyright © 2017年 Jiang. All rights reserved.
//

#import "ViewController.h"
#import "QSDispatchQueue.h"

@interface ViewController ()

@property (nonatomic,strong)UIButton *btn1;
@property (nonatomic,strong)UIButton *btn2;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    self.title = @"QSDispatchQueueDemo";
    
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [self.view addSubview:({
        _btn1 = [[UIButton alloc]initWithFrame:CGRectMake(15, 15, 200, 40)];
        [_btn1 addTarget:self action:@selector(testAsync) forControlEvents:UIControlEventTouchUpInside];
        [_btn1 setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        _btn1.titleLabel.font = [UIFont boldSystemFontOfSize:20];
        [_btn1 setTitle:@"异步调用" forState:UIControlStateNormal];
        _btn1;
    })];

    [self.view addSubview:({
        _btn2 = [[UIButton alloc]initWithFrame:CGRectMake(15, 100, 200, 40)];
        [_btn2 addTarget:self action:@selector(testSync) forControlEvents:UIControlEventTouchUpInside];
        [_btn2 setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        _btn2.titleLabel.font = [UIFont boldSystemFontOfSize:20];
        [_btn2 setTitle:@"同步调用" forState:UIControlStateNormal];
        _btn2;
    })];
}

- (void)testAsync{
    
    dispatch_queue_t workConcurrentQueue = dispatch_queue_create("com.jzp.async.queue", DISPATCH_QUEUE_CONCURRENT);
    QSDispatchQueue *queue = [[QSDispatchQueue alloc]initWithQueue:workConcurrentQueue concurrentCount:3];
    for (NSInteger i = 0; i < 10; i++) {
        [queue async:^{
            NSLog(@"thread-info:%@开始执行任务%d",[NSThread currentThread],(int)i);
            sleep(1);
            NSLog(@"thread-info:%@结束执行任务%d",[NSThread currentThread],(int)i);
        }];
    }
    NSLog(@"异步:主线程任务...");
}

- (void)testSync{
    
    dispatch_queue_t workConcurrentQueue = dispatch_queue_create("com.jzp.sync.queue", DISPATCH_QUEUE_CONCURRENT);
    QSDispatchQueue *queue = [[QSDispatchQueue alloc]initWithQueue:workConcurrentQueue concurrentCount:1];
    for (NSInteger i = 0; i < 10; i++) {
        [queue sync:^{
            NSLog(@"thread-info:%@开始执行任务%d",[NSThread currentThread],(int)i);
            sleep(1);
            NSLog(@"thread-info:%@结束执行任务%d",[NSThread currentThread],(int)i);
        }];
    }
    NSLog(@"异步:主线程任务...");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
