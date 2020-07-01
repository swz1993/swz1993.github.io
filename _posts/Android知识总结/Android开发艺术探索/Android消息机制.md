Android 消息机制主要是指 Handler 的运行机制，Handler 运行机制需要底层的 MessageQueue 和 Looper 支撑。 MessageQueue 即消息队列，它以单链表的数据结构来存储数据，对外提供插入和删除的操作。 Looper 为轮询器，会以无限循环的模式去查询是否有新的消息，有的话就处理，没有就等待。 ThreadLocal 可以在不同的线程之间互不干扰的存取数据，通过ThreadLocal可以获得每个线程的 Lopper。线程默认是没有 Lopper 的，如果使用 Handler 就必须为线程添加 Lopper。

## 1、Android 消息机制概述

Handler 的作用是将一个任务切换到指定的线程中去执行，Handler 创建时会采用当前线程的 Looper 来构造内部的消息循环系统，如果当前线程没有 Lopper 就会报错。

```java

public Handler(Callback callback, boolean async) {
    if (FIND_POTENTIAL_LEAKS) {
        final Class<? extends Handler> klass = getClass();
        if ((klass.isAnonymousClass() || klass.isMemberClass() || klass.isLocalClass()) &&
                (klass.getModifiers() & Modifier.STATIC) == 0) {
            Log.w(TAG, "The following Handler class should be static or leaks might occur: " +
                klass.getCanonicalName());
        }
    }

    //获取当前线程的Lopper
    mLooper = Looper.myLooper();
    if (mLooper == null) {
        throw new RuntimeException(
            "Can't create handler inside thread that has not called Looper.prepare()");
    }
    //根据lopper获取messageQueue
    mQueue = mLooper.mQueue;
    mCallback = callback;
    mAsynchronous = async;
}

//Looper 中的方法及属性
//从ThreadLocal中获取当前线程的Lopper
static final ThreadLocal<Looper> sThreadLocal = new ThreadLocal<Looper>();
public static @Nullable Looper myLooper() {
        return sThreadLocal.get();
    }

```

Handler 创建完成后就为其绑定了一个 Looper 和 MessageQueue。然后通过 Handler 的 post 方法将一个 Runnable 投递到 Handler 内部的 Looper 中去处理，也可以通过 Handler 的 send 方法发送一个消息，这个消息也是在 Looper 中去处理，其实 post 方法 最终也是通过调用 send 方法来完成的。当 Handeler 的 send 方法被调用时，它会调用 MessageQueue 的 enqueueMessage 方法将这个消息放入队列中，然后 Looper 发现有新的消息来了就会处理它，最终消息中的 Runnable 或者 Handler 的 handlerMessage 方法就会被调用。 Looper 是运行在创建 Handelr 所在的线程中的，这样一来， Handler 中的业务逻辑就被切换到创建 Handler 所在的线程中去执行了。

## 2、Android 消息机制分析

#### 2.1、ThreadLocal 的工作原理

ThreadLocal 是一个线程内部的数据存储类，通过它可以在指定的线程内存储数据，并且存储的数据只对存储线程可见。一般来说，当某些数据是以线程为作用域并且不同的线程有不同的数据副本时可以考虑 ThreadLocal。比如我们上面说的 Looper 就是。

ThreadLocal 之所以可以达到这种效果是因为每个线程都有一个保存值的 ThreadLocalMap 对象，ThreadLocal 的值就存放在了当前线程的 ThreadLocalMap 成员变量中，所以只能在本线程访问，其他线程不能访问。其中，key 为当前的 ThreadLocal 对象。

那其工作原理呢？我们看一下它的 set 和 get 方法：

