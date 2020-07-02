---
layout: post
title:  "Java集合(八) -- LinkedHashMap"
date:   2018-05-23 21:03:36 +0530
description: LinkedHashMap
---

LinkedHashMap是HashMap的子类，此实现与HashMap的不同之处在于它维护了一个**贯穿其所有条目**的双向链表。 此链表定义迭代排序，通常是键插入映射的顺序（插入顺序）。 请注意，如果将键重新插入Map，则不会影响插入顺序。

## 定义及说明

定义如下：

```java
public class LinkedHashMap<K,V> extends HashMap<K,V> implements Map<K,V>{}
```

它继承于HashMap，底层使用哈希表和链表来维护集合。

构造方法为：

```java
//此链表哈希映射的迭代排序方法：true表示访问顺序，false表示插入顺序。
final boolean accessOrder;

//使用指定的初始容量和加载因子构造一个空的插入排序的LinkedHashMap实例
public LinkedHashMap(int initialCapacity, float loadFactor) {
        super(initialCapacity, loadFactor);
        accessOrder = false;
    }

//使用指定的初始容量和默认加载因子（0.75）构造一个空的插入排序的LinkedHashMap实例
public LinkedHashMap(int initialCapacity) {
        super(initialCapacity);
        accessOrder = false;
    }

//使用默认初始容量（16）和加载因子（0.75）构造一个空的插入顺序LinkedHashMap实例。
public LinkedHashMap() {
        super();
        accessOrder = false;
    }

//构造一个插入有序的LinkedHashMap实例，其具有与指定映射相同的映射。 LinkedHashMap实例使用默认加载因子（0.75）和足以保存指定映射中的映射的初始容量创建。
public LinkedHashMap(Map<? extends K, ? extends V> m) {
        super();
        accessOrder = false;
        putMapEntries(m, false);
    }

//使用指定的初始容量，加载因子和排序模式构造一个空的LinkedHashMap实例。
public LinkedHashMap(int initialCapacity,
                         float loadFactor,
                         boolean accessOrder) {
        super(initialCapacity, loadFactor);
        this.accessOrder = accessOrder;
    }
```

我们可以看到，LinkedHashMap是调用父类的构造函数做初始化。其构造函数中的accessOrder属性决定了迭代顺序，true表示访问顺序，false表示插入顺序。默认使用插入顺序，即使用通过put或其类似方法插入的顺序进行排序。

## 源码及简析

按照惯例应该是分析put()方法了，但是，很尴尬，LinkedHashMap并没有重写put()方法，也就是说，它的put()方法跟HashMap是相同的。但是，他重写了putVal()方法中调用的afterNodeAccess()和afterNodeInsertion()方法，我们看一下：

```java
//LinkedHashMap自己的Entry
static class LinkedHashMapEntry<K,V> extends HashMap.Node<K,V> {
        LinkedHashMapEntry<K,V> before, after;
        LinkedHashMapEntry(int hash, K key, V value, Node<K,V> next) {
            super(hash, key, value, next);
        }
    }

//双向链表的头部
transient LinkedHashMapEntry<K,V> head;

//双向链表的尾部
transient LinkedHashMapEntry<K,V> tail;


//将节点移动到最后
void afterNodeAccess(Node<K,V> e) {
        LinkedHashMapEntry<K,V> last;
        //如果是按访问顺序排序，且e不是链表的尾部
        if (accessOrder && (last = tail) != e) {
            //将e节点赋值给p，将e的前节点赋值给b，将e的后节点赋值给a，将tail赋值给last
            LinkedHashMapEntry<K,V> p =
                (LinkedHashMapEntry<K,V>)e, b = p.before, a = p.after;
            //将p的后一个节点置为空
            p.after = null;
            //如果p为链表头部
            if (b == null)
                //将a置为链表头部
                head = a;
            else
                //否则，将a置为b的后一个元素
                b.after = a;
            //如果p不是链表的尾部
            if (a != null)
                //将a的上一个元素置为b
                a.before = b;
            else
                //否则，将b赋值给last
                last = b;
            //当前链表如果为空
            if (last == null)
                //将p置为链表的头部
                head = p;
            else {
                //否则，将p置为last的下一个元素
                p.before = last;
                last.after = p;
            }
            //将p置为链表的尾部
            tail = p;
            ++modCount;
        }
    }

//在HashMap中传过来的evict为true
void afterNodeInsertion(boolean evict) {
        LinkedHashMapEntry<K,V> first;
        //判断是否删除过时的条目
        if (evict && (first = head) != null && removeEldestEntry(first)) {
            K key = first.key;
            //调用HashMap的方法
            removeNode(hash(key), key, null, false, true);
        }
    }

//如果此映射应删除其最旧条目，则返回true。它允许映射通过删除过时条目来减少内存消耗。
protected boolean removeEldestEntry(Map.Entry<K,V> eldest) {
        //糟老头子坏的很，它直接返回了false！！！
        return false;
    }
```

