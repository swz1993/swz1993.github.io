---
layout: post
title:  "Java集合(六) -- WeakhashMap"
date:   2018-05-23 21:03:36 +0530
description: WeakhashMap
---
WeakHashMap是一个带有弱键的Map，即当某个键不再正常使用的时候，这个键就会被移除，它所对应的键值对也就被移除了。该类支持空键和空值，具有与HashMap相似的性能特征，有与初始容量和负载因子。WeakHashMap是非同步的。

## WeakHashMap的定义及说明

定义如下：

```java
public class WeakHashMap<K,V>extends AbstractMap<K,V> implements Map<K,V> {}
```

WeakHashMap的定义还是比较简单的，就是继承了AbstractMap，实现了Map。即拥有Map基本的属性和方法。

### 构造方法

构造方法如下：

```java
//最大的容量，如果具有参数的任一构造函数隐式指定较高值，则使用最大容量
private static final int MAXIMUM_CAPACITY = 1 << 30;

//默认的初始容量，必须是2的次方
private static final int DEFAULT_INITIAL_CAPACITY = 16;

//默认的加载因子
private static final float DEFAULT_LOAD_FACTOR = 0.75f;

//数组类型，实际是一个单链表，数组长度必须是2的次方
Entry<K,V>[] table;

//阈值(容量*loadFaactor)
private int threshold;

//加载因子
private final float loadFactor;

//WeakHashMap中包含的键值的数量
private int size;

//使用给定的初始容量和给定的加载因子构造一个新的空WeakHashMap。
public WeakHashMap(int initialCapacity, float loadFactor) {
        //判断自定义的初始容量
        if (initialCapacity < 0)
            throw new IllegalArgumentException("Illegal Initial Capacity: "+
                                               initialCapacity);

        if (initialCapacity > MAXIMUM_CAPACITY)
            initialCapacity = MAXIMUM_CAPACITY;

        //判断自定义的加载因子
        if (loadFactor <= 0 || Float.isNaN(loadFactor))
            throw new IllegalArgumentException("Illegal Load factor: "+
                                               loadFactor);
        //计算初始容量(找到大于initialCapacity的最小的2的次方)
        int capacity = 1;
        while (capacity < initialCapacity)
            capacity <<= 1;
        //新建一个空数组
        table = newTable(capacity);
        this.loadFactor = loadFactor;
        threshold = (int)(capacity * loadFactor);
    }

//使用给定的初始容量和默认加载因子（0.75）构造一个新的空WeakHashMap。
public WeakHashMap(int initialCapacity) {
        this(initialCapacity, DEFAULT_LOAD_FACTOR);
    }

//使用默认初始容量（16）和加载因子（0.75）构造一个新的空WeakHashMap
public WeakHashMap() {
        this(DEFAULT_INITIAL_CAPACITY, DEFAULT_LOAD_FACTOR);
    }

//使用与指定映射相同的映射构造一个新的WeakHashMap。 使用默认加载因子（0.75）创建WeakHashMap，且初始容量要足以保存指定映射中的映射。
public WeakHashMap(Map<? extends K, ? extends V> m) {
        this(Math.max((int) (m.size() / DEFAULT_LOAD_FACTOR) + 1,
                DEFAULT_INITIAL_CAPACITY),
             DEFAULT_LOAD_FACTOR);
        putAll(m);
    }

```

有没有一种熟悉的感觉？不错，就是HashMap。可以看到它与HashMap相类似，都有容量、加载因子、阈值以及都是单链表结构。怎么看出是一个单链表？看一下Entry就了然了：

```java
private static class Entry<K,V> extends WeakReference<Object> implements Map.Entry<K,V> {
        //值
        V value;
        //hash值
        final int hash;
        下个节点
        Entry<K,V> next;

        Entry(Object key, V value,
              ReferenceQueue<Object> queue,
              int hash, Entry<K,V> next) {
            super(key, queue);
            this.value = value;
            this.hash  = hash;
            this.next  = next;
        }

}
```

其中ReferenceQueue是一个引用队列，在检测到可到达性更改后，垃圾回收器将已注册的引用对象添加到队列中，主要是用于监听Reference所指向的对象是否已经被垃圾回收。通过"super(key, queue)"方法及其调用方法，使key成为一个弱引用对象，并将其注册到queue中，以便在key被GC的时候可以添加到queue中去。

## 源码简析

我们还是从put()方法入手，分析一下它的实现原理：