```java

public void set(T value) {
     Thread t = Thread.currentThread();
     ThreadLocalMap map = getMap(t);
     if (map != null)
         map.set(this, value);
     else
         createMap(t, value);
    }

ThreadLocalMap getMap(Thread t) {
        return t.threadLocals;
    }

void createMap(Thread t, T firstValue) {
        t.threadLocals = new ThreadLocalMap(this, firstValue);
    }


public T get() {
        Thread t = Thread.currentThread();
        ThreadLocalMap map = getMap(t);
        if (map != null) {
        ThreadLocalMap.Entry e = map.getEntry(this);
        if (e != null) {
               @SuppressWarnings("unchecked")
               T result = (T)e.value;
               return result;
            }
        }
        return setInitialValue();
    }

private T setInitialValue() {
    T value = initialValue();
    Thread t = Thread.currentThread();
    ThreadLocalMap map = getMap(t);
    if (map != null)
        map.set(this, value);
    else
        createMap(t, value);
    return value;
 }

```

由此我们可以看出，set 和 get 方法操作的是一个 ThreadLocalMap 对象，ThreadLocalMap 是 Thread 的静态内部类，是线程私有的，因此在不同的线程中访问同一个 ThreadLoca 的 get 和 set 方法，它们对 ThreadLocal 所做的读/写操作仅限于各个线程美不。我们看一下 ThreadLocalMap 几个主要的属性和方法：

```java

static class ThreadLocalMap {

        /**
         *此哈希映射中的条目使用其主要引用字段作为键（始终是ThreadLocal对象）
         *扩展WeakReference。 请注意，空键（即entry.get（）== null）意味着
         *不再引用该键，因此可以从表中删除该条目。 在下面的代码中，
         *此类条目称为“陈旧条目”。
         */
        static class Entry extends WeakReference<ThreadLocal<?>> {
            /** The value associated with this ThreadLocal. */
            Object value;

            Entry(ThreadLocal<?> k, Object v) {
                super(k);
                value = v;
            }
        }

        /**
         * The initial capacity -- MUST be a power of two.
         */
        private static final int INITIAL_CAPACITY = 16;

        /**
         * The table, resized as necessary.
         * table.length MUST always be a power of two.
         */
        private Entry[] table;

        ...

        /**
         * Set the resize threshold to maintain at worst a 2/3 load factor.
         */
        private void setThreshold(int len) {
            threshold = len * 2 / 3;
        }

        /**
         * Increment i modulo len.
         */
        private static int nextIndex(int i, int len) {
            return ((i + 1 < len) ? i + 1 : 0);
        }

        /**
         * Decrement i modulo len.
         */
        private static int prevIndex(int i, int len) {
            return ((i - 1 >= 0) ? i - 1 : len - 1);
        }

        /**
         * Construct a new map initially containing (firstKey, firstValue).
         * ThreadLocalMaps是延迟构造的，因此只有在至少要放置一个条目时才创建一个。
         */
        ThreadLocalMap(ThreadLocal<?> firstKey, Object firstValue) {
            table = new Entry[INITIAL_CAPACITY];
            int i = firstKey.threadLocalHashCode & (INITIAL_CAPACITY - 1);
            table[i] = new Entry(firstKey, firstValue);
            size = 1;
            setThreshold(INITIAL_CAPACITY);
        }

        private void setThreshold(int len) {
                    threshold = len * 2 / 3;
                }

        /**
         * Get the entry associated with key.  This method
         * itself handles only the fast path: a direct hit of existing
         * key. It otherwise relays to getEntryAfterMiss.  This is
         * designed to maximize performance for direct hits, in part
         * by making this method readily inlinable.
         *
         * @param  key the thread local object
         * @return the entry associated with key, or null if no such
         */
        private Entry getEntry(ThreadLocal<?> key) {
            int i = key.threadLocalHashCode & (table.length - 1);
            Entry e = table[i];
            if (e != null && e.get() == key)
                return e;
            else
                return getEntryAfterMiss(key, i, e);
        }

        /**
         * Set the value associated with key.
         *
         * @param key the thread local object
         * @param value the value to be set
         */
        private void set(ThreadLocal<?> key, Object value) {

            // We don't use a fast path as with get() because it is at
            // least as common to use set() to create new entries as
            // it is to replace existing ones, in which case, a fast
            // path would fail more often than not.

            Entry[] tab = table;
            int len = tab.length;
            int i = key.threadLocalHashCode & (len-1);

            for (Entry e = tab[i];
                 e != null;
                 e = tab[i = nextIndex(i, len)]) {
                ThreadLocal<?> k = e.get();

                if (k == key) {
                    e.value = value;
                    return;
                }

                if (k == null) {
                    replaceStaleEntry(key, value, i);
                    return;
                }
            }

            tab[i] = new Entry(key, value);
            int sz = ++size;
            if (!cleanSomeSlots(i, sz) && sz >= threshold)
                rehash();
        }

        /**
         * Remove the entry for key.
         */
        private void remove(ThreadLocal<?> key) {
            Entry[] tab = table;
            int len = tab.length;
            int i = key.threadLocalHashCode & (len-1);
            for (Entry e = tab[i];
                 e != null;
                 e = tab[i = nextIndex(i, len)]) {
                if (e.get() == key) {
                    e.clear();
                    expungeStaleEntry(i);
                    return;
                }
            }
        }

      ...

    }

```

