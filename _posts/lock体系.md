## 1、concurrent包的结构层次

包含两个子包：atomic以及lock，以及现相关的其他类。

## 2、AbstractQueueService(AQS)

AQS主要的实现思路，主要使用一个volatile 的 int 值（代表共享资源）和FIFO的双端队列来确保线程之间的并发等待，唤醒等功能。当前线程通过获取state状态信息，如果获取成功，那么就获得执行权直接运行，如果获取失败，那么直接将线程和状态信息，构造成一个Node节点，放入到双端队列中，阻塞当前线程。如果获取资源的线程执行执行完毕，将释放state，那么将唤醒等待的线程，去获取资源。

其中，队列的元素是一个Node节点，Node的属性主要有：

```java

static final class Node {
    int waitStatus;
    Node prev;
    Node next;
    Node nextWaiter;
    Thread thread;
    private volatile int state;

    ...
}

```

+ waitStatus：表示节点的状态，其中包含
  + CANCELLED：值为1，表示当前节点被取消；
  + SIGNAL：值为-1，表示当前节点的的后继节点将要或者已经被阻塞，在当前节点释放的时候需要unpark后继节点；
  + CONDITION：值为-2，表示当前节点在等待condition，即在condition队列中；
  + PROPAGATE：值为-3，表示releaseShared需要被传播给后续节点（仅在共享模式下使用）；
  + 无状态，表示当前节点在队列中等待获取锁。
+ prev：前继节点；
+ next：后继节点；
+ nextWaiter：存储condition队列中的后继节点；
+ thread：当前线程。

其中，队列里还有一个 **head节点** 和一个 **tail** 节点，分别表示头结点和尾节点，其中头结点不存储Thread，仅保存next结点的引用。

AQS中有一个 **state** 变量，该变量对不同的子类实现具有不同的意义，对ReentrantLock来说，它表示加锁的状态：

+ 无锁时state=0，有锁时state>0；
+ 第一次加锁时，将state设置为1；
+ 由于ReentrantLock是可重入锁，所以持有锁的线程可以多次加锁，当需要加锁的线程就是当前持有锁的线程时（即exclusiveOwnerThread==Thread.currentThread()），即可加锁，每次加锁都会将state的值+1，state等于几，就代表当前持有锁的线程加了几次锁;
+ 解锁时每解一次锁就会将state减1，state减到0后，锁就被释放掉，这时其它线程可以加锁；
+ 当持有锁的线程释放锁以后，如果是等待队列获取到了加锁权限，则会在等待队列头部取出第一个线程去获取锁，获取锁的线程会被移出队列；

## 2.1AQS的两种功能

从使用上来说，AQS的功能分为两种：独占和共享。跟共享锁比起来，独占锁的特点是：

+ 读锁和读锁可以共享
+ 写锁和读/写锁不能共享

#### 2.1.1 AQS独占锁的内部实现

###### 2.1.1.1 独占锁的加锁

我们通过 **ReentrantLock** 的实现来分析独占锁的实现

首先看一下lock方法：

```java

public void lock() {
        sync.lock();
    }

```

该方法调用了 sync 实例的lock方法，sync是ReentrantLock的内部类，它有两个子类 FairSync（公平锁） 和 NonfairSync（非公平锁）。

我们通过公平锁来看一下，先看下 FairSync 的定义：

