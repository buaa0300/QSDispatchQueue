# QSDispatchQueue

**控制GCD并发队列最大并发数方案**

>####一、概述 ####

#####1、GCD并发的困扰#####

- 在GCD中有两种队列，分别是**串行队列**和**并发队列**。在**串行队列**中，同一时间只有一个任务在执行，不能充分利用多核 CPU 的资源，效率较低。

- **并发队列**可以分配多个线程，同时处理不同的任务；效率虽然提升了，但是**多线程的并发**是用**时间片轮转**方法实现的，线程创建、销毁、上下文切换等会消耗CPU 资源。

- 目前iPhone的处理器是多核（2个、4个），适当的并发可以提高效率，但是无节制地并发，如将大量任务不加思索就用并发队列来执行，这只会大量增加线程数，抢占CPU资源，甚至会挤占掉主线程的 CPU 资源（极端情况）。

- 此外，提交给并发队列的任务中，有些任务内部会有全局的锁（如 CoreText 绘制时的 CGFont 内部锁），会导致线程休眠、阻塞；一旦这类任务多，并发队列还需要创建新的线程来执行其他任务；这种情况下，线程数大量增加是避免不了的。

#####2、优雅的NSOperationQueue#####

- NSOperationQueue是iOS提供的工作队列，开发者只需要将任务封装在NSOperation的子类（NSBlockOperation、NSInvocationOperation或自定义NSOperation子类）中，然后添加进NSOperationQueue队列，队列就会按照优先顺序及工作的从属依赖关系(如果有的话)组织执行。

- NSOperationQueue中，已经考虑到了最大并发数的问题，并提供了**maxConcurrentOperationCount**属性**设置最大并发数**(该属性需要在任务添加到队列中之前进行设置)。maxConcurrentOperationCount默认值是-1；如果值设为0，那么不会执行任何任务；如果值设为1，那么该队列是串行的；如果大于1，那么是并行的。

      NSOperationQueue *queue = [[NSOperationQueue alloc]init]；
      queue.maxConcurrentOperationCount = 2;
      //添加Operation任务...

- 第三方库如SDWebImage库和AFNetworking 中就是采用NSOperationQueue来控制最大并发数的。