我们可以看到，在 ThreadLocalMap 中存放着一个 Entry[] table 数组，ThreadLocal 的值就存放在这里。

#### 2.2、消息队列的工作原理

这里的消息队列值的是  MessageQueue ， MessageQueue 主要包含两个操作：插入和读取。其中，读取操作本身会伴随着删除操作。插入和读取对应的方法分别为 enqueueMessage 和 next，其中，enqueueMessage 的作用是往消息队列中插入一条消息，而 next 的作用是从消息队列中取出一条消息并将其从消息队列中移除。

下面我们来看一下它的 enqueueMessage 方法：

```java

boolean enqueueMessage(Message msg, long when) {
        if (msg.target == null) {
            throw new IllegalArgumentException("Message must have a target.");
        }
        if (msg.isInUse()) {
            throw new IllegalStateException(msg + " This message is already in use.");
        }

        synchronized (this) {
            if (mQuitting) {
                IllegalStateException e = new IllegalStateException(
                        msg.target + " sending message to a Handler on a dead thread");
                Log.w(TAG, e.getMessage(), e);
                msg.recycle();
                return false;
            }

            msg.markInUse();
            msg.when = when;
            Message p = mMessages;
            boolean needWake;
            if (p == null || when == 0 || when < p.when) {
                // New head, wake up the event queue if blocked.
                msg.next = p;
                mMessages = msg;
                needWake = mBlocked;
            } else {
                // Inserted within the middle of the queue.  Usually we don't have to wake
                // up the event queue unless there is a barrier at the head of the queue
                // and the message is the earliest asynchronous message in the queue.
                needWake = mBlocked && p.target == null && msg.isAsynchronous();
                Message prev;
                for (;;) {
                    prev = p;
                    p = p.next;
                    if (p == null || when < p.when) {
                        break;
                    }
                    if (needWake && p.isAsynchronous()) {
                        needWake = false;
                    }
                }
                msg.next = p; // invariant: p == prev.next
                prev.next = msg;
            }

            // We can assume mPtr != 0 because mQuitting is false.
            if (needWake) {
                nativeWake(mPtr);
            }
        }
        return true;
    }

```

可以看出，enqueueMessage 主要单链表的插入操作，接下来看一下 next 方法：

```java

Message next() {
    // Return here if the message loop has already quit and been disposed.
    // This can happen if the application tries to restart a looper after quit
    // which is not supported.
    ...

    int pendingIdleHandlerCount = -1; // -1 only during first iteration
    int nextPollTimeoutMillis = 0;
    for (;;) {
        if (nextPollTimeoutMillis != 0) {
            Binder.flushPendingCommands();
        }

        nativePollOnce(ptr, nextPollTimeoutMillis);

        synchronized (this) {
            // Try to retrieve the next message.  Return if found.
            final long now = SystemClock.uptimeMillis();
            Message prevMsg = null;
            Message msg = mMessages;
            if (msg != null && msg.target == null) {
                // Stalled by a barrier.  Find the next asynchronous message in the queue.
                do {
                    prevMsg = msg;
                    msg = msg.next;
                } while (msg != null && !msg.isAsynchronous());
            }
            if (msg != null) {
                if (now < msg.when) {
                    // Next message is not ready.  Set a timeout to wake up when it is ready.
                    nextPollTimeoutMillis = (int) Math.min(msg.when - now, Integer.MAX_VALUE);
                } else {
                    // Got a message.
                    mBlocked = false;
                    if (prevMsg != null) {
                        prevMsg.next = msg.next;
                    } else {
                        mMessages = msg.next;
                    }
                    msg.next = null;
                    if (DEBUG) Log.v(TAG, "Returning message: " + msg);
                    msg.markInUse();
                    return msg;
                }
            } else {
                // No more messages.
                nextPollTimeoutMillis = -1;
            }

            // Process the quit message now that all pending messages have been handled.
            ...
        }

        ...
    }
}

```