```java

/**
 * Sync object for fair locks
 */
static final class FairSync extends Sync {
    private static final long serialVersionUID = -3000897897090466540L;

    final void lock() {
        acquire(1);
    }

    /**
     * Fair version of tryAcquire.  Don't grant access unless
     * recursive call or no waiters or is first.
     */
    protected final boolean tryAcquire(int acquires) {
        final Thread current = Thread.currentThread();
        // 获取state
        int c = getState();
        // state=0表示当前队列中没有线程被加锁
        if (c == 0) {
            /*
             * 首先判断是否有前继结点
             * 设置状态为acquires，即lock方法中写死的1（这里为什么不直接setState？因为可能同时有多个线程同时在执行到此处，所以用CAS来执行）；
             * 设置当前线程独占锁。
             */
            if (!hasQueuedPredecessors() &&
                compareAndSetState(0, acquires)) {
                setExclusiveOwnerThread(current);
                return true;
            }
        }
        /*
         * 如果state不为0，表示已经有线程独占锁了，这时还需要判断独占锁的线程是否是当前的线程，原因是由于ReentrantLock为可重入锁；
         * 如果独占锁的线程是当前线程，则将状态加1，并setState;
         * 这里为什么不用compareAndSetState？因为独占锁的线程已经是当前线程，不需要通过CAS来设置。
         */
        else if (current == getExclusiveOwnerThread()) {
            int nextc = c + acquires;
            if (nextc < 0)
                throw new Error("Maximum lock count exceeded");
            setState(nextc);
            return true;
        }
        return false;
    }
}

```

其中，acquire是AQS中的方法，代码如下：

```java

public final void acquire(int arg) {
    if (!tryAcquire(arg) &&
        acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
        selfInterrupt();
}

```

该方法主要工作如下：

+ 尝试获取独占锁；
+ 获取成功则返回，否则执行下一步;
+ addWaiter方法将当前线程封装成Node对象，并添加到队列尾部；
+ 自旋获取锁，并判断中断标志位。如果中断标志位为true，执行下一步，否则返回；
+ 设置线程中断。

其中，tryAcquire 方法在FairSync已经说明，我们接着看 addWaiter 方法：

```java

private Node addWaiter(Node mode) {
    // 根据当前线程创建一个Node对象
    Node node = new Node(Thread.currentThread(), mode);
    // Try the fast path of enq; backup to full enq on failure
    Node pred = tail;
    // 判断tail是否为空，如果为空表示队列是空的，直接enq
    if (pred != null) {
        node.prev = pred;
        // 这里尝试CAS来设置队尾，如果成功则将当前节点设置为tail，否则enq
        if (compareAndSetTail(pred, node)) {
            pred.next = node;
            return node;
        }
    }
    enq(node);
    return node;
}

private Node enq(final Node node) {
    // 重复直到成功
    for (;;) {
        Node t = tail;
        // 如果tail为null，则必须创建一个Node节点并进行初始化
        if (t == null) { // Must initialize
            if (compareAndSetHead(new Node()))
                tail = head;
        } else {
            node.prev = t;
            // 尝试CAS来设置队尾
            if (compareAndSetTail(t, node)) {
                t.next = node;
                return t;
            }
        }
    }
}

```

该方法就是根据当前线程创建一个Node，然后添加到队列尾部。

然后我们再看一下acquireQueued方法：

```java

final boolean acquireQueued(final Node node, int arg) {
    boolean failed = true;
    try {
        // 中断标志位
        boolean interrupted = false;
        for (;;) {
            // 获取前继节点
            final Node p = node.predecessor();
            // 如果前继节点是head，则尝试获取
            if (p == head && tryAcquire(arg)) {
                // 设置head为当前节点（head中不包含thread）
                setHead(node);
                // 清除之前的head
                p.next = null; // help GC
                failed = false;
                return interrupted;
            }
            // 如果p不是head或者获取锁失败，判断是否需要进行park
            if (shouldParkAfterFailedAcquire(p, node) &&
                parkAndCheckInterrupt())
                interrupted = true;
        }
    } finally {
        if (failed)
            cancelAcquire(node);
    }
}

//前继节点的状态是SIGNAL时，需要park
private static boolean shouldParkAfterFailedAcquire(Node pred, Node node) {
    int ws = pred.waitStatus;
    if (ws == Node.SIGNAL)
        /*
         * This node has already set status asking a release
         * to signal it, so it can safely park.
         */
        return true;
    if (ws > 0) {
        /*
         * Predecessor was cancelled. Skip over predecessors and
         * indicate retry.
         */
        do {
            node.prev = pred = pred.prev;
        } while (pred.waitStatus > 0);
        pred.next = node;
    } else {
        /*
         * waitStatus must be 0 or PROPAGATE.  Indicate that we
         * need a signal, but don't park yet.  Caller will need to
         * retry to make sure it cannot acquire before parking.
         */
        compareAndSetWaitStatus(pred, ws, Node.SIGNAL);
    }
    return false;
}

//阻塞当前线程，然后返回线程的中断状态并复为中断状态。
private final boolean parkAndCheckInterrupt() {
    LockSupport.park(this);
    return Thread.interrupted();
}

```

