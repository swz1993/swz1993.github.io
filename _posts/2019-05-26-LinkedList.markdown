---
layout: post
title:  "Java集合(三) -- LinkedList"
date:   2018-05-23 21:03:36 +0530
description: LinkedList
---
通过前面的分析，我们已经知道ArrayList是一个增、删慢但是改、查快的集合。今天，我们就来看一个跟它正好相反的增、删快，改、查慢的集合--LinkedList。

## LinkedList的定义

先看定义

```java
public class LinkedList<E>
    extends AbstractSequentialList<E>
    implements List<E>, Deque<E>, Cloneable, java.io.Serializable
{}
```

先简单分析一下：

1、继承了AbstractSequentialList，实现了List接口，所以具有List基本的添加、修改等操作，支持顺序访问数据。

2、实现了Deque接口，所以可以单做是一个双端队列来使用。

3、实现了Cloneable接口，所以支持clone。

4、实现了java.io.Serializable接口，所以支持序列化和反序列化。

提到LinkedList，其实最直观的就是它是一个实现了List接口及Dequq接口的双向链表，可以从链表的开头或者结尾对链表进行遍历。接下来，我们就从源码上一步步分析。

## LinkedList源码简析

按照惯例，我们先看一下它的构造函数：

```java

//构造一个空的列表
public LinkedList() {}

//构造一个包含指定集合元素的列表
public LinkedList(Collection<? extends E> c) {}

```

然后看一下它的三个属性：

```java
//List中元素的个数
transient int size = 0;

//指向上一个节点的指针
transient Node<E> first;

//指向下一个节点的指针
transient Node<E> last;
```

first和last的类型为Node，那我们去看一下Node是什么

```java
private static class Node<E> {
        //当前节点所包含的值
        E item;
        //下一个节点
        Node<E> next;
        //上一个节点
        Node<E> prev;

        Node(Node<E> prev, E element, Node<E> next) {
            this.item = element;
            this.next = next;
            this.prev = prev;
        }
    }
```

我们发现Node其实就是一个双向链表，而我们操作元素时，也是用Node。所以LinkedList是通过双向链表实现的。

既然LinkedList是通过双向链表来实现的，可是他又实现了List接口，那么它是怎么根据索引取值的呢？我们看一下它的get()方法：

```java
public E get(int index) {
        //判断是否发生数组越界异常
        checkElementIndex(index);
        //返回指定位置的数据
        return node(index).item;
    }

Node<E> node(int index) {
        //比较index和1/2链表长度
        if (index < (size >> 1)) {
            //index<1/2链表长度,则从链表表头开始往后找
            Node<E> x = first;
            for (int i = 0; i < index; i++)
                x = x.next;
            return x;
        } else {
            //index>1/2链表长度,则从链表的末尾开始往前找
            Node<E> x = last;
            for (int i = size - 1; i > index; i--)
                x = x.prev;
            return x;
        }
    }
```
通过分析我们发现，LinkedList在调用get()方法的时候，会比较index和1/2链表长度。如果前者小，就从链表的表头开始往后找，直到找到index位置。如果前者大，则从链表的末尾开始往前找，直到找到index位置。然后返回index位置的值。所以，LinkedList在随机查找元素的时候效率是很慢的。

那我们开头不是说过它增、删很快吗？怎么体现的呢？我们看一下add()方法：

```java
public void add(int index, E element) {
        //判断是否发生数组越界异常
        checkPositionIndex(index);

        if (index == size)
            //如果index == size，直接插到链表末尾
            linkLast(element);
        else
            //获取到当前index位置的元素，然后执行方法
            linkBefore(element, node(index));
    }

void linkBefore(E e, Node<E> succ) {
        //获取index位置上一个元素
        final Node<E> pred = succ.prev;
        //将新元素e插入到index-1位置的元素和index位置的元素中间
        final Node<E> newNode = new Node<>(pred, e, succ);
        //将之前index位置元素的节点的prev的指向变为新元素
        succ.prev = newNode;
        if (pred == null)
            //如果是插入表头，则将新的元素作为链表的表头
            first = newNode;
        else
            //将之前上一个元素的节点的next的指向变为新元素
            pred.next = newNode;
        size++;
        modCount++;
    }
```