可以看到 next 方法是一个无限循环的方法，如果消息队列中没有消息，那么 next 方法会椅子阻塞在这里，当新消息到来时，next 方法会返回这条消息，并将其从单链表中删除。

#### 2.3、Looper 的工作原理

Looper会不停的从 MessageQueue 中取出消息并处理，如果没有消息，就阻塞在那里。

而我们知道，创建一个 Looper 需要调用它的 prepare 方法，我们看一下这个方法里面做了什么：

```java

static final ThreadLocal<Looper> sThreadLocal = new ThreadLocal<Looper>();

public static void prepare() {
    prepare(true);
}

private static void prepare(boolean quitAllowed) {
    if (sThreadLocal.get() != null) {
        throw new RuntimeException("Only one Looper may be created per thread");
    }
    sThreadLocal.set(new Looper(quitAllowed));
}

private Looper(boolean quitAllowed) {
    mQueue = new MessageQueue(quitAllowed);
    mThread = Thread.currentThread();
}

```

可以看到它创建了一个 MessageQueue 对象，并将当前的线程保存起来。

接下来，我们看一下它的 loop 方法：

```java

public static void loop() {
      final Looper me = myLooper();
      if (me == null) {
          throw new RuntimeException("No Looper; Looper.prepare() wasn't called on this thread.");
      }
      final MessageQueue queue = me.mQueue;

      // Make sure the identity of this thread is that of the local process,
      // and keep track of what that identity token actually is.
      Binder.clearCallingIdentity();
      final long ident = Binder.clearCallingIdentity();

      for (;;) {
          Message msg = queue.next(); // might block
          if (msg == null) {
              // No message indicates that the message queue is quitting.
              return;
          }

          // This must be in a local variable, in case a UI event sets the logger
          final Printer logging = me.mLogging;
          if (logging != null) {
              logging.println(">>>>> Dispatching to " + msg.target + " " +
                      msg.callback + ": " + msg.what);
          }

          final long slowDispatchThresholdMs = me.mSlowDispatchThresholdMs;

          final long traceTag = me.mTraceTag;
          if (traceTag != 0 && Trace.isTagEnabled(traceTag)) {
              Trace.traceBegin(traceTag, msg.target.getTraceName(msg));
          }
          final long start = (slowDispatchThresholdMs == 0) ? 0 : SystemClock.uptimeMillis();
          final long end;
          try {
              msg.target.dispatchMessage(msg);
              end = (slowDispatchThresholdMs == 0) ? 0 : SystemClock.uptimeMillis();
          } finally {
              if (traceTag != 0) {
                  Trace.traceEnd(traceTag);
              }
          }
          if (slowDispatchThresholdMs > 0) {
              final long time = end - start;
              if (time > slowDispatchThresholdMs) {
                  Slog.w(TAG, "Dispatch took " + time + "ms on "
                          + Thread.currentThread().getName() + ", h=" +
                          msg.target + " cb=" + msg.callback + " msg=" + msg.what);
              }
          }

          if (logging != null) {
              logging.println("<<<<< Finished to " + msg.target + " " + msg.callback);
          }

          // Make sure that during the course of dispatching the
          // identity of the thread wasn't corrupted.
          final long newIdent = Binder.clearCallingIdentity();
          if (ident != newIdent) {
              Log.wtf(TAG, "Thread identity changed from 0x"
                      + Long.toHexString(ident) + " to 0x"
                      + Long.toHexString(newIdent) + " while dispatching to "
                      + msg.target.getClass().getName() + " "
                      + msg.callback + " what=" + msg.what);
          }

          msg.recycleUnchecked();
      }
  }

```

