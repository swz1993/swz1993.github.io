这周赶项目，暂停了一下微博。结果今天看到简书app的图标竟然有负罪感！趁着周末，更新一波。。。

从本文开始，我们开始分析一个新的Java的知识点--多线程。要研究这个，首先我们要知道，什么是线程。

## 线程的定义

**进程**是指一个内存中运行的应用程序，每个进程都有自己独立的一块内存空间，拥有自己的数据和代码。
 
**线程**是指进程中的一个任务，一个进程中可以运行多个线程。线程是属于某个进程，进程中的多个线程共享此进程的内存。

拿手机举个例子，我们拿着手机可以一边听歌一边看微信，此时，微信和听歌软件就构成了多进程。即同一时刻，有不同的进程在工作。而多线程就是指在同一个程序中，同时执行多个任务，通常，每个任务称为一个线程。线程跟进程的区别是，每个进程都有自己独立的数据空间，而同一类的线程共享数据。多进程是为了提高CPU的使用率，而多线程是为了提高应用程序的使用率。

## 线程的状态

线程的状态如下：

![](https://images0.cnblogs.com/blog/497634/201312/18152411-a974ea82ebc04e72bd874c3921f8bfec.jpg)

线程的状态分为五种：

**新建状态**：当使用某种方式创建一个线程对象后，该线程就是新建状态

**就绪状态**：当已创建的线程的start()方法被调用后，就进入就绪状态。这种状态也叫做"可执行状态"。在这种状态下，该线程随时等待被CPU调度执行(注意，这个时候不是立即执行，而是等待CPU的调度)。

**可运行状态**：在Java虚拟机中执行的线程处于此状态。即线程取得CPU的权限，开始执行。线程只能从就绪状态进入运行状态。(在任何给定时刻，一个可运行的线程可能正在运行也可能没有运行)

**阻塞状态**：当线程因为某种关系，无法获得CPU的使用权限时，就处于这种状态。比如调用的wait()方法(等待)、有同步锁(阻塞)及调用了sleep()方法(计时等待)等。

**死亡状态**：以退出的线程处于此状态。退出可能是线程执行完毕，或者是发生了异常等。

当一个线程开始运行的时候，它并不是始终运行的。因为Java中多线程是抢占式调度，即多个线程抢占时间片来执行任务。当一个线程的时间片用完后，它就会被系统剥夺其运行权限，并与其他线程共同争夺下一个时间片的使用权。

## 线程的创建

创建线程的方式有：继承Thread类、实现Runnable接口及通过Callable和Future新建一个线程。

### 继承Thread类

创建的步骤为：

1、继承Thread类

2、重写run方法

3、实例化我们写的Thread类的子类，并调用start方法启动线程

具体代码如下：

```
//继承Thread类
public class MyThread extends Thread{

   //重写run方法(线程的执行部分)
   @Override
    public void run() {
       //自己的代码逻辑
       ........
    }

}

public class Main{

    public static void main(String [] args){
    
        //实例化一个MyThread类的子类
        MyThread myThread = new MyThread();
        //调用start方法启动线程
        myThread.start();
        
    }

}
```

### 实现Runnable接口

创建步骤为：

1、定义一个类，实现Runnable接口，重写run方法；

2、创建一个Runnable的实现类的实例，并以此为参数创建一个Thread类

3、调用Thread类的start方法，启动线程

>还可以创建一个实现Runnable接口的匿名类，或者创建一个实现Runnable接口的Java Lambda表达式(JDK8之后)。

具体代码如下：

```
//定义一个类，实现Runnable接口
public class MyRunnable implements Runnable {

    //重写run方法
    @Override
    public void run() {
        //自己的代码逻辑
        .......
    }
}

public class Main{

    public static void main(String [] args){
    
        //实例化一个Runnable实现类的实例
        MyRunnable myRunnable = new MyRunnable();
        //以myRunnable为参数实例化一个Thread类
        Thread thread = new Thread(myRunnable);
        //调用start方法启动线程
        thread();
        
        /**
          *--------分割线------
          */
          //创建Runnable的匿名实现
          Runnable myRunnable =new Runnable(){
                public void run(){
                     //自己的代码逻辑
                      .......                 
                      }
              }
             
          //Runnable的Lambda实现
          Runnable runnable =() -> { //自己的代码逻辑};      
        
}
```

>注意：

>1、使用"myThread.run();"时，run()方法并非是由刚创建的新线程执行，而是被创建新线程的当前线程所执行了。想要让创建的新线程执行run()方法，必须调用新线程的start()方法。且start()方法不可以多次调用。

>2、调用start()方法后，并不是让线程立刻执行，而是将线程变为可执行状态，等待CPU的调度。

**问题来了，当用此方式创建线程后，线程执行的run()方法是Runnable接口中的还是Thread类中的？**

我们看一下Thread类的定义及其run()方法：

```
public class Thread implements Runnable {

private Runnable target;

public Thread(Runnable target) {
        init(null, target, "Thread-" + nextThreadNum(), 0);
    }
    
private void init(ThreadGroup g, Runnable target, String name, long stackSize) {
       ......
        this.target = target;
       ......
    }

@Override
public void run() {
    if (target != null) {
        target.run();
     }
  }

}
```
可以看到，在run()方法中，会判断target是否为空，不为空则执行Runnable的run()方法，否则此方法不执行任何操作并返回。也是因为如此，Java提示Thread的子类要重写此方法。

实现Runnable接口比继承Thread类的优势：

1、避免了Java中的单继承限制

2、适合多个相同的程序代码的线程去处理同一个共享资源

3、代码可以被多个线程共享且代码和数据独立，增加了程序的健壮性

### 通过Callable和FutureTask

创建步骤为：

1、创建一个Callable接口的实现类，并实现call()方法

2、使用FutureTask类包装Callable实现类的对象，封装了Callable的call()方法的返回值

3、以FutureTask对象为Thread的参数创建线程，并启动线程

4、调用FutureTask对象的get()方法，获取线程执行结束后的返回值

代码如下：

```
//创建一个Callable接口的实现类，并实现call()方法
public class MyThread implements Callable<Integer> {

    @Override
    public Integer call() throws Exception {
        //自己的代码逻辑
        return value;
    }
}

public class Main{

    public static void main(String [] args){
    
        //使用FutureTask类包装Callable实现类的对象
        MyThread myThread = new MyThread();

        FutureTask futureTask = new FutureTask<Integer>(myThread);

        //以FutureTask对象为Thread的参数创建线程
        Thread thread = new Thread(futureTask);

        thread.start();  
        
        //获取值
        try {
            //get()方法会阻塞，直到子线程执行结束才返回
            int x = (int) futureTask.get();
        } catch (InterruptedException e) {
            e.printStackTrace();
        } catch (ExecutionException e) {
            e.printStackTrace();
        }      
    }

}
```
其中，Callable的类型参数为返回值的类型，Future保存异步计算的结果。

>在计算过程中，可以使用isDone方法判断Future任务是否结束(包括正常结束或者中途退出)，返回true表示完成，返回false表示未完成。可以用cancal方法取消计算。

一般推荐使用实现Runable或Callable接口的方式来创建多线程。因为这样既可以继承其他类，而且多线程可以共享一个target，即多线程可以共同处理同一份资源。

## 线程的优先级及守护线程

### 线程优先级

每个线程都有优先级，且默认情况下，线程**继承其父类**的优先级。我们可以使用setPriority方法为线程设置优先级。可以将线程的优先级设置在MIN_PRIORITY(1)和MAX_PRIORITY(10)之间。NORM_PRIORITY表示线程优先级为5，为默认优先级。数字越大，表示优先级越高。高优先级的线程被CPU调用的概率大于低优先级的线程。不过要注意的是线程优先级无法保证线程的执行顺序，它是依赖于平台的。比如在Linux下，线程优先级仅适用于Java6之后，在这之前线程优先级没有作用。

### 守护线程
在Java中，线程可以分为用户线程和守护线程，可以使用Thread类的setDaemon方法将一个线程设置为守护线程。守护线程在后台运行，当JVM中没有其他非守护线程时，守护线程会和JVM一起结束。守护线程的作用是为其他线程提供服务，比如我们熟悉的GC就是这样。要注意的是，不要用守护线程访问文件或数据库等资源。因为守护线程可能在任何时候发生中断，而这个时候，我们对资源文件的读写有可能还没有完成。

>有时候主线程都结束了，守护线程还在执行，这是因为线程结束是需要时间的。	

## Thread类的部分方法

### start()方法

start方法为将线程由新建状态转变为可运行状态，其源码如下：

```
//表示Java线程状态的工具，初始化为线程未启动
private volatile int threadStatus = 0;

//线程是否运行的标志
boolean started = false;

//此线程的线程组
private ThreadGroup group;

public synchronized void start() {

        //判断线程是否未启动或者已经运行，满足一项则抛出异常
        if (threadStatus != 0 || started)
            throw new IllegalThreadStateException();

        //添加次线程到其线程组
        group.add(this);
        
        //将运行状态置为false
        started = false;
        try {
        	  //调用本地方法启动线程
            nativeCreate(this, stackSize, daemon);
            //将线程的运行状态置为true
            started = true;
        } finally {
            try {
            	   //如果启动失败，从其线程组中移除此线程
            	   //此线程组的状态将回滚，就像从未尝试启动线程一样。该线程再次被视为线程组的未启动成员，允许随后尝试启动该线程。
                if (!started) {
                    group.threadStartFailed(this);
                }
            } catch (Throwable ignore) {
                            }
        }
    }
```
可以看到，当一个线程是未启动或者已运行时，调用start方法将抛出异常。当线程启动失败后，会将其从线程组中移除，以让其有机会重新启动。
				
### sleep()方法

使当前正在执行的线程休眠(暂时停止执行)，该线程不会失去任何监视器的所有权。源码如下：

```
private static final int NANOS_PER_MILLI = 1000000;

public static void sleep(long millis) throws InterruptedException {
     
        Thread.sleep(millis, 0);
    }

//实际调用的方法    
public static void sleep(long millis, int nanos)
    throws InterruptedException {
        //判断传入的毫秒和纳秒是否有错误
        if (millis < 0) {
            throw new IllegalArgumentException("millis < 0: " + millis);
        }
        if (nanos < 0) {
            throw new IllegalArgumentException("nanos < 0: " + nanos);
        }
        if (nanos > 999999) {
            throw new IllegalArgumentException("nanos > 999999: " + nanos);
        }
        //零睡眠
        if (millis == 0 && nanos == 0) {
            //如果线程为中断状态，则抛出异常并返回
            if (Thread.interrupted()) {
              throw new InterruptedException();
            }
            return;
        }
        //返回运行的Java虚拟机的高分辨率时间源的当前值，以纳秒计。
        long start = System.nanoTime();
        //将传入的时间转为纳秒级
        long duration = (millis * NANOS_PER_MILLI) + nanos;
		 //获取锁
        Object lock = currentThread().lock;

        //等待可能会提前返回，所以循环直到睡眠时间结束。
        synchronized (lock) {
            while (true) {
                //调用本地方法
                sleep(lock, millis, nanos);

                long now = System.nanoTime();
                long elapsed = now - start;

                if (elapsed >= duration) {
                    break;
                }

                duration -= elapsed;
                start = now;
                millis = duration / NANOS_PER_MILLI;
                nanos = (int) (duration % NANOS_PER_MILLI);
            }
        }
    }
```
由上面的源码可以看出，我们最终调用的是sleep(long millis, int nanos)方法。在sleep方法中，是通过循环不断判断当前时间跟起始时间的差值，直到这个值大于等于我们传入的休眠时间，则线程可以继续工作。在此期间，当前线程为阻塞状态。

### yield()方法

线程执行此方法的作用是暂停当前正在执行的线程，使其他具有相同优先级的线程获得运行的机会。但是在实际中，我们不能保证其功能可以完全实现，因为yield是将线程从运行状态变为可运行状态，在这种情况下，当前线程可能会被CPU再次选中。此方法为本地方法，jdk中源码如下：

```
public static native void yield();
```

### join()方法

此方法为让一个线程加入到另一个线程的后面，在前面的线程没有结束的时候，后面的线程不被执行。调用此方法会导致线程栈发生变化，当然，这些变化都是瞬时的。

```
//负责此线程的join / sleep / park操作的同步对象
private final Object lock = new Object();

public final void join() throws InterruptedException {
        //调用join(long millis)方法
        join(0);
    }
    
public final void join(long millis, int nanos)
    throws InterruptedException {
        synchronized(lock) {
        //判断传入的参数是否正确
        if (millis < 0) {
            throw new IllegalArgumentException("timeout value is negative");
        }

        if (nanos < 0 || nanos > 999999) {
            throw new IllegalArgumentException(
                                "nanosecond timeout value out of range");
        }
        //根据条件判断millis是否要加1
        if (nanos >= 500000 || (nanos != 0 && millis == 0)) {
            millis++;
        }
 		  //调用join(long millis)方法
        join(millis);
        }
    }
 
//真正被调用的方法    
public final void join(long millis) throws InterruptedException {
        synchronized(lock) {
        //返回当前时间
        long base = System.currentTimeMillis();
        long now = 0;
		  //判断传入的参数是否正确
        if (millis < 0) {
            throw new IllegalArgumentException("timeout value is negative");
        }
		  //以下就是根据isAlive(线程是否存活)，调用wait方法的循环
        if (millis == 0) {
            while (isAlive()) {
                lock.wait(0);
            }
        } else {
            while (isAlive()) {
                long delay = millis - now;
                if (delay <= 0) {
                    break;
                }
                lock.wait(delay);
                now = System.currentTimeMillis() - base;
            }
        }
        }
    }      
```
wait()方法的作用：导致当前线程等待，直到另一个线程调用此对象的notify()方法或notifyAll()方法或指定的等待时间已经过去。  

由源码可知，我们可以自己设置等待时间。但是如果我们不设置等待时间或者设置的等待时间为0，则线程会永远等待。直到被其join的线程结束后，会调用this.notifyAll方法，使其结束等待。

## 未捕获异常处理器

UncaughtExceptionHandler：是在Java Thread类中定义的，当Thread由于**未捕获的异常**而突然终止时调用的处理程序接口。这个接口只有一个方法：

```
//当给定线程由于给定的未捕获异常而终止时调用的方法。Java虚拟机将忽略此方法抛出的任何异常
void uncaughtException(Thread t, Throwable e);
```

当一个线程由于未捕获的异常而即将终止时，Java虚拟机将使用getUncaughtExceptionHandler向线程查询其UncaughtExceptionHandler并将调用处理程序的uncaughtException方法，将线程和异常作为参数传递。
如果某个线程没有显式设置其UncaughtExceptionHandler，则其ThreadGroup对象将充当其UncaughtExceptionHandler。如果ThreadGroup对象没有处理异常的特殊要求，它可以将调用转发到getDefaultUncaughtExceptionHandler默认的未捕获异常处理程序。我们可以用setUncaughtExceptionHandler方法为任何线程设置一个处理器。也可以用Thread类的静态方法setDefaultUncaughtExceptionHandler为所有线程设置一个默认的处理器。我们可以实现Thread.UncaughtExceptionHandler接口并重写其uncaughtException方法来自定义一个未捕获异常处理器。

## 小结

本文主要是简单的介绍一下线程的相关概念，使大家对线程有基本的了解。本文中涉及到的锁及介绍的相关方法，会在后期的分析中一一讲解。