分析完可以得知，链表中插入元素只是改变元素指针的指向，所以会比较快。

## LinkedList的其他方法

其他的方法大同小异，我们就不做具体的分析了。不过，根据对LinkedList不同的使用方式，我们可以将方法归为几类：

**1、用作栈(LIFO(后进先出))**

```java
//将元素压入栈中
public void push(E e) {
        addFirst(e);
    }

public void addFirst(E e) {
        linkFirst(e);
    }

//弹出栈中的元素
public E pop() {
        return removeFirst();
    }

public E removeFirst() {
        final Node<E> f = first;
        if (f == null)
            throw new NoSuchElementException();
        return unlinkFirst(f);
    }

//检索此列表的第一个元素
public E peek() {
        final Node<E> f = first;
        return (f == null) ? null : f.item;
    }

public E peekFirst() {
        final Node<E> f = first;
        return (f == null) ? null : f.item;
     }
```
及addFirst()、removeFirst()和peekFirst()。

**2、用作队列(FIFO(先进先出))**

```java
//检索此列表的第一个元素
public E peek() {
        final Node<E> f = first;
        return (f == null) ? null : f.item;
    }

public E element() {
        return getFirst();
    }

public boolean add(E e) {
        linkLast(e);
        return true;
    }

public E getFirst() {
        final Node<E> f = first;
        if (f == null)
            throw new NoSuchElementException();
        return f.item;
    }

public E peekFirst() {
        final Node<E> f = first;
        return (f == null) ? null : f.item;
     }

//检索并删除此列表的第一个元素
public E poll() {
        final Node<E> f = first;
        return (f == null) ? null : unlinkFirst(f);
    }

public E remove() {
        return removeFirst();
    }

public E removeFirst() {
        final Node<E> f = first;
        if (f == null)
            throw new NoSuchElementException();
        return unlinkFirst(f);
    }

public E pollFirst() {
        final Node<E> f = first;
        return (f == null) ? null : unlinkFirst(f);
    }



//将指定的元素添加为此列表的最后一个元素
public boolean offer(E e) {
        return add(e);
    }

public void addLast(E e) {
        linkLast(e);
    }

public boolean offerLast(E e) {
        addLast(e);
        return true;
    }

```

然后我们再看一下clone()方法：

```java
 public Object clone() {
        LinkedList<E> clone = superClone();

        // 将链表的各个节点处于初始状态
        clone.first = clone.last = null;
        clone.size = 0;
        clone.modCount = 0;

        // 将元素填入新的链表
        for (Node<E> x = first; x != null; x = x.next)
            clone.add(x.item);

        return clone;
    }

@SuppressWarnings("unchecked")
    private LinkedList<E> superClone() {
        try {
            return (LinkedList<E>) super.clone();
        } catch (CloneNotSupportedException e) {
            throw new InternalError(e);
        }
    }
```

还有序列化的方法：

```java
 private void writeObject(java.io.ObjectOutputStream s)
        throws java.io.IOException {

        s.defaultWriteObject();

        // 写入链表大小
        s.writeInt(size);

        //按顺序写出元素
        for (Node<E> x = first; x != null; x = x.next)
            s.writeObject(x.item);
    }

@SuppressWarnings("unchecked")
    private void readObject(java.io.ObjectInputStream s)
        throws java.io.IOException, ClassNotFoundException {

        s.defaultReadObject();

        // 写入链表大小
        int size = s.readInt();

        // 按顺序写入元素
        for (int i = 0; i < size; i++)
            linkLast((E)s.readObject());
    }
```

好了，LinkedList的分析就到这了，现在我们总结一下：

1、LinkedList是通过双向链表实现的。内部类Node对应LinkedList各个节点的数据结构。

2、由于LinkedList是双向链表结构，所以具有增、删快，改、查慢的特点。

3、LinkedList不是线程安全的。

4、LinkedList在根据角标寻找元素的时候会比较角标和1/2链表长度，已决定从表头还是表尾遍历链表。

5、LinkedList也可以看成是自动扩容，而且没有上限。