**说明**：NSOperationQueue使用详见[多线程编程3 - NSOperationQueue](http://blog.csdn.net/q199109106q/article/details/8566222) 和 [NSOperation](http://www.cnblogs.com/xufengyuan/p/7119104.html)

#####3、我们该怎么办#####

- GCD多线程方案很优秀，在iOS 4 与 MacOS X 10.6之后，NSOperationQueue的底层就是用GCD来实现的。

- NSOperationQueue在控制最大并发数上的确很方便，但是GCD也提供了某些机制可以实现控制最大并发数的效果。

- 开发中NSOperationQueue和GCD都可以用，视场景而定（个人更喜欢用GCD）。

>####二、QSDispatchQueue方案 ####

#####1、GCD的信号量机制(dispatch_semaphore）####

- **信号量**是一个整型值，有初始计数值；可以接收**通知信号**和**等待信号**。当信号量收到通知信号时，计数+1；当信号量收到等待信号时，计数-1；如果信号量为0，线程会被阻塞，直到信号量大于0，才会继续下去。

- 使用信号量机制可以实现线程的同步，也可以控制最大并发数。以下是如何控制最大并发数的代码。

      dispatch_queue_t workConcurrentQueue = dispatch_queue_create("cccccccc", DISPATCH_QUEUE_CONCURRENT);
      dispatch_queue_t serialQueue = dispatch_queue_create("sssssssss",DISPATCH_QUEUE_SERIAL);
      dispatch_semaphore_t semaphore = dispatch_semaphore_create(3);
    
      for (NSInteger i = 0; i < 10; i++) {
        dispatch_async(serialQueue, ^{
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            dispatch_async(workConcurrentQueue, ^{
                NSLog(@"thread-info:%@开始执行任务%d",[NSThread currentThread],(int)i);
                sleep(1);
                NSLog(@"thread-info:%@结束执行任务%d",[NSThread currentThread],(int)i);
                dispatch_semaphore_signal(semaphore);});
        });
      }
      NSLog(@"主线程...!");

![执行结果.png](http://upload-images.jianshu.io/upload_images/201701-94be44025dcd8025.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1080)

**说明**：从执行结果中可以看出，虽然将10个任务都异步加入了并发队列，但是信号量机制控制了最大线程并发数，始终是3个线程在执行任务。此外，这些任务也没有阻塞主线程。

>#####2、QSDispatchQueue方案的实现####

1）直接在代码中使用GCD的信号量，不够优雅，代码也很冗余；基于此，QSDispatchQueue方案出来了。(代码很简单，一共两个文件)

2）QSDispatchQueue方法声明如下：

    //QSDispatchQueue.h
    @interface QSDispatchQueue : NSObject

    #pragma mark - main queue + global queue
    /**
     全局并发队列的最大并发数，默认4
     */
    + (QSDispatchQueue *)mainThreadQueue;

    + (QSDispatchQueue *)defaultGlobalQueue;

    + (QSDispatchQueue *)lowGlobalQueue;

    + (QSDispatchQueue *)highGlobalQueue;

    + (QSDispatchQueue *)backGroundGlobalQueue;

    #pragma mark -
    @property (nonatomic,assign,readonly)NSUInteger concurrentCount;

    - (instancetype)init;

    /**
     默认最大并发数是1
     @param queue 并发队列
     */
    - (instancetype)initWithQueue:(dispatch_queue_t)queue;

    /**
     @param queue 并发队列
     @param concurrentCount 最大并发数，应大于1
     */
    - (instancetype)initWithQueue:(dispatch_queue_t)queue
                  concurrentCount:(NSUInteger)concurrentCount;

    //同步
    - (void)sync:(dispatch_block_t)block;

    //异步
    - (void)async:(dispatch_block_t)block;

    @end

>#####3、QSDispatchQueue方案的使用####

    dispatch_queue_t workConcurrentQueue = dispatch_queue_create("cccccccc", DISPATCH_QUEUE_CONCURRENT);
    QSDispatchQueue *queue = [[QSDispatchQueue alloc]initWithQueue:workConcurrentQueue concurrentCount:3];
    for (NSInteger i = 0; i < 10; i++) {
        [queue async:^{
            NSLog(@"thread-info:%@开始执行任务%d",[NSThread currentThread],(int)i);
            sleep(1);
            NSLog(@"thread-info:%@结束执行任务%d",[NSThread currentThread],(int)i);
        }];
    }
    NSLog(@"主线程任务...");

执行结果如下图：

![QSDispatchQueue方案执行结果.png](http://upload-images.jianshu.io/upload_images/201701-f5be87ede6fc5a25.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1080)

**说明**：从执行结果中来看，通过QSDispatchQueue方案也到达了最大线程并发数的目的。

- 使用QSDispatchQueue方案，代码更简洁，让开发者不用去时刻注意信号量的处理，只关注任务即可。

>####三、小结 ####

- 在iOS开发中，我们常将耗时任务提交给GCD的并发队列，但是并发队列并不会去管理最大并发数，无限制提交任务给并发队列，会给性能带来问题。

- YYKit组件中的[YYDispatchQueuePool](https://github.com/ibireme/YYDispatchQueuePool) 也能控制并发队列的并发数；其思路是为不同优先级创建和 CPU 数量相同的 serial queue，每次从 pool 中获取 queue 时，会轮询返回其中一个 queue。

- QSDispatchQueue是使用信号量让并发队列中的**任务并发数**得到抑制；YYDispatchQueuePool是让**一定数量的串行队列**代替并发队列，避开了并发队列不好控制并发数的问题。

>####End ####

-  **相关文章**

	[iOS实录13：GCD使用小结](http://www.jianshu.com/p/e1784f8172c0)

	[iOS实录16：GCD小结之控制最大并发数](http://www.jianshu.com/p/5d51a367ed62)


- 我是[南华coder](http://www.jianshu.com/u/7d197f08438f)，一名北漂的初级iOS程序猿。**iOS实(践)录系列**是我的一点开发心得，希望能够抛砖引玉。