该方法的功能是循环的尝试获取锁，直到成功为止，最后返回中断标志位。

其中，park与wait的作用类似，但是对中断状态的处理并不相同。如果当前线程不是中断的状态，park与wait的效果是一样的；如果一个线程是中断的状态，这时执行wait方法会报java.lang.IllegalMonitorStateException，而执行park时并不会报异常，而是直接返回。

所以，知道了这一点，就可以知道为什么要进行中断状态的复位了：

+ 如果当前线程是非中断状态，则在执行park时被阻塞，这时返回中断状态是false；
+ 如果当前线程是中断状态，则park方法不起作用，会立即返回，然后parkAndCheckInterrupt方法会获取中断的状态，也就是true，并复位；
+ 再次执行循环的时候，由于在前一步已经把该线程的中断状态进行了复位，则再次调用park方法时会阻塞。
所以，这里判断线程中断的状态实际上是为了不让循环一直执行，要让当前线程进入阻塞的状态。想象一下，如果不这样判断，前一个线程在获取锁之后执行了很耗时的操作，那么岂不是要一直执行该死循环？这样就造成了CPU使用率飙升，这是很严重的后果。

在 acquireQueued 方法的finally语句块中，如果在循环的过程中出现了异常，则执行 cancelAcquire 方法，用于将该节点标记为取消状态。

```java

private void cancelAcquire(Node node) {
    // Ignore if node doesn't exist
    if (node == null)
        return;
    // 设置该节点不再关联任何线程
    node.thread = null;

    // Skip cancelled predecessors
    // 通过前继节点跳过取消状态的node
    Node pred = node.prev;
    while (pred.waitStatus > 0)
        node.prev = pred = pred.prev;

    // predNext is the apparent node to unsplice. CASes below will
    // fail if not, in which case, we lost race vs another cancel
    // or signal, so no further action is necessary.
    // 获取过滤后的前继节点的后继节点
    Node predNext = pred.next;

    // Can use unconditional write instead of CAS here.
    // After this atomic step, other Nodes can skip past us.
    // Before, we are free of interference from other threads.
    // 设置状态为取消状态
    node.waitStatus = Node.CANCELLED;

    /*
     * 1.如果当前节点是tail：
     * 尝试更新tail节点，设置tail为pred；
     * 更新失败则返回，成功则设置tail的后继节点为null
     */
    if (node == tail && compareAndSetTail(node, pred)) {
        compareAndSetNext(pred, predNext, null);
    } else {
        // If successor needs signal, try to set pred's next-link
        // so it will get one. Otherwise wake it up to propagate.
        int ws;
        /*
         * 2.如果当前节点不是head的后继节点：
         * 判断当前节点的前继节点的状态是否是SIGNAL，如果不是则尝试设置前继节点的状态为SIGNAL；
         * 上面两个条件如果有一个返回true，则再判断前继节点的thread是否不为空；
         * 若满足以上条件，则尝试设置当前节点的前继节点的后继节点为当前节点的后继节点，也就是相当于将当前节点从队列中删除
         */
        if (pred != head &&
            ((ws = pred.waitStatus) == Node.SIGNAL ||
             (ws <= 0 && compareAndSetWaitStatus(pred, ws, Node.SIGNAL))) &&
            pred.thread != null) {
            Node next = node.next;
            if (next != null && next.waitStatus <= 0)
                compareAndSetNext(pred, predNext, next);
        } else {
            // 3.如果是head的后继节点或者状态判断或设置失败，则唤醒当前节点的后继节点
            unparkSuccessor(node);
        }

        node.next = node; // help GC
    }
}

```