通过上面分析，我们发现，如果是按照访问顺序排序，则经过一系列的判断和赋值后，将新元素插入到链表的尾部。也就是说，如果按照访问的顺序排序，则排序靠后的，就是最近插入的元素。要注意，这个排序跟在Map中的存储顺序没有关系，只是在双向链表中的顺序。我们还发现在LinkedHashMapEntry类内部，出现了before和after两个属性，而根据在afterNodeAccess()方法中的分析，他们分别指向元素的上一个和下一个节点。那么，由此得出，在LinkedHashMap中的链表是一个双向链表。

删除条目时，调用了HashMap的remove()方法，LinkedHashMap重写了其中调用的afterNodeRemoval(node)方法(在removeNode方法中调用)，我们现在来看一下：

```java
void afterNodeRemoval(Node<K,V> e) {
        //将e的值赋予p，将p的上个节点的值赋予b，p的下个节点的值赋予a
        LinkedHashMapEntry<K,V> p =
            (LinkedHashMapEntry<K,V>)e, b = p.before, a = p.after;
        //将p前、后节点置为空
        p.before = p.after = null;
        //如果p为链表头部
        if (b == null)
            //将a设置为链表头部
            head = a;
        else
            //否则，将b的下个元素由变为a
            b.after = a;
        //如果p为链表尾部
        if (a == null)
            //将b设为链表尾部
            tail = b;
        else
            //否则，将b设置为a的上个元素
            a.before = b;
    }
```

可以看到，通过对指定元素e前后节点b、a的设置，使得其b、a的指向不再指向p，以将其删除。

接下来，我们看一下它的get()方法：

```java
public V get(Object key) {
        //初始化一个节点对象
        Node<K,V> e;
        //判断key所对应的节点是否为空，不为空则获取key所对应的节点值
        if ((e = getNode(hash(key), key)) == null)
            return null;
        //判断排序方式
        if (accessOrder)
            //如果是访问顺序，则重排序
            afterNodeAccess(e);
        return e.value;
    }


//重排序(或是调用了put()方法之后，为节点设置前、后位置的元素)
void afterNodeAccess(Node<K,V> e) {
        LinkedHashMapEntry<K,V> last;
        //判断排序方式是按访问顺序排序，且e节点不是双向链表的尾部
        if (accessOrder && (last = tail) != e) {
            //将e节点赋值给p，将e的前节点赋值给b，将e的后节点赋值给a
            LinkedHashMapEntry<K,V> p =
                (LinkedHashMapEntry<K,V>)e, b = p.before, a = p.after;
            //将p的后一个节点置为空
            p.after = null;
            if (b == null)
                //如果b为空，证明e为首节点，则将e的下个节点置为首节点
                head = a;
            else
                //如果b不为空，则将a置为其下个节点，替代e的位置
                b.after = a;
            if (a != null)
                //如果a不为空，则将a的上一个节点置为b，替代e的位置
                a.before = b;
            else
                //如果a为空，则将b的值赋值给last
                last = b;
            if (last == null)
                //如果last为空(即tail为空，且b为空，说明只有p一个元素)，则将p置为首节点
                head = p;
            else {
                //如果last不为空，则将p的前节点置为last，last的后节点置为p
                p.before = last;
                last.after = p;
            }
            /将p置为尾节点
            tail = p;
            ++modCount;
        }
    }
```
可以发现，我们把get方法访问过的元素放到链表的尾部，而通过上面的分析，我们发现，如果主动删除元素，则从链表的头部开始。这样，就形成了一个简单的LRU。不过，由于其removeEldestEntry()方法直接返回了false，所以，如果我们要用它做LRU，就需要自己写一个类继承LinkedHashMap，并重写removeEldestEntry()方法。比如，我们要求Map的长度在100以内：

```java
private static final int MAX_ENTRIES = 100;

@Override
protected boolean removeEldestEntry(Map.Entry eldest) {
     return size() > MAX_ENTRIES;
}
```

## 小结

1、LinkedHashMap继承于HashMap，是一个基于HashMap和双向链表实现的Map。

2、LinedHashMap是有顺序的，分别为按照插入顺序排序和按照访问顺序排序，默认为按照插入顺序排序。

3、LinkedHashMap是非同步的。