```java
//已清除的WeakEntries的引用队列
private final ReferenceQueue<Object> queue = new ReferenceQueue<>();

public V put(K key, V value) {
        //判断key是否为空
        Object k = maskNull(key);
        //获取key经过处理后的hashCode
        int h = hash(k);
        //获取当前数组
        Entry<K,V>[] tab = getTable();
        //返回哈希码h对应的索引
        int i = indexFor(h, tab.length);
        //获取i索引位置的链表的首节点并遍历链表
        for (Entry<K,V> e = tab[i]; e != null; e = e.next) {
            //判断hash值是否相等
            if (h == e.hash && eq(k, e.get())) {
                //获取当前位置的旧值
                V oldValue = e.value;
                //新旧值不相等，则新值覆盖旧值
                if (value != oldValue)
                    e.value = value;
                //返回旧值，结束后面的操作
                return oldValue;
            }
        }

        //修改次数加1
        modCount++;
        //将新元素添加到数组中
        Entry<K,V> e = tab[i];
        tab[i] = new Entry<>(k, value, queue, h, e);
        //调整数组大小
        if (++size >= threshold)
            resize(tab.length * 2);
        return null;
    }

//对key的hashCode做处理
final int hash(Object k) {
        //获取k的hashCode
        int h = k.hashCode();

        //hashCode混淆
        h ^= (h >>> 20) ^ (h >>> 12);
        return h ^ (h >>> 7) ^ (h >>> 4);
    }

//首次删除过时条目后返回表
private Entry<K,V>[] getTable() {
        expungeStaleEntries();
        return table;
    }

//从表中清除过时的条目
private void expungeStaleEntries() {
        //遍历queue中的key
        for (Object x; (x = queue.poll()) != null; ) {
            synchronized (queue) {
                @SuppressWarnings("unchecked")
                //取出queue中的当前元素
                Entry<K,V> e = (Entry<K,V>) x;
                //获取当前key在数组中的索引
                int i = indexFor(e.hash, table.length);
                //将当前key赋值与prev
                Entry<K,V> prev = table[i];
                Entry<K,V> p = prev;
                //遍历索引i对应的链表
                while (p != null) {
                    //获取p的下一个元素并赋值给next
                    Entry<K,V> next = p.next;
                    //判断p是否等于e(除了第一次轮询以外，其他情况下p = prev.next())
                    if (p == e) {
                        //判断prev是否等于e
                        if (prev == e)
                            //p和prev都等于e，则直接将数组索引为i的链表的首节点替换为next
                            table[i] = next;
                        else
                            //只有p等于e，则改变prev的下一个元素的指向，将其变为p的下一个元素，即删除p
                            prev.next = next;
                        //不得将e.next归零; 旧的条目可能被HashIterator使用
                        //置为空以方便GC回收
                        e.value = null;
                        //数组长度减一
                        size--;
                        break;
                    }
                    //重新赋值，以便再次循环
                    prev = p;
                    p = next;
                }
            }
        }
    }


//返回哈希码h对应的索引
private static int indexFor(int h, int length) {
        return h & (length-1);
    }

//调整数组大小
void resize(int newCapacity) {
        //获取当前table数组
        Entry<K,V>[] oldTable = getTable();
        //获取当前数组长度
        int oldCapacity = oldTable.length;
        //判断数组长度是否大于最大值
        if (oldCapacity == MAXIMUM_CAPACITY) {
            //将阈值置为最大值
            threshold = Integer.MAX_VALUE;
            return;
        }
        //使用新的数组长度新建一个数组
        Entry<K,V>[] newTable = newTable(newCapacity);
        //将旧数组的所有元素移入新数组
        transfer(oldTable, newTable);
        //将table指向新数组
        table = newTable;

        //判断数组长度是否大于等于阈值的1/2
        if (size >= threshold / 2) {
            //重新计算阈值
            threshold = (int)(newCapacity * loadFactor);
        } else {
            //从表中清除过时的条目
            expungeStaleEntries();
            //将新元素移入旧的数组
            transfer(newTable, oldTable);
            //将table指向旧数组
            table = oldTable;
        }
    }

//将所有条目从src传输到dest
private void transfer(Entry<K,V>[] src, Entry<K,V>[] dest) {
        for (int j = 0; j < src.length; ++j) {
            //获取src指定位置的元素
            Entry<K,V> e = src[j];
            src[j] = null;
            //遍历指定索引下的链表
            while (e != null) {
                Entry<K,V> next = e.next;
                //获取key
                Object key = e.get();
                if (key == null) {
                    //key为null则将其next和value置为空，且数组长度减一
                    e.next = null;
                    e.value = null;
                    size--;
                } else {
                    //获取e在dest数组中所对应的索引，并赋值
                    int i = indexFor(e.hash, dest.length);
                    e.next = dest[i];
                    dest[i] = e;
                }
				//赋值并重新开始循环
                e = next;
            }
        }
    }

```

从上面的分析中我们可以看出，WeakHashMap每次put一个元素，都会先删除table中不再正常使用的元素。然后再判断当前已有元素中的key是否有与要添加元素的key相同的，相同则覆盖其值，不同则将新元素添加如数组中。在这个过程中不再正常使用的键的原理为：当WeakHashMap中的键(弱引用)被GC回收时，该键会被添加到queue中。然后，在put过程中会执行expungeStaleEntries()方法，该方法会遍历queue中的key并删除WeakHashMap中与其key对应的键值对。

在expungeStaleEntries()方法中，有一个queue.poll()方法，它ReferenceQueue中的方法，具体如下：

```java

//ReferenceQueue的队首
private Reference<? extends T> head = null;

//ReferenceQueue的队尾
private Reference<? extends T> tail = null;

//判断队列中是否为空，如果不为空，则取出链表中head位置的元素
public Reference<? extends T> poll() {
        synchronized (lock) {
            if (head == null)
                return null;
            return reallyPollLocked();
        }
    }

//Reference.queueNext将设置为sQueueNextUnenqueued，以指示何时将引用放入队列并从队列中删除。
private static final Reference sQueueNextUnenqueued = new PhantomReference(null, null);

private Reference<? extends T> reallyPollLocked() {

        if (head != null) {
            Reference<? extends T> r = head;
            if (head == tail) {
                tail = null;
                head = null;
            } else {
                head = head.queueNext;
            }
            //更新queueNext以指示引用已入队，但现在已从队列中删除。
            r.queueNext = sQueueNextUnenqueued;
            return r;
        }

        return null;
    }
```

作用就是取出queue中已经被GC的key，以方便从数组中删除。

好了，本文到此结束。

感觉自己博客写的好乱！！！