该方法中执行的过程有些复杂，首先是要获取当前节点的前继节点，如果前继节点的状态不是取消状态（即pred.waitStatus > 0），则向前遍历队列，直到遇到第一个waitStatus <= 0的节点，并把当前节点的前继节点设置为该节点，然后设置当前节点的状态为取消状态。

接下来的工作可以分为3种情况：

+ 当前节点是tail；
+ 当前节点不是head的后继节点（即队列的第一个节点，不包括head），也不是tail；
+ 当前节点是head的后继节点。
我们依次来分析一下：

当前节点是tail

这种情况很简单，因为tail是队列的最后一个节点，如果该节点需要取消，则直接把该节点的前继节点的next指向null，也就是把当前节点移除队列

当前节点不是head的后继节点，也不是tail

这里将node的前继节点的next指向了node的后继节点，真正执行的代码就是如下一行：

```java
compareAndSetNext(pred, predNext, next);
```

当前节点是head的后继节点

这里直接unpark后继节点的线程，然后将next指向了自己。

###### 2.1.1.2 独占锁的解锁

解锁通过 unlock 方法实现

```java

public void unlock() {
    sync.release(1);
}

//这里首先尝试着去释放锁，成功了之后要去唤醒后继节点的线程，这样其他的线程才有机会去执行。
public final boolean release(int arg) {
    // 尝试释放锁
    if (tryRelease(arg)) {
        // 释放成功后unpark后继节点的线程
        Node h = head;
        if (h != null && h.waitStatus != 0)
            unparkSuccessor(h);
        return true;
    }
    return false;
}

//释放锁
protected final boolean tryRelease(int releases) {
    // 这里是将锁的数量减1
    int c = getState() - releases;
    // 如果释放的线程和获取锁的线程不是同一个，抛出非法监视器状态异常
    if (Thread.currentThread() != getExclusiveOwnerThread())
        throw new IllegalMonitorStateException();
    boolean free = false;
    // 由于重入的关系，不是每次释放锁c都等于0，
    // 直到最后一次释放锁时，才会把当前线程释放
    if (c == 0) {
        free = true;
        setExclusiveOwnerThread(null);
    }
    // 记录锁的数量
    setState(c);
    return free;
}

//当前线程被释放之后，需要唤醒下一个节点的线程，通过unparkSuccessor方法来实现

private void unparkSuccessor(Node node) {
    /*
     * If status is negative (i.e., possibly needing signal) try
     * to clear in anticipation of signalling.  It is OK if this
     * fails or if status is changed by waiting thread.
     */
    int ws = node.waitStatus;
    if (ws < 0)
        compareAndSetWaitStatus(node, ws, 0);

    /*
     * Thread to unpark is held in successor, which is normally
     * just the next node.  But if cancelled or apparently null,
     * traverse backwards from tail to find the actual
     * non-cancelled successor.
     */
    Node s = node.next;
    if (s == null || s.waitStatus > 0) {
        s = null;
        for (Node t = tail; t != null && t != node; t = t.prev)
            if (t.waitStatus <= 0)
                s = t;
    }
    if (s != null)
        LockSupport.unpark(s.thread);
}

```

unparkSuccessor 主要功能就是要唤醒下一个线程，这里s == null || s.waitStatus > 0判断后继节点是否为空或者是否是取消状态，然后从队列尾部向前遍历找到最前面的一个waitStatus小于0的节点，至于为什么从尾部开始向前遍历，回想一下cancelAcquire方法的处理过程，cancelAcquire只是设置了next的变化，没有设置prev的变化，在最后有这样一行代码：node.next = node，如果这时执行了unparkSuccessor方法，并且向后遍历的话，就成了死循环了，所以这时只有prev是稳定的。