我们可以看到， loop 方法是一个死循环，唯一跳出循环的方式是 MessageQueue 的 next 方法返回了 null。而 next 方法是一个阻塞操作，当没有消息的时候就会阻塞在那里，所以导致 loop 方法也被阻塞到那里。当有消息时，Looper 会调用 msg.target.dispatchMessage(msg) 方法，而 msg.target 就是发送这条消息的 Handler 对象，这样 Handler 发送的消息又交给它的 dispatchMessage 方法来处理了。而 Handler 的 dispatchMessage 方法是在创建 Handler 时所使用的 Looper 中执行的，这样就将代码逻辑切换到指定的线程中去执行了。

Looper 提供了 quit 和 quitSafely 来推出一个 Looper，二者的区别是：quit 会直接退出 Looper，而 quitSafely 只是设定一个退出标记，然后把消息队列中的消息处理完毕才安全的退出。在子线程中，如果手动为其创建了一个 Looper，那么在所有消息都处理完后，调用 quit 方法来终止循环，否则这个子线程就会一直处于等待状态。

> Looper 的 quit 和 quitSafely 其实调用的是 MessageQueue 的 quit 方法，它将 MessageQueue 的 mQuitting 属性设置为 true，使得 MessageQueue 的 next 方法的死循环退出。

#### 2.4、Handler 的工作原理

Handler 负责消息的发送和接收，消息的发送可以使用 post 的一系列方法和 send 的一系列方法来完成，而 post 系列的方法最终会调用 sned 系列的方法。而 send 系列的方法最终会调用 sendMessageAtTime 来处理，所以我们看一下 sendMessageAtTime 做了什么：

```java

public boolean sendMessageAtTime(Message msg, long uptimeMillis) {
    MessageQueue queue = mQueue;
    if (queue == null) {
        RuntimeException e = new RuntimeException(
                this + " sendMessageAtTime() called with no mQueue");
        Log.w("Looper", e.getMessage(), e);
        return false;
    }
    return enqueueMessage(queue, msg, uptimeMillis);
}

private boolean enqueueMessage(MessageQueue queue, Message msg, long uptimeMillis) {
    msg.target = this;
    if (mAsynchronous) {
        msg.setAsynchronous(true);
    }
    return queue.enqueueMessage(msg, uptimeMillis);
}

```

可以看到，sned 方法最终就是往消息队列中插入一条消息， MessageQueue 的 next 方法就会返回这条消息给 Looper ，Looper 接收到消息之后就去处理消息，最终由Looper交给Handler 的 dispatchMessage 方法，这时 Handler 就进入了消息处理阶段：

```java

public void dispatchMessage(Message msg) {
    if (msg.callback != null) {
        handleCallback(msg);
    } else {
        if (mCallback != null) {
            if (mCallback.handleMessage(msg)) {
                return;
            }
        }
        handleMessage(msg);
    }
}

```

首先检查 Message 的 callback 是否为 null ，不为 null 则调用 handleCallback() 方法来处理信息。其中，Message 的 callback 是 Handler 的 post 方法传递的 Runnable 对象，handleCallback 的逻辑为：

```java

private static void handleCallback(Message message) {
    message.callback.run();
}

```

其次，检查 mCallback 是否为 null，不为 null 就调用 mCallback#handleMessage 来处理消息：

```java

public interface Callback {
    /**
     * @param msg A {@link android.os.Message Message} object
     * @return True if no further handling is desired
     */
    public boolean handleMessage(Message msg);
}

```

这个 Callback 的创建方式为：

```java

Handler handler = new Handler(new Handler.Callback() {
            @Override
            public boolean handleMessage(Message msg) {
                return false;
            }
        });

```

最后调用 handleMessage 来处理消息：

```java

public void handleMessage(Message msg) {
}

```