到这里，通过ReentrantLock的lock和unlock来分析AQS独占锁的实现已经基本完成了，但ReentrantLock还有一个非公平锁NonfairSync。

其实NonfairSync和FairSync主要就是在获取锁的方式上不同，公平锁是按顺序去获取，而非公平锁是抢占式的获取，lock的时候先去尝试修改state变量，如果抢占成功，则获取到锁：

```java

final void lock() {
    if (compareAndSetState(0, 1))
        setExclusiveOwnerThread(Thread.currentThread());
    else
        acquire(1);
}

```

非公平锁的tryAcquire方法调用了nonfairTryAcquire方法：

```java

final boolean nonfairTryAcquire(int acquires) {
    final Thread current = Thread.currentThread();
    int c = getState();
    if (c == 0) {
        if (compareAndSetState(0, acquires)) {
            setExclusiveOwnerThread(current);
            return true;
        }
    }
    else if (current == getExclusiveOwnerThread()) {
        int nextc = c + acquires;
        if (nextc < 0) // overflow
            throw new Error("Maximum lock count exceeded");
        setState(nextc);
        return true;
    }
    return false;
}

```

该方法比公平锁的tryAcquire方法在第二个if判断中少了一个是否存在前继节点判断。

![锁的获取](https://pic1.zhimg.com/80/v2-65f7bd7554ae41dce3bd649cbc859498_hd.jpg)

###### 2.1.1.3 可中断式获取锁（acquireInterruptibly方法）

与acquire方法逻辑几乎一致，唯一的区别是当parkAndCheckInterrupt返回true时即线程阻塞时该线程被中断，代码抛出被中断异常。

###### 2.1.1.4 超时等待式获取锁（tryAcquireNanos()方法）

通过调用lock.tryLock(timeout,TimeUnit)方式达到超时等待获取锁的效果，该方法会在三种情况下才会返回：
+ 在超时时间内，当前线程成功获取了锁；
+ 当前线程在超时时间内被中断；
+ 超时时间结束，仍未获得锁返回false。

源码为：

```java

public final boolean tryAcquireNanos(int arg, long nanosTimeout)
        throws InterruptedException {
    if (Thread.interrupted())
        throw new InterruptedException();
    return tryAcquire(arg) ||
        //实现超时等待的效果
        doAcquireNanos(arg, nanosTimeout);
}

private boolean doAcquireNanos(int arg, long nanosTimeout)
        throws InterruptedException {
    if (nanosTimeout <= 0L)
        return false;
    //1\. 根据超时时间和当前时间计算出截止时间
    final long deadline = System.nanoTime() + nanosTimeout;
    final Node node = addWaiter(Node.EXCLUSIVE);
    boolean failed = true;
    try {
        for (;;) {
            final Node p = node.predecessor();
            //2\. 当前线程获得锁出队列
            if (p == head && tryAcquire(arg)) {
                setHead(node);
                p.next = null; // help GC
                failed = false;
                return true;
            }
            // 3.1 重新计算超时时间
            nanosTimeout = deadline - System.nanoTime();
            // 3.2 已经超时返回false
            if (nanosTimeout <= 0L)
                return false;
            // 3.3 线程阻塞等待
            if (shouldParkAfterFailedAcquire(p, node) &&
                nanosTimeout > spinForTimeoutThreshold)
                LockSupport.parkNanos(this, nanosTimeout);
            // 3.4 线程被中断抛出被中断异常
            if (Thread.interrupted())
                throw new InterruptedException();
        }
    } finally {
        if (failed)
            cancelAcquire(node);
    }
}

```

程序逻辑为：

![超时等待式获取锁](https://pic4.zhimg.com/80/v2-990f19dd7feca0bd0270ac4aa8d1caf7_hd.jpg)

###### 2.1.1.4 共享锁

我们继续一鼓作气的来看看共享锁是怎样实现的？共享锁的获取方法为acquireShared，源码为：

```java

public final void acquireShared(int arg) {
    if (tryAcquireShared(arg) < 0)
        doAcquireShared(arg);
}

private void doAcquireShared(int arg) {
    final Node node = addWaiter(Node.SHARED);
    boolean failed = true;
    try {
        boolean interrupted = false;
        for (;;) {
            final Node p = node.predecessor();
            if (p == head) {
                int r = tryAcquireShared(arg);
                if (r >= 0) {
                    // 当该节点的前驱节点是头结点且成功获取同步状态
                    setHeadAndPropagate(node, r);
                    p.next = null; // help GC
                    if (interrupted)
                        selfInterrupt();
                    failed = false;
                    return;
                }
            }
            if (shouldParkAfterFailedAcquire(p, node) &&
                parkAndCheckInterrupt())
                interrupted = true;
        }
    } finally {
        if (failed)
            cancelAcquire(node);
    }
}

```

逻辑几乎和独占式锁的获取一模一样，这里的自旋过程中能够退出的条件是当前节点的前驱节点是头结点并且tryAcquireShared(arg)返回值大于等于0即能成功获得同步状态。

共享锁的释放（releaseShared()方法）：

```java

public final boolean releaseShared(int arg) {
    if (tryReleaseShared(arg)) {
        doReleaseShared();
        return true;
    }
    return false;
}

private void doReleaseShared() {
    /*
     * Ensure that a release propagates, even if there are other
     * in-progress acquires/releases.  This proceeds in the usual
     * way of trying to unparkSuccessor of head if it needs
     * signal. But if it does not, status is set to PROPAGATE to
     * ensure that upon release, propagation continues.
     * Additionally, we must loop in case a new node is added
     * while we are doing this. Also, unlike other uses of
     * unparkSuccessor, we need to know if CAS to reset status
     * fails, if so rechecking.
     */
    for (;;) {
        Node h = head;
        if (h != null && h != tail) {
            int ws = h.waitStatus;
            if (ws == Node.SIGNAL) {
                if (!compareAndSetWaitStatus(h, Node.SIGNAL, 0))
                    continue;            // loop to recheck cases
                unparkSuccessor(h);
            }
            else if (ws == 0 &&
                     !compareAndSetWaitStatus(h, 0, Node.PROPAGATE))
                continue;                // loop on failed CAS
        }
        if (h == head)                   // loop if head changed
            break;
    }
}

```

在共享式锁的释放过程中，对于能够支持多个线程同时访问的并发组件，必须保证多个线程能够安全的释放同步状态，这里采用的CAS保证，当CAS操作失败continue，在下一次循环中进行重试。

## 3、lock简介

在lock接口出现之前，Java程序主要是靠synchronized关键字实现锁功能，而JDK 1.5之后，并发包提供了lock接口，它虽然失去了synchronized关键字隐式加锁和解锁的便捷性，但是却拥有了对锁获取和释放的可操作性，可中断的获取锁和超时获取锁等。

> synchronized同步代码块执行完成或者遇到异常会自动释放锁，而lock必须调用unlock方法来释放锁。

#### 3.1 Lock接口API

```java
//获取锁
void lock()
//获取锁的过程能够响应中断
void lockInterruptibly() throws InterruptedException
//非阻塞式响应中断能立即返回，获取锁放回true反之返回fasle
boolean tryLock()
//超时获取锁，在超时内或者未中断的情况下能够获取锁
boolean tryLock(long time, TimeUnit unit) throws InterruptedException
//获取与lock绑定的等待通知组件，当前线程必须获得了锁才能进行等待，进行等待时会先释放锁，当再次获取锁时才能从等待中返回
Condition newCondition()
```